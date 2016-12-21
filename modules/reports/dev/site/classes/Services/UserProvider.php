<?php
/**
 * Created by PhpStorm.
 * User: andriy
 * Date: 13.12.16
 * Time: 14:43
 *
 * see sample http://silex.sensiolabs.org/doc/master/providers/security.html
 */

namespace App\Services;


use Symfony\Component\Security\Core\Exception\UnsupportedUserException;
use Symfony\Component\Security\Core\Exception\UsernameNotFoundException;
use Symfony\Component\Security\Core\User\UserInterface;
use Symfony\Component\Security\Core\User\UserProviderInterface;
use App\Models\User;
use Silex\Application;
use GuzzleHttp\Exception\RequestException;
use GuzzleHttp\Exception\ConnectException;
use GuzzleHttp\Exception\ClientException;
use GuzzleHttp\Psr7;

class UserProvider implements UserProviderInterface
{
    private $app;

    /**
     * UserProvider constructor.
     * @param $app
     */
    public function __construct(Application $app)
    {
        $this->app = $app;
    }


    public function loadUserByUsername($username)
    {
        /* @var \Symfony\Component\HttpFoundation\Request $request */
        $request = $this->app['request_stack']->getCurrentRequest();
        $jwt = $this->app['jwt']->getTokenFromRequest($request);
        if ($jwt === false) {
            throw new UsernameNotFoundException(sprintf('JWT not provided.'));
        }
        $payload = json_decode($this->app['jwt']->payloadDecode($jwt));
        if ($payload->email != $username) {
            throw new UsernameNotFoundException(sprintf('Username "%s" not met JWT.', $username));
        }
        $base_uri = $this->app['postgrest']['host'] . ':' . $this->app['postgrest']['port'];
        $this->app['monolog']->debug('JWT:\'' . $jwt . '\'');
        $client = new \GuzzleHttp\Client([
            'base_uri' => $base_uri,
            'headers' => [
                'Authorization' => 'Bearer ' . $jwt,
            ],
        ]);
        try {
            $response = $client->request('GET', '/users', [
                'query' => [
                    'email' => 'eq.' . $username,
                ],
            ]);
        } catch (ConnectException $e) {
            $this->app->abort(502, "Connection to PostgREST '$base_uri' not established."
                . " Got code:" . $e->getCode()
                . " message:" . $e->getMessage()
                . ($e->hasResponse() ? ' response:' . Psr7\str($e->getResponse()) : '')
            );
        } catch (ClientException $e) {
            $this->app->abort($e->getCode(), $e->getMessage());
        }
        return new User($username, json_decode(
            $response->getBody()->getContents()
        ));
    }

    public function refreshUser(UserInterface $user)
    {
        // TODO: Implement refreshUser() method.
        return $user;
    }

    public function supportsClass($class)
    {
        return $class = User::class;
    }

}
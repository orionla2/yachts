<?php

namespace App\Controllers;

use App\Models\User;
use Silex\Application;
use Silex\Api\ControllerProviderInterface;
use Silex\ControllerCollection;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\HttpFoundation\Request;
use PhpAmqpLib\Connection\AMQPStreamConnection;
use PhpAmqpLib\Message\AMQPMessage;
use \App\Services\MetaHandler;
use Symfony\Component\Security\Core\Exception\UsernameNotFoundException;

/**
 * Created by PhpStorm.
 * User: andrey
 * Date: 04.12.16
 * Time: 17:14
 */
class InvoicesController implements ControllerProviderInterface
{
    public function connect(Application $app)
    {
        /** @var ControllerCollection $controllers  */
        $controllers = $app['controllers_factory'];
        $controllers->get('/', [$this, 'getIndex']);
        $controllers->get('/test', [$this, 'getTest']);
        return $controllers;
    }

    public function getTest(Application $app, Request $request)
    {
        return new JsonResponse([ "result" => "ok" ]);
    }

    public function getIndex(Application $app)
    {
        $dataToShow = [ "index" => "not implemented" ];
        return new JsonResponse($dataToShow);
    }
}
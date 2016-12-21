<?php
/**
 * Created by PhpStorm.
 * User: andriy
 * Date: 13.12.16
 * Time: 17:54
 */

namespace App\Services;

use Symfony\Component\HttpFoundation\Request;
use \Firebase\JWT\JWT;

class JWTProcessor
{
    const TOKEN_HEADER_KEY     = 'Authorization';

    private $app;

    /**
     * JWTProcessor constructor.
     * @param $app \Pimple\Container
     */
    public function __construct($app)
    {
        $this->app = $app;
    }

    public function getTokenFromRequest(Request $request)
    {
        $headerField = $request->headers->get(self::TOKEN_HEADER_KEY);
        if (preg_match('/Bearer\\s+([\\w\\-\\_]+\\.[\\w\\-\\_]+\\.[\\w\\-\\_]+)/i', $headerField, $matches)) {
            return $matches[1];
        } else {
            return false;
        }
    }

    public function payloadDecode($token)
    {
        if (preg_match('/\\w+\\.(\\w+).\\w+/i', $token, $matches)) {
            return base64_decode($matches[1]);
        } else {
            return false;
        }

    }
}
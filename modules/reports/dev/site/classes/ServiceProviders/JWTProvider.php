<?php
/**
 * Created by PhpStorm.
 * User: andriy
 * Date: 13.12.16
 * Time: 18:00
 */

namespace App\ServiceProviders;

use App\Services\JWTProcessor;
use Pimple\Container;
use Pimple\ServiceProviderInterface;

class JWTProvider implements ServiceProviderInterface
{
    public function register(Container $app)
    {
        $app['jwt'] = function() use ($app) {
            return new JWTProcessor($app);
        };
    }
}
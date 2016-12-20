<?php
/**
 * Created by PhpStorm.
 * User: andriy
 * Date: 13.12.16
 * Time: 19:57
 */

namespace App\ServiceProviders;

use App\Services\UserProvider;
use Pimple\Container;
use Pimple\ServiceProviderInterface;

class UserProviderServiceProvider implements ServiceProviderInterface
{
    public function register(Container $app)
    {
        $app['user.provider'] = function() use ($app) {
            return new UserProvider($app);
        };
    }

}
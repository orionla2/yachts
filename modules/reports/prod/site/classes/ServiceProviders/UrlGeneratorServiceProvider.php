<?php
/**
 * Created by PhpStorm.
 * User: andriy
 * Date: 14.12.16
 * Time: 12:59
 */

namespace App\ServiceProviders;

use App\Services\UrlGenerator;
use Pimple\Container;
use Pimple\ServiceProviderInterface;

class UrlGeneratorServiceProvider implements ServiceProviderInterface
{
    public function register(Container $app)
    {
        $app['url'] = function() use ($app) {
            return new UrlGenerator($app);
        };
    }

}
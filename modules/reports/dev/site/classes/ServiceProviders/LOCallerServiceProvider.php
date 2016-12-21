<?php
namespace App\ServiceProviders;

use Pimple\Container;
use Pimple\ServiceProviderInterface;
use \App\Services\LOCaller;
/**
 * Created by PhpStorm.
 * User: andrey
 * Date: 04.12.16
 * Time: 16:48
 */
class LOCallerServiceProvider implements ServiceProviderInterface
{
    public function register(Container $app)
    {
        $app['lo_caller'] = function() use ($app) {
            $loCaller = new LOCaller($app['reports.path']);
            return $loCaller;
        };
    }
}
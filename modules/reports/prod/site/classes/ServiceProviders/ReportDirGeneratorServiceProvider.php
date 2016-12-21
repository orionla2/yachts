<?php
/**
 * Created by PhpStorm.
 * User: andriy
 * Date: 13.12.16
 * Time: 11:37
 */

namespace App\ServiceProviders;

use App\Services\ReportDirGenerator;
use Pimple\Container;
use Pimple\ServiceProviderInterface;

class ReportDirGeneratorServiceProvider implements ServiceProviderInterface
{
    public function register(Container $app)
    {
        $app['reports.dir.done'] = function() use ($app) {
            $gen = new ReportDirGenerator($app['reports.path']['done']);
            return $gen;
        };
    }

}
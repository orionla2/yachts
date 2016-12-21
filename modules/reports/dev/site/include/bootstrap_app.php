<?php
/**
 * Created by PhpStorm.
 * User: andrey
 * Date: 04.12.16
 * Time: 17:27
 */

use Silex\Application;
use Symfony\Component\Debug\Debug;
use App\ServiceProviders\LOCallerServiceProvider;

$app = new Application();
$app['debug'] = defined('DEBUG') ? DEBUG : false;

$app->register(new LOCallerServiceProvider());

$path = require('path.php');
$app['reports.path'] = $path['reports'];
$network = require('network.php');
$app['postgrest'] = $network['postgrest'];
$app->register(new \App\ServiceProviders\ReportDirGeneratorServiceProvider());
$app['reports.config'] = require('reports.php');
$app['rabbit.config'] = require('rabbit.php');

if ($app['debug']) {
    // enable the debug mode
    Debug::enable();
}


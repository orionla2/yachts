<?php
/**
 * Created by PhpStorm.
 * User: andrey
 * Date: 04.12.16
 * Time: 17:27
 */

use Silex\Application;
use Silex\Provider\AssetServiceProvider;
use Silex\Provider\TwigServiceProvider;
use Silex\Provider\ServiceControllerServiceProvider;
use Silex\Provider\HttpFragmentServiceProvider;
use Silex\Provider\MonologServiceProvider;
use Silex\Provider\WebProfilerServiceProvider;
use Symfony\Component\Debug\Debug;
use App\ServiceProviders\LOCallerServiceProvider;
use App\ServiceProviders\JMSServiceProvider;

// This check prevents access to debug front controllers that are deployed by accident to production servers.
// Feel free to remove this, extend it, or make something more sophisticated.
//echo (in_array(@$_SERVER['REMOTE_ADDR'], array('127.0.0.1', 'fe80::1', '::1','172.20.0.4'))) ? "<br>1" : "<br>0";
//echo (isset($_SERVER['HTTP_X_FORWARDED_FOR'])) ? "<br>1" : "<br>0";
if (
    isset($_SERVER['HTTP_X_FORWARDED_FOR'])
    && !in_array(@$_SERVER['REMOTE_ADDR'], array('127.0.0.1', 'fe80::1', '::1','172.20.0.4'))
) {
    header('HTTP/1.0 403 Forbidden');
    exit('You are not allowed to access this file. Check '.basename(__FILE__).' for more information.');
}

$app = new Application();
$app['debug'] = defined('DEBUG') ? DEBUG : false;

$app->register(new ServiceControllerServiceProvider());
$app->register(new AssetServiceProvider());
$app->register(new TwigServiceProvider());
$app->register(new HttpFragmentServiceProvider());
$app->register(new LOCallerServiceProvider());
/*$app->register(new JMSServiceProvider(), [
    'jms.metadata-dir' => __DIR__ . "/config/metadata",
]);*/

$app['twig'] = $app->extend('twig', function ($twig) {
    return $twig;
});
$app['twig.path'] = array(__DIR__.'/../templates');
$app['twig.options'] = array('cache' => __DIR__.'/../var/cache/twig');
$app['reports.path'] = '/home/application/reports';
$app['reports.config'] = require('reports.php');

if ($app['debug']) {
    // enable the debug mode
    Debug::enable();

    $app->register(new MonologServiceProvider(), array(
        'monolog.logfile' => __DIR__.'/../var/logs/silex_dev.log',
    ));

    $app->register(new WebProfilerServiceProvider(), array(
        'profiler.cache_dir' => __DIR__.'/../var/cache/profiler',
    ));
}


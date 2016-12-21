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

/* @var $app Silex\Application */
$app->register(new ServiceControllerServiceProvider());
$app->register(new AssetServiceProvider());
$app->register(new TwigServiceProvider());
$app->register(new HttpFragmentServiceProvider());
$app->register(new \App\ServiceProviders\JWTProvider());
$app->register(new \App\ServiceProviders\UserProviderServiceProvider());
$app->register(new \App\ServiceProviders\UrlGeneratorServiceProvider(), [
    'url.report.file' => '/reports/file'
]);


/*$app->register(new JMSServiceProvider(), [
    'jms.metadata-dir' => __DIR__ . "/config/metadata",
]);*/

$app['twig'] = $app->extend('twig', function ($twig) {
    return $twig;
});
$app['twig.path'] = array(__DIR__.'/../templates');
$app['twig.options'] = array('cache' => __DIR__.'/../var/cache/twig');
$app->register(new MonologServiceProvider(), array(
    'monolog.logfile' => __DIR__.'/../var/logs/silex_dev.log',
    'monolog.level' => (getenv('LOG_LEVEL') !== false ? getenv('LOG_LEVEL') : 'INFO'),
));

if ($app['debug']) {
    $app->register(new WebProfilerServiceProvider(), array(
        'profiler.cache_dir' => __DIR__.'/../var/cache/profiler',
    ));
}


<?php

define('DEBUG', (getenv('LOG_LEVEL') !== false ? getenv('LOG_LEVEL') == 'DEBUG' : false));

ini_set('display_errors', DEBUG ? 1 : 0);

require_once __DIR__ . '/../vendor/autoload.php';

require __DIR__ . '/../include/bootstrap_app.php';
require __DIR__ . '/../include/bootstrap_web.php';
require __DIR__ . '/../include/mount_routes.php';
require __DIR__ . '/../include/error_handling.php';

/* @var $app Silex\Application */
$app->run();

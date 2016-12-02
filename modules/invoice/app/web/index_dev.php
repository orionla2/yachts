<?php

use Symfony\Component\Debug\Debug;

// This check prevents access to debug front controllers that are deployed by accident to production servers.
// Feel free to remove this, extend it, or make something more sophisticated.
//echo (in_array(@$_SERVER['REMOTE_ADDR'], array('127.0.0.1', 'fe80::1', '::1','172.20.0.4'))) ? "<br>1" : "<br>0";
//echo (isset($_SERVER['HTTP_X_FORWARDED_FOR'])) ? "<br>1" : "<br>0";
/*if (
    isset($_SERVER['HTTP_X_FORWARDED_FOR'])
    && !in_array(@$_SERVER['REMOTE_ADDR'], array('127.0.0.1', 'fe80::1', '::1','172.20.0.3'))
    ) {
    header('HTTP/1.0 403 Forbidden');
    exit('You are not allowed to access this file. Check '.basename(__FILE__).' for more information.');
}*/

require_once __DIR__.'/../vendor/autoload.php';

Debug::enable();

$app = require __DIR__.'/../src/app.php';
require __DIR__.'/../config/dev.php';
require __DIR__.'/../src/controllers.php';
$app->run();

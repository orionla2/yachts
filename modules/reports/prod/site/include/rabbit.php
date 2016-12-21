<?php
/**
 * Created by PhpStorm.
 * User: andrey
 * Date: 11.12.16
 * Time: 22:36
 */
return [
    'server' => getenv('RMQ_SERVER') !== false ? getenv('RMQ_SERVER') : 'localhost',
    'port' => getenv('RMQ_PORT') !== false ? getenv('RMQ_PORT') : 5672,
    'login' => getenv('RMQ_LOGIN') !== false ? getenv('RMQ_LOGIN') : 'guest',
    'password' => getenv('RMQ_PASSWORD') !== false ? getenv('RMQ_PASSWORD') : 'guest',
    'queue' => 'report',
];
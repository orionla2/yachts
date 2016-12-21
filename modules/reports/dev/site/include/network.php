<?php
/**
 * Created by PhpStorm.
 * User: andriy
 * Date: 20.12.16
 * Time: 11:45
 */
return [
    'postgrest' => [
        'host' => getenv('POSTGREST_HOST') !== false ? getenv('POSTGREST_HOST') : 'postgrest',
        'port' => getenv('POSTGREST_PORT') !== false ? getenv('POSTGREST_PORT') : '80',
    ],
];
<?php
/**
 * Created by PhpStorm.
 * User: andriy
 * Date: 23.12.16
 * Time: 18:22
 */
/* @var $app Silex\Application */
$app->register(new Silex\Provider\SecurityServiceProvider(), array(
    'security.firewalls' => array(
        'dev' => array(
            'pattern'    => '^/(_(profiler|wdt)|css|images|js)/',
            'security'   => false,
        ),
        'default' => array(
            'anonymous' => null,
        ),
    ),
));
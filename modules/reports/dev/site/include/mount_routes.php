<?php
/**
 * Created by PhpStorm.
 * User: andrey
 * Date: 04.12.16
 * Time: 17:36
 */

/* @var $app Silex\Application */
$app->mount('reports', new \App\Controllers\ReportsController());
$app->mount('invoices', new \App\Controllers\InvoicesController());

<?php
/**
 * Created by PhpStorm.
 * User: andriy
 * Date: 08.12.16
 * Time: 20:54
 */
return [
    'test' => [
        'file' => 'report1.ods',
        'description' => 'Test report',
        'provider' => 'App\\ReportDataProviders\\TestDataProvider',
        'nameGenerator' => 'App\\Services\\ReportDatedGenerator',
    ],
];
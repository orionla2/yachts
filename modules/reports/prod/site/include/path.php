<?php
/**
 * Created by PhpStorm.
 * User: andrey
 * Date: 11.12.16
 * Time: 23:50
 */
return [
    'reports' => [
        'template' => getenv('REPORT_DIR') !== false ? getenv('REPORT_DIR') : "/home/application/reports",
        'done' => getenv('REPORT_DONE_DIR') !== false ? getenv('REPORT_DONE_DIR') : "/home/application/reports-done",
    ],
];
<?php
/**
 * Created by PhpStorm.
 * User: andriy
 * Date: 08.12.16
 * Time: 20:41
 */

namespace App\ReportDataProviders;


interface ReportDataProviderInterface
{
    public function getData(array $constraints = []);
}
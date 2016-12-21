<?php
/**
 * Created by PhpStorm.
 * User: andriy
 * Date: 12.12.16
 * Time: 17:59
 */

namespace App\Services;


interface ReportNameGeneratorInterface
{
    public function generate(array $reportInfo = []);
}
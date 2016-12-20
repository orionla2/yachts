<?php
/**
 * Created by PhpStorm.
 * User: andriy
 * Date: 12.12.16
 * Time: 17:56
 */

namespace App\Services;


class ReportDatedGenerator implements ReportNameGeneratorInterface
{
    public function generate(array $reportInfo = [])
    {
        $date = new \DateTime();
        return "Report_" . $date->format('YmdHi') . ".xls";
    }
}
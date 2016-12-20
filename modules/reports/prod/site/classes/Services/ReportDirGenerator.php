<?php
/**
 * Created by PhpStorm.
 * User: andriy
 * Date: 13.12.16
 * Time: 11:40
 */

namespace App\Services;


class ReportDirGenerator
{
    private $reportDoneDir;

    public function __construct($reportDoneDir)
    {
        $this->reportDoneDir = $reportDoneDir;
    }

    /**
     * @param $userId integer|string user id
     * @return string created path for report dir
     */
    public function create($userId)
    {
        $dirName = $this->reportDoneDir . DIRECTORY_SEPARATOR . $userId . DIRECTORY_SEPARATOR . uniqid('', true);
        mkdir($dirName, 0755, true);
        return $dirName;
    }
}
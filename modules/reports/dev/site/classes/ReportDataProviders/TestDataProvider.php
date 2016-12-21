<?php
/**
 * Created by PhpStorm.
 * User: andriy
 * Date: 08.12.16
 * Time: 20:43
 */

namespace App\ReportDataProviders;


class TestDataProvider implements ReportDataProviderInterface
{
    public function getData(array $constraints = [])
    {
        // $json = file_get_contents(__DIR__ . '/../../include/test_report_data.json');
        // $data = [ 'test_data' => json_decode($json),  ];
        $dataSet = [];
        $row = 0;
        $keys = [];
        if (($handle = fopen(__DIR__ . '/../../include/test_data.csv', "r")) !== FALSE) {
            while (($dataRow = fgetcsv($handle)) !== FALSE) {
                if ($row == 0) {
                    $keys = $dataRow;
                } else {
                    $dataSet[] = array_combine($keys, $dataRow);
                }
                $row++;
            }
            fclose($handle);
        }
        return [ 'test_data' => $dataSet ];
    }

}
<?php
/**
 * Created by PhpStorm.
 * User: andriy
 * Date: 12.12.16
 * Time: 18:30
 */

namespace App\Services;


class MetaHandler
{
    public static function write($folder, $data)
    {
        return file_put_contents($folder . DIRECTORY_SEPARATOR . 'meta.json'
            , json_encode($data)
            , LOCK_EX);
    }

    public static function read($folder)
    {
        $fileName = $folder . DIRECTORY_SEPARATOR . 'meta.json';
        if (!file_exists($fileName)) {
            return false;
        }
        $content = file_get_contents($fileName);
        if (false === $content) {
            return false;
        } else {
            return json_decode($content);
        }
    }
}
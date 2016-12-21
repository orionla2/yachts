<?php
/**
 * Created by PhpStorm.
 * User: andriy
 * Date: 14.12.16
 * Time: 12:34
 */

namespace App\Services;

use Pimple\Container;

class UrlGenerator
{
    private $app;

    /**
     * UrlGenerator constructor.
     * @param $app Container;
     */
    public function __construct(Container $app)
    {
        $this->app = $app;
    }

    public function report($fileName)
    {
        $pathParts = explode(DIRECTORY_SEPARATOR, $fileName);
        $url = $_SERVER['HTTP_HOST']
            . $this->app['url.report.file']
            . '/'
            . $pathParts[count($pathParts) - 2]
            . '/'
            . $pathParts[count($pathParts) - 1];
        return $url;
    }
}
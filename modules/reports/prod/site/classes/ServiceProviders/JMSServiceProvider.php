<?php
/**
 * Created by PhpStorm.
 * User: andriy
 * Date: 09.12.16
 * Time: 17:19
 */

namespace App\ServiceProviders;

use Pimple\Container;
use Pimple\ServiceProviderInterface;
use JMS\Serializer;

class JMSServiceProvider implements ServiceProviderInterface
{
    public function register(Container $app)
    {
        $app['jms'] = function() use ($app) {
            $serializer = Serializer\SerializerBuilder::create()
                ->addMetadataDir($app['jms.metadata-dir'])
                ->build();
            return $serializer;
        };
    }
}
<?php
/**
 * Created by PhpStorm.
 * User: andriy
 * Date: 12.12.16
 * Time: 20:44
 */
use PhpAmqpLib\Connection\AMQPStreamConnection;
use PhpAmqpLib\Message\AMQPMessage;

require_once __DIR__ . '/../vendor/autoload.php';
require_once __DIR__ . '/../vendor/autoload.php';

require __DIR__ . '/../include/bootstrap_app.php';

$connection = new AMQPStreamConnection('localhost', 5672, 'guest', 'guest');
$channel = $connection->channel();

$channel->queue_declare('report', false, false, false, false);

$msgBody = new \stdClass();
$msgBody->id = 'test';
$msgBody->user_id = 1;
$msgBody->report_folder = $app['reports.dir.done']->create($msgBody->user_id);
print_r($msgBody);

$msg = new AMQPMessage(json_encode($msgBody));
$channel->basic_publish($msg, '', 'report');

echo " [x] Sent \n";

$channel->close();
$connection->close();
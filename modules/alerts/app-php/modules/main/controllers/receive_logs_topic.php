<?php
require_once __DIR__ . '/../../../vendor/autoload.php';
use PhpAmqpLib\Connection\AMQPStreamConnection;
$connection = new AMQPStreamConnection('rabbitmq', 5432, 'admin', '123456789');
$channel = $connection->channel();
$channel->exchange_declare('x-pgsql-listen', 'topic', false, false, false);
list($queue_name, ,) = $channel->queue_declare("something", false, false, true, false);
$binding_keys = array_slice($argv, 1);
/*if( empty($binding_keys )) {
    //file_put_contents('php://stderr', "Usage: $argv[0] [binding_key]\n");
    //exit(1);
    echo ' [*] Waiting for logs. Type:' . $argv[0] . '[binding_key] "\n";';
}
foreach($binding_keys as $binding_key) {
	$channel->queue_bind($queue_name, 'pgsql_logs', $binding_key);
}*/
$channel->queue_bind($queue_name, 'x-pgsql-listen', 'test');
echo ' [*] Waiting for logs. To exit press CTRL+C', "\n";
$callback = function($msg){
  echo ' [x] ',$msg->delivery_info['routing_key'], ':', $msg->body, "\n";
};
$channel->basic_consume($queue_name, '', false, true, false, false, $callback);
while(count($channel->callbacks)) {
    $channel->wait();
}
$channel->close();
$connection->close();
?>
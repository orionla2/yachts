<?php
namespace Module\main\controllers;
/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */

/**
 * Description of MainController
 *
 * @author orionla2
 */
use Silex\Api\ControllerProviderInterface;
use Silex\Application;
use Symfony\Component\HttpFoundation\Request;
use Extention\TestExtention\Application\TestExtention;
use PhpAmqpLib\Connection\AMQPStreamConnection;
use PhpAmqpLib\Message\AMQPMessage;

class MainController implements ControllerProviderInterface{
    
    public function connect (Application $app) {
        $app['twig.loader.filesystem']->addPath(
            __DIR__ . '/../views/main'
        );
        $controller = $app['controllers_factory'];
        $controller->get('/',[$this,'actionIndex'])->bind('main-index');
        $controller->get('/send',[$this,'actionSend'])->bind('main-send');
        $controller->get('/recieve',[$this,'actionRecieve'])->bind('main-recieve');
        $controller->get('/newtask/{string}',[$this,'actionNewTask'])->bind('main-newtask');
        $controller->get('/emitlogs/{argv}',[$this,'actionEmitLog'])->bind('main-emitlogs');
        $controller->get('/emitlogs/{type}/{message}',[$this,'actionDirectEmit'])->bind('main-emitlogsdirect');
        $controller->get('/topiclogs/{argv}',[$this,'actionTopicEmit'])->bind('main-emitlogstopic');
        return $controller;
    }
    
    public function actionIndex(Application $app){
        $test = new TestExtention('RabbitMQ Service');
        $msg = $test->getMessage();
        return $app['twig']->render('index.html.twig', ['reqObj' => array(
            'Message' => $msg
            )]);
    }

    public function actionSend(Application $app){
        $connection = new AMQPStreamConnection('rabbitmq', 5672, 'admin', '123456789');
        $channel = $connection->channel();

        $channel->queue_declare('hello', false, false, false, false);

        $msg = new AMQPMessage('Test Message!');
        $channel->basic_publish($msg, '', 'hello');

        //echo " [x] Sent 'Hello World!'\n";
        return $app['twig']->render('index.html.twig', ['reqObj' => array(
            'Message' => " [x] Sent 'Test Message!'\n"
            )]);
        $channel->close();
        $connection->close();
    }
    public function actionNewTask(Application $app, $string){
        $connection = new AMQPStreamConnection('rabbitmq', 5672, 'admin', '123456789');
        $channel = $connection->channel();

        $channel->queue_declare('task_queue', false, true, false, false);

        $data = implode(' ', array_slice(explode(' ',$string), 1));
        if(empty($data)) $data = "Default Test!";
        $msg = new AMQPMessage($data,
                                array('delivery_mode' => 2) # make message persistent
                              );

        $channel->basic_publish($msg, '', 'task_queue');

        $channel->close();
        $connection->close();
        
        return $app['twig']->render('index.html.twig', ['reqObj' => array(
            'Message' => " [x] Sent 'Default Message!'\n"
            )]);
    }

    public function actionRecieve(Application $app){
        $connection = new AMQPStreamConnection('rabbitmq', 5672, 'admin', '123456789');
        $channel = $connection->channel();

        $channel->queue_declare('hello', false, false, false, false);

        //echo ' [*] Waiting for messages. To exit press CTRL+C', "\n";

        /*$callback = function($msg) {
          //echo " [x] Received ", $msg->body, "\n";
          return $app['twig']->render('index.html.twig', ['reqObj' => array(
            'Message' => $msg->body
            )]);
        };*/

        //$channel->basic_consume('hello', '', false, true, false, false, $callback);

        /*while(count($channel->callbacks)) {
            $channel->wait();
        }*/
        
        $channel->close();
        $connection->close();
        return $app['twig']->render('index.html.twig', ['reqObj' => array(
            'Message' => 'empty'
            )]);
    }
    
    public function actionEmitLog (Application $app, $argv) {
        $connection = new AMQPStreamConnection('rabbitmq', 5672, 'admin', '123456789');
        $channel = $connection->channel();

        $channel->exchange_declare('logs', 'fanout', false, false, false);

        $data = implode(' ', array_slice(explode(' ',$argv), 0));
        if(empty($data)) $data = "info: Hello World!";
        $msg = new AMQPMessage($data);

        $channel->basic_publish($msg, 'logs');

        //echo " [x] Sent ", $data, "\n";

        $channel->close();
        $connection->close();
        
        return $app['twig']->render('index.html.twig', ['reqObj' => array(
            'Message' => " [x] Sent ", $data, "\n"
            )]);

    }
    
    public function actionDirectEmit (Application $app, $type, $message) {
        $connection = new AMQPStreamConnection('rabbitmq', 5672, 'admin', '123456789');
        $channel = $connection->channel();

        $channel->exchange_declare('direct_logs', 'direct', false, false, false);

        $severity = isset($type) && !empty($type) ? $type : 'info';

        $data = $message;
        if(empty($data)) $data = "Hello World!";

        $msg = new AMQPMessage($data);

        $channel->basic_publish($msg, 'direct_logs', $severity);

        echo " [x] Sent ",$severity,':',$data," \n";
        
        $channel->close();
        $connection->close();
        return $app['twig']->render('index.html.twig', ['reqObj' => array(
            'Message' => " [x] Sent " , $severity , ':' , $data, "\n"
            )]);
    }
    public function actionTopicEmit (Application $app, $argv) {
        $connection = new AMQPStreamConnection('rabbitmq', 5672, 'admin', '123456789');
        $channel = $connection->channel();
        
        $channel->exchange_declare('topic_logs', 'topic', false, false, false);
        $argv = explode(' ',$argv);
        $routing_key = isset($argv[0]) && !empty($argv[0]) ? $argv[0] : 'anonymous.info';
        $data = implode('.', array_slice($argv, 1));
        if (empty($data))
            $data = "Hello World!";

        $msg = new AMQPMessage($data);

        $channel->basic_publish($msg, 'topic_logs', $routing_key);

        echo " [x] Sent ", $routing_key, ':', $data, " \n";

        $channel->close();
        $connection->close();
        
        return $app['twig']->render('index.html.twig', ['reqObj' => array(
            'Message' => " [x] Sent " . $routing_key . ':' . $data . "\n"
            )]);
    }
}

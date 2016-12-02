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
        return $controller;
    }
    
    public function actionIndex(Application $app){
        $test = new TestExtention('RabbitMQ Service');
        $msg = $test->getMessage();
        return $app['twig']->render('index.html.twig', ['reqObj' => array(
            'Message' => $msg
            )]);
    }

    public function actionSend(){
        $connection = new AMQPStreamConnection('localhost', 5672, 'guest', 'guest');
        $channel = $connection->channel();

        $channel->queue_declare('hello', false, false, false, false);

        $msg = new AMQPMessage('Test Message!');
        $channel->basic_publish($msg, '', 'hello');

        echo " [x] Sent 'Hello World!'\n";

        $channel->close();
        $connection->close();
    }
    public function actionRecieve(){
        $connection = new AMQPStreamConnection('localhost', 5672, 'guest', 'guest');
        $channel = $connection->channel();

        $channel->queue_declare('hello', false, false, false, false);

        echo ' [*] Waiting for messages. To exit press CTRL+C', "\n";

        $callback = function($msg) {
          echo " [x] Received ", $msg->body, "\n";
        };

        $channel->basic_consume('hello', '', false, true, false, false, $callback);

        while(count($channel->callbacks)) {
            $channel->wait();
        }

        $channel->close();
        $connection->close();
    }
}

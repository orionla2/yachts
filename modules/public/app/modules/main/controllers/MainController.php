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

class MainController implements ControllerProviderInterface{
    
    public function connect (Application $app) {
        $app['twig.loader.filesystem']->addPath(
            __DIR__ . '/../views/main'
        );
        $controller = $app['controllers_factory'];
        $controller->get('/',[$this,'actionIndex'])->bind('main-index');
        return $controller;
    }
    
    public function actionIndex(Application $app){
        $test = new TestExtention('Public Microservice');
        $msg = $test->getMessage();
        return $app['twig']->render('index.html.twig', ['reqObj' => array(
            'Message' => $msg
            )]);
    }
}

<?php
namespace Extention\ControllerLoader;
/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */

/**
 * Description of ConfigLoad
 *
 * @author orionla2
 */
class ConfigLoad {
    
    public static function loadControllers($config, $app){
        foreach ($config as $controllers) {
            foreach ($controllers as $name => $controller) {
                $url = $controller['url'];
                $namespace = $controller['namespace'];
                $className = $controller['className'];
                $class = "\\" . $namespace . '\\' . $name . '\\controllers\\' . $className;
                $app->mount($url, new $class());
            }
        }
    }
}

<?php

namespace Extention\TestExtention\Application;

/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */

/**
 * Description of TestExtension
 *
 * @author orionla2
 */
class TestExtention {
    //put your code here
    protected static $message = 'test';
    
    public function __construct ($msg = null) {
        if ($msg != null) {
            self::$message = $msg;
        }
    }
    
    public function getMessage () {
        return self::$message;
    }
}

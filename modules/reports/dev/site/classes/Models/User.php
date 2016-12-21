<?php
/**
 * Created by PhpStorm.
 * User: andriy
 * Date: 13.12.16
 * Time: 14:35
 */

namespace App\Models;


use Symfony\Component\Security\Core\User\UserInterface;

class User implements UserInterface
{
    private $userName;
    private $data;

    /**
     * User constructor.
     * @param $userName string
     * @param $data array
     */
    public function __construct($userName, $data)
    {
        $this->userName = $userName;
        $this->data = $data;
    }


    public function getRoles()
    {
        return $this->data['role'];
    }

    public function getPassword()
    {
        // TODO: Implement getPassword() method.
        return '';
    }

    public function getSalt()
    {
        // TODO: Implement getSalt() method.
        return null;
    }

    public function getUsername()
    {
        return $this->userName;
    }

    public function eraseCredentials()
    {
        // TODO: Implement eraseCredentials() method.
    }

}
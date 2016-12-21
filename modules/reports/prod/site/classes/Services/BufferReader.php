<?php
/**
 * Created by PhpStorm.
 * User: andriy
 * Date: 08.12.16
 * Time: 18:22
 */

namespace App\Services;


class BufferReader
{
    private $buffer;
    private $tail;

    /**
     * BufferAnalyzer constructor.
     */
    public function __construct()
    {
        $this->buffer = '';
        $this->tail = 0;
    }

    public function add($fragment, callable $callback)
    {
        $this->buffer .= $fragment;
        while (($pos = strpos($this->buffer, "\n", $this->tail)) !== false) {
            $sub_line = substr($this->buffer, $this->tail, $pos - $this->tail + 1);
            $this->tail = $pos + 1;
            $callback($sub_line);
        }
    }

    public function getBuffer()
    {
        return $this->buffer;
    }
}
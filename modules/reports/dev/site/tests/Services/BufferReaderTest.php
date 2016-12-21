<?php
/**
 * Created by PhpStorm.
 * User: andriy
 * Date: 09.12.16
 * Time: 16:06
 */

namespace Test\Services;


class BufferReaderTest extends \PHPUnit_Framework_TestCase
{

    public function testAdd()
    {
        $br = new \App\Services\BufferReader();
        $tmp = [];
        $br->add("Hello", function($str){ $this->assertTrue(false, 'this code should not be executed'); });
        $br->add("Hello\nAg", function($str) use (&$tmp) { $tmp[] = $str; });
        $this->assertCount(1, $tmp );
        $this->assertEquals("HelloHello\n", $tmp[0]);

        $br->add("ain", function($str){ $this->assertTrue(false, 'this code should not be executed'); });
        $br->add("Again\nTail", function($str) use (&$tmp) { $tmp[] = $str; });
        $this->assertCount(2, $tmp );
        $this->assertEquals("AgainAgain\n", $tmp[1]);
        $this->assertEquals("HelloHello\nAgainAgain\nTail", $br->getBuffer());

        $br->add("\nTail\nLastTail\n", function($str) use (&$tmp) { $tmp[] = $str; });
        $this->assertCount(5, $tmp );
        $this->assertEquals("Tail\n", $tmp[2]);
        $this->assertEquals("Tail\n", $tmp[3]);
        $this->assertEquals("LastTail\n", $tmp[4]);

        $br->add("\n", function($str) use (&$tmp) { $tmp[] = $str; });
        $this->assertCount(6, $tmp );
        $this->assertEquals("\n", $tmp[5]);
    }
}

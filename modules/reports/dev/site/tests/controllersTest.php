<?php
namespace Test;

use Silex\WebTestCase;

class controllersTest extends WebTestCase
{
    public function testGetHomepage()
    {
        $this->markTestSkipped();// 'it came from original skeleton, it does not needed'
        $client = $this->createClient();
        $client->followRedirects(true);
        $crawler = $client->request('GET', '/');

        $this->assertTrue($client->getResponse()->isOk());
        $this->assertContains('Welcome', $crawler->filter('body')->text());
    }

    public function createApplication()
    {
        require __DIR__.'/../include/bootstrap.php';
        require __DIR__.'/../include/mount_routes.php';
        require __DIR__.'/../include/error_handling.php';
        $app['session.test'] = true;

        return $app;
    }
}

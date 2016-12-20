<?php

namespace App\Controllers;

use App\Models\User;
use Silex\Application;
use Silex\Api\ControllerProviderInterface;
use Silex\ControllerCollection;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\HttpFoundation\Request;
use PhpAmqpLib\Connection\AMQPStreamConnection;
use PhpAmqpLib\Message\AMQPMessage;
use \App\Services\MetaHandler;
use Symfony\Component\Security\Core\Exception\UsernameNotFoundException;

/**
 * Created by PhpStorm.
 * User: andrey
 * Date: 04.12.16
 * Time: 17:14
 */
class ReportsController implements ControllerProviderInterface
{
    public function connect(Application $app)
    {
        /** @var ControllerCollection $controllers  */
        $controllers = $app['controllers_factory'];
        $controllers->get('/', [$this, 'getIndex']);
        $controllers->get('/status', [$this, 'getStatus']);
        $controllers->get('/status/{id}', [$this, 'getStatusById'])->assert('id', '[\d\.]+');
        $controllers->get('/file/{dir}/{fileName}', [$this, 'getFile']);
        $controllers->post('/{id}', [$this, 'makeReport'])->assert('id', '[\w\d\_\-]+');
        return $controllers;
    }

    public function getFile(Application $app, Request $request, $dir, $fileName)
    {
        $app['monolog']->debug('$dir: ' . $dir);
        $app['monolog']->debug('$fileName: ' . $fileName);
        $fullName = $app['reports.path']['done']
            . DIRECTORY_SEPARATOR . $this->getUserId($app, $request)
            . DIRECTORY_SEPARATOR . $dir
            . DIRECTORY_SEPARATOR . $fileName;
        if (!file_exists($fullName)) {
            $app->abort(404, "File " . $dir . DIRECTORY_SEPARATOR . $fileName . " not found.");
        }
        return $app->sendFile($fullName);
    }

    public function getStatus(Application $app, Request $request)
    {
        $result = [];
        $userDir = $app['reports.path']['done'] . DIRECTORY_SEPARATOR . $this->getUserId($app, $request);
        if (is_dir($userDir)) {
            $userContent = scandir($userDir);
            foreach($userContent as $dirName) {
                $dirItem = $userDir . DIRECTORY_SEPARATOR . $dirName;
                $app['monolog']->debug('$dirItem: ' . $dirItem);

                if ($dirName == '.' || $dirName == '..' || !is_dir($dirItem)) {
                    continue;
                }
                if (($meta = MetaHandler::read($dirItem)) === false) {
                    continue;
                }
                $item['id'] = $dirName;
                $item['meta'] = $meta;
                $item['files'] = $this->getDirFilesUrl($app, $dirItem);
                $result[] = $item;
            }
        }
        return new JsonResponse($result);
    }

    public function getStatusById(Application $app, Request $request, $id)
    {
        $dirItem = $app['reports.path']['done'] . DIRECTORY_SEPARATOR . $this->getUserId($app, $request) . DIRECTORY_SEPARATOR . $id;
        if (($meta = MetaHandler::read($dirItem)) === false) {
            $app['monolog']->debug('meta not read from ' . $dirItem);
            $app->abort(404, "Item '$id' not found.");
        }
        $item['id'] = $id;
        $item['meta'] = $meta;
        $item['files'] = $this->getDirFilesUrl($app, $dirItem);
        return new JsonResponse($item);
    }

    private function getDirFilesUrl(Application $app, $dir)
    {
        $result = [];
        $dirContent = scandir($dir);
        foreach($dirContent as $fileName) {
            if ($fileName == '.' || $fileName == '..' || $fileName == 'meta.json' || is_dir($dir . DIRECTORY_SEPARATOR . $fileName)) {
                continue;
            }
            $result[] = $app['url']->report($dir . DIRECTORY_SEPARATOR . $fileName);
        }
        return $result;
    }

    private function getUserId(Application $app, Request $request)
    {

        $token = $app['jwt']->getTokenFromRequest($request);
        if ($payload = $app['jwt']->payloadDecode($token)) {
            /* @var User $user */
            $user = $app['user.provider']->loadUserByUserName((json_decode($payload))->email);
            return $user->getUsername();
            //return (json_decode($payload))->email;
        } else {
            throw new UsernameNotFoundException(sprintf('JWT not provided.'));
        }
    }

    public function makeReport(Application $app, Request $request, $id)
    {
        if (!isset($app['reports.config'][$id])) {
            $app->abort(404, "Report '$id' not found.");
        }
        /* @var $dataProvider \App\ReportDataProviders\ReportDataProviderInterface */
        $connection = new AMQPStreamConnection(
            $app['rabbit.config']['server'],
            $app['rabbit.config']['port'],
            $app['rabbit.config']['login'],
            $app['rabbit.config']['password']);
        $channel = $connection->channel();

        $channel->queue_declare($app['rabbit.config']['queue'], false, false, false, false);

        $msgBody = new \stdClass();
        $msgBody->id = $id;
        $msgBody->user_id = $this->getUserId($app, $request);
        $msgBody->report_folder = $app['reports.dir.done']->create($msgBody->user_id);
        $task_id_pos = strrpos($msgBody->report_folder, DIRECTORY_SEPARATOR) + 1;
        $result = new \stdClass();
        $result->task_id = substr($msgBody->report_folder, $task_id_pos);

        MetaHandler::write(
            $msgBody->report_folder,
            [ 'type' => $msgBody->id, 'status' => 'pending', 'progress' => 0 ]
        );

        $msg = new AMQPMessage(json_encode($msgBody));
        $channel->basic_publish($msg, '', $app['rabbit.config']['queue']);

        $channel->close();
        $connection->close();
        return new JsonResponse($result);
    }

    public function getIndex(Application $app)
    {
        $dataToShow = [];
        foreach($app['reports.config'] as $key => $reportEntry) {
            $result = new \stdClass();
            $result->id = $key;
            $result->description = $reportEntry['description'];
            $dataToShow[] = $result;
        }
        return new JsonResponse($dataToShow);
    }
}
<?php
/**
 * Created by PhpStorm.
 * User: andrey
 * Date: 11.12.16
 * Time: 22:13
 */
use PhpAmqpLib\Connection\AMQPStreamConnection;
use Silex\Provider\MonologServiceProvider;

require_once __DIR__ . '/../vendor/autoload.php';
require __DIR__ . '/../include/bootstrap_app.php';

/* @var $app Silex\Application */
$app->register(new MonologServiceProvider(), array(
    'monolog.logfile' => __DIR__.'/../var/logs/worker.log',
    'monolog.level' => (getenv('LOG_LEVEL') !== false ? getenv('LOG_LEVEL') : 'INFO'),
));

try {
    $connection = new AMQPStreamConnection(
        $app['rabbit.config']['server'],
        $app['rabbit.config']['port'],
        $app['rabbit.config']['login'],
        $app['rabbit.config']['password']);
} catch (\ErrorException $e) {
    $app['monolog']->error('Error on connection: ', ['code' => $e->getCode(), 'message' => $e->getMessage(), 'credentials' => $app['rabbit.config']]);
    exit(1);
}

$channel = $connection->channel();

$channel->queue_declare($app['rabbit.config']['queue'], false, false, false, false);

$app['monolog']->info('Worker ready for messages with:'
    . ' server=' . $app['rabbit.config']['server']
    . ' port=' . $app['rabbit.config']['port']
    . ' login=' . $app['rabbit.config']['login']
    . ' password=' . $app['rabbit.config']['password']
);

$callback = function($msg) use($app) {
    $app['monolog']->debug('New task received: ' . $msg->body);
    $task = json_decode($msg->body);
    if (is_null($task)) {
        $app['monolog']->warning('Failed to decode JSON, ' . $msg->body . '. Process aborted.');
        $msg->delivery_info['channel']->basic_ack($msg->delivery_info['delivery_tag']);
        return;
    }
    if (!isset($task->id)) {
        $app['monolog']->warning('Task id is not set in message ' . $msg->body . '. Nothing to do.');
        $msg->delivery_info['channel']->basic_ack($msg->delivery_info['delivery_tag']);
        return;
    }
    if (!isset($task->user_id)) {
        $app['monolog']->warning('User id is not set in message ' . $msg->body . '. Nothing to do.');
        $msg->delivery_info['channel']->basic_ack($msg->delivery_info['delivery_tag']);
        return;
    }
    if (!isset($task->report_folder)) {
        $app['monolog']->warning('Report folder is not set in message ' . $msg->body . '. Nothing to do.');
        $msg->delivery_info['channel']->basic_ack($msg->delivery_info['delivery_tag']);
        return;
    }

    try {
        // make report
        if (!isset($app['reports.config'][$task->id])) {
            $app['monolog']->error('Report with id=' . $task->id . ' not implemented');
            $msg->delivery_info['channel']->basic_ack($msg->delivery_info['delivery_tag']);
            return;
        }
        $config = $app['reports.config'][$task->id];
        /* @var $dataProvider \App\ReportDataProviders\ReportDataProviderInterface */
        $dataProvider = new $config['provider']();
        $data = $dataProvider->getData();
        $dataLines = array_reduce(array_values($data), function($carry, $dataSet){
            return $carry + count($dataSet);
        }, 0);
        /* @var $reportNameGenerator App\Services\ReportNameGeneratorInterface */
        $reportNameGenerator = new $config['nameGenerator'];
        $reportFileName = $reportNameGenerator->generate($config);
        //$reportFolder = $app['reports.path']['done'] . DIRECTORY_SEPARATOR . $task->user_id . DIRECTORY_SEPARATOR . uniqid('', true);
        $reportFolder = $task->report_folder;
        \App\Services\MetaHandler::write($reportFolder, [ 'type' => $task->id, 'status' => 'started', 'progress' => 0 ]);
        $app['monolog']->debug('Report going to start processing with:'
            . ' report file=' . $app['reports.path']['template'] . DIRECTORY_SEPARATOR . $app['reports.config'][$task->id]['file']
            . ' result file=' . $reportFileName
            . ' folder=' . $reportFolder
        );
        $reportResult = $app['lo_caller']->startReport(
            $app['reports.path']['template'] . DIRECTORY_SEPARATOR . $app['reports.config'][$task->id]['file'],
            $reportFileName,
            $reportFolder,
            $data,
            function ($line) use ($reportFolder, $dataLines, $task, $app) {
                $app['monolog']->debug('LibreOffice sent message: \'' . $line . '\'');
                if (preg_match('/\\{.*\\}/', $line, $matches)) {
                    $payload = json_decode($matches[0]);
                    if (isset($payload->progress)) {
                        \App\Services\MetaHandler::write(
                            $reportFolder,
                            [ 'type' => $task->id, 'status' => 'process', 'progress' => $payload->progress / $dataLines ]
                        );
                    }
                }
            });
        $app['lo_caller']->removeDirs();
        if ($reportResult->code == 0) {
            \App\Services\MetaHandler::write(
                $reportFolder,
                [ 'type' => $task->id, 'status' => 'success', 'progress' => 1 ]
            );
            $app['monolog']->info('Task succeed: ' . $msg->body);
        } else {
            \App\Services\MetaHandler::write(
                $reportFolder,
                [
                    'status' => 'error',
                    'progress' => 0,
                    'code' => $reportResult->code,
                    'message' => $reportResult->error
                ]
            );
            $app['monolog']->warning('Task failed: ' . $msg->body . ' error:' . $reportResult->error);
        }
        $msg->delivery_info['channel']->basic_ack($msg->delivery_info['delivery_tag']);
    } catch(Exception $e) {
        $app['monolog']->warning('Error occured during task: ' . $e->getMessage());
    }
};

$channel->basic_qos(null, 1, null);
$channel->basic_consume($app['rabbit.config']['queue'], '', false, false, false, false, $callback);

// loop over incoming messages
try {
    while(count($channel->callbacks)) {
        $channel->wait();
    }
} catch (PhpAmqpLib\Exception\AMQPRuntimeException $e) {
    $app['monolog']->error('Error on runtime: ', ['code' => $e->getCode(), 'message' => $e->getMessage()]);
    exit(1);
}

$channel->close();
$connection->close();
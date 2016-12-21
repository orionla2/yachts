<?php
namespace App\Services;
/**
 * Created by PhpStorm.
 * User: andrey
 * Date: 04.12.16
 * Time: 18:50
 */
class LOCaller
{
    const max_utime = 180 * 1000000; // after that time unfinished service will be killed
    const progress_watchdog_utime = 10 * 1000000; // after that time service that do not send log messages will be killed
    const wait_quant = 50000; // wait time quant

    private $reportDir;
    private $dataDir;
    private $dstDir;
    private $cwd;

    public function __construct($reportDir)
    {
        $this->reportDir = $reportDir;
    }

    /**
     * @return mixed
     */
    public function getCwd()
    {
        return $this->cwd;
    }


    public function callMacro($macroName)
    {
        $exec_out = [];
        $exec_return_code = 0;
        exec(
            'soffice --invisible --nodefault --norestore "macro:///Standard.Module1.starter()"'
            , $exec_out
            , $exec_return_code
        );
        $res = new \stdClass();
        $res->out = implode('<br>',$exec_out);
        $res->code = $exec_return_code;
        return $res;
    }

    public function startMacro($macroName)
    {
        $descriptorspec = array(
            // 0 => array("pipe", "r"),  // stdin - канал, из которого дочерний процесс будет читать
            1 => array("pipe", "w"),  // stdout - канал, в который дочерний процесс будет записывать
            2 => array("file", "/tmp/error-output.txt", "a") // stderr - файл для записи
        );

        $cwd = '/tmp';

        $process = proc_open('exec soffice --invisible --nodefault --norestore "macro:///Standard.Module1.starter()"', $descriptorspec, $pipes, $cwd, null);

        $res = new \stdClass();
        $res->out = 'no result';
        $res->code = 1000;
        $res->error = 'unknown';
        if (is_resource($process)) {
            // $pipes теперь выглядит так:
            // 0 => записывающий обработчик, подключенный к дочернему stdin
            // 1 => читающий обработчик, подключенный к дочернему stdout
            // Вывод сообщений об ошибках будет добавляться в /tmp/error-output.txt

/*            fwrite($pipes[0], '<?php print_r($_ENV); ?>');
            fclose($pipes[0]);*/

            $res->out = stream_get_contents($pipes[1]);
            fclose($pipes[1]);

            // Важно закрывать все каналы перед вызовом
            // proc_close во избежание мертвой блокировки
            $return_value = proc_close($process);

            $res->code = $return_value;
        } else {
            $res->error = 'process did not started';
        }
        return $res;
    }

    private function createDirs()
    {
        $this->cwd = sys_get_temp_dir() . '/' . uniqid('lo_');
        $this->dataDir = $this->cwd . '/data';
        $this->dstDir = $this->cwd . '/dst';
        mkdir($this->cwd, 0755);
        mkdir($this->dataDir, 0755);
        mkdir($this->dstDir, 0755);
        return $this->cwd;
    }

    public function removeDirs()
    {
        if (isset($this->dataDir)) {
            array_map('unlink', glob($this->dataDir . "/*"));
            rmdir($this->dataDir);
        }
        if (isset($this->dstDir)) {
            array_map('unlink', glob($this->dstDir . "/*"));
            rmdir($this->dstDir);
        }
        if (isset($this->cwd)) {
            array_map('unlink', glob($this->cwd . "/*"));
            rmdir($this->cwd);
        }
    }

    /**
     * copy report to work dir
     * make csv files with data
     * @param $reportFile string fully qualified source report file name will be copied to workdir
     * @param $data array ['table_name' => [ [ 'key1' => val1, 'key2' => val2 ], [ 'key1' => val3, 'key2' => val4 ], ... ]]
     * @return string file name of report file, copied for process
     */
    public function prepareFiles($reportFile, $data)
    {
        $reportFileName = pathinfo($reportFile, PATHINFO_FILENAME);
        $dstPath = $this->cwd . DIRECTORY_SEPARATOR . $reportFileName . '.' . pathinfo($reportFile, PATHINFO_EXTENSION);
        copy($reportFile, $dstPath);

        foreach($data as $table_name => $values) {
            if (count($values) == 0) {
                continue;
            }
            $csvFileName = $this->dataDir . DIRECTORY_SEPARATOR . $table_name . '.csv';
            $fp = fopen($csvFileName, 'w');
            fputcsv($fp, array_keys((array)$values[0]));
            array_walk($values, function($row) use ($fp) {
                fputcsv($fp, array_values((array)$row));
            });
            fclose($fp);
        }
        return $dstPath;
    }

    /**
     * @param $reportFileName string fully qualified report file name, it will be copied to tmp dir
     * @param $resultReportName string resulting report .xls file (ex: 'YearReport.xls')
     * @param $dirToCopyResult string dir to copy result file without trailing slash
     * @param $data array mixed ['table_name' => [ [ 'key1' => val1, 'key2' => val2 ], [ 'key1' => val3, 'key2' => val4 ], ... ]]
     * @return \StdClass
     */
    public function startReport($reportFileName, $resultReportName, $dirToCopyResult, $data,    callable $progress)
    {
        $this->cwd = $this->createDirs();
        $workReportFile = $this->prepareFiles($reportFileName, $data);

        $descriptorspec = array(
            // 0 => array("pipe", "r"),  // stdin - канал, из которого дочерний процесс будет читать
            1 => array("pipe", "w"),  // stdout - канал, в который дочерний процесс будет записывать
            2 => array("file", $this->cwd . "/error-output.txt", "a") // stderr - файл для записи
        );
        // you may user --invisible instead of --headless for debug purposes
        $process = proc_open(
            'exec soffice --headless --nodefault --norestore "macro:///Standard.Starter.Report(\"'
                . $workReportFile .'\", \"'
                . $this->dstDir . DIRECTORY_SEPARATOR . $resultReportName . '\", \"'
                . $this->dataDir . '\")"'
            , $descriptorspec
            , $pipes
            , $this->cwd
            , null);

        $res = new \stdClass();
        $res->out = '';
        $res->code = 1000; // just magic number to easily find if it is occured
        $res->error = '';
        if (is_resource($process)) {
            // $pipes теперь выглядит так:
            // 0 => записывающий обработчик, подключенный к дочернему stdin
            // 1 => читающий обработчик, подключенный к дочернему stdout
            // Вывод сообщений об ошибках будет добавляться в /tmp/error-output.txt

            stream_set_blocking($pipes[1], false);
            $time_passed = 0;
            $log_watchdog = 0;
            $wait_for_terminate = false;
            $status = null;
            $br = new BufferReader();
            do {
                $logFragment = stream_get_contents($pipes[1]);
                if ($logFragment != '') {
                    $br->add($logFragment, $progress);
                    $log_watchdog = 0;
                }
                $status = proc_get_status($process);
                if ($status['running'] === false) {
                    break;
                } else {
                    if (($time_passed >= self::max_utime || $log_watchdog >= self::progress_watchdog_utime) && !$wait_for_terminate) {
                        proc_terminate($process);
                        $wait_for_terminate = true;
                        $res->error = 'forced termination on '
                            . ($log_watchdog >= self::progress_watchdog_utime ? ' watchdog' : 'max process time');
                    }
                    usleep(self::wait_quant);
                    $time_passed += self::wait_quant;
                    $log_watchdog +=  self::wait_quant;
                }
            } while (true);

            $br->add(stream_get_contents($pipes[1]), $progress);
            $res->out = $br->getBuffer();
            fclose($pipes[1]);

            // Важно закрывать все каналы перед вызовом
            // proc_close во избежание мертвой блокировки
            proc_close($process);

            $res->code = $status['exitcode'];
            if ($res->code == 0) {
                copy($this->dstDir . DIRECTORY_SEPARATOR . $resultReportName
                    , $dirToCopyResult . '/' . $resultReportName);
            }
        } else {
            $res->error = 'process did not started';
        }

        return $res;
    }

}
#!/bin/bash
rm -R prod/*
cp -R dev/basic prod/basic
cp -R dev/nginx prod/nginx
cp -R dev/reports prod/reports
rm -R prod/reports/bak
rm prod/reports/*.csv
cp dev/reports/test_data.csv prod/reports
mkdir prod/reports-done
cp -R dev/site prod/site
rm -R prod/site/.idea
rm -R prod/site/tests
rm -R prod/site/var/cache
mkdir -p prod/site/var/cache/profiler prod/site/var/cache/twig
rm -R prod/site/var/logs/*
rm prod/site/workers/test-sender.php
rm prod/site/phpunit.xml.dist
rm prod/site/README.rst
cp -R dev/supervisor prod/supervisor
mkdir prod/tmp
chown -R 1000:1000 prod
docker build -t mapleukraine/yacht-nginx-php-lo --rm .
#!/bin/bash
export ALIAS_DOMAIN=reports.site.org
export RMQ_SERVER=localhost
export REPORT_DIR=/home/application/reports
export REPORT_DONE_DIR=/home/application/reports-done
export POSTGREST_HOST=site.org
docker run -d \
	-v $(pwd)/dev/site:/app \
	-v $(pwd)/dev/nginx/vhost.common.d:/opt/docker/etc/nginx/vhost.common.d \
	-v $(pwd)/dev/basic:/home/application/.config/libreoffice/4/user/basic \
	-v $(pwd)/dev/basic:/root/.config/libreoffice/4/user/basic \
	-v $(pwd)/dev/reports:/home/application/reports \
	-v $(pwd)/dev/reports-done:/home/application/reports-done \
	-v $(pwd)/dev/supervisor/conf:/etc/supervisor/conf.d \
	-v /tmp/.X11-unix:/tmp/.X11-unix \
	-v $HOME/.Xauthority:/root/.Xauthority \
	-p 8080:80 \
	-p 8443:443 \
	--name reports-dev \
	-e "ALIAS_DOMAIN=$ALIAS_DOMAIN" \
	-e DISPLAY=$DISPLAY \
	-e REPORT_DIR=$REPORT_DIR \
	-e REPORT_DONE_DIR=$REPORT_DONE_DIR \
	-e RMQ_SERVER=localhost \
	-e LOG_LEVEL=DEBUG \
	-e POSTGREST_HOST=$POSTGREST_HOST \
	nginx-php-lo
docker run -d --network container:reports-dev --name rabbit-dev rabbitmq:3
# run -ti --rm \
#	-v $(pwd)/dev/site:/app \
#	-v $(pwd)/dev/tmp:/tmp \
#	nginx-php-lo /bin/bash
#	-v $(pwd)/dev/supervisor/conf/report-workers.conf:/opt/docker/etc/supervisor.d/report-workers.conf \

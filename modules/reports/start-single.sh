#!/bin/bash
docker run -ti --rm \
	-v $(pwd)/dev/site:/app \
	-v $(pwd)/dev/nginx/vhost.common.d:/opt/docker/etc/nginx/vhost.common.d \
	-v $(pwd)/dev/basic:/home/application/.config/libreoffice/4/user/basic \
	-v $(pwd)/dev/basic:/root/.config/libreoffice/4/user/basic \
	-p 80:80 \
	-p 443:443 \
	--name reports-dev-single \
	nginx-php-lo \
	/bin/bash
#!/bin/bash
export ALIAS_DOMAIN=reports.site.org
export RMQ_SERVER=localhost
docker run -d \
	-p 8080:80 \
	-p 8443:443 \
	--name reports-prod \
	-e "ALIAS_DOMAIN=$ALIAS_DOMAIN" \
	-e RMQ_SERVER=$RMQ_SERVER \
	-e LOG_LEVEL=DEBUG \
	mapleukraine/yacht-nginx-php-lo
docker run -d --network container:reports-prod --name rabbit-prod rabbitmq:3

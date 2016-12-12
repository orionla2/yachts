FROM nginx:1.10.1-alpine

MAINTAINER Andrew Markov "orionla2@gmail.com"

ENV TIMEZONE                UTC
ENV PHP_LISTEN              /var/run/php5-fpm.sock
ENV PHP_CLEAR_ENV           no
ENV RABBITMQ_VERSION=3.6.1 \
    RABBITMQ_AUTOCLUSTER_PLUGIN_VERSION=0.4.1
ENV RABBITMQ_HOME=/srv/rabbitmq_server-${RABBITMQ_VERSION} \
    PLUGINS_DIR=/srv/rabbitmq_server-${RABBITMQ_VERSION}/plugins \
    ENABLED_PLUGINS_FILE=/srv/rabbitmq_server-${RABBITMQ_VERSION}/etc/rabbitmq/enabled_plugins \
    RABBITMQ_MNESIA_BASE=/var/lib/rabbitmq
ENV PATH=$PATH:$RABBITMQ_HOME/sbin

EXPOSE      5671/tcp 5672/tcp 15672/tcp 15671/tcp
VOLUME      /var/lib/rabbitmq
CMD         ["/usr/bin/wrapper"]

RUN \
    # Installing php
    apk add --update \
         php5-json \
         php5-pdo \
         php5-zip \
         php5-gd \
         php5-curl \
         php5-dom \
         php5-openssl \
         php5-phar \
         php5-pcntl \
         php5-ctype \
         php5-cli \
         php5-cgi \
         php5-bcmath \
         php5-pcntl \
         php5-opcache \
         php5-fpm \
         curl && \

    apk add --virtual tobedeleted \
        git \
        tzdata \
        autoconf \
        openssl-dev \
        g++ \
        make \
        alpine-sdk \
        php5-dev \
        php5-pear \
        cmake && \

    cp /usr/share/zoneinfo/${TIMEZONE} /etc/localtime && \
    echo "${TIMEZONE}" > /etc/timezone && \

    
    # Set environments
    sed -i "s|;*daemonize\s*=\s*yes|daemonize = no|g" /etc/php5/php-fpm.conf && \
    sed -i "s|;listen.owner\s*=\s*nobody|listen.owner = root|g" /etc/php5/php-fpm.conf && \
    sed -i "s|;listen.group\s*=\s*nobody|listen.group = root|g" /etc/php5/php-fpm.conf && \
    sed -i "s|;*listen\s*=\s*127.0.0.1:9000|listen = ${PHP_LISTEN}|g" /etc/php5/php-fpm.conf && \
    sed -i "s|;*clear_env\s*=.*|clear_env = ${PHP_CLEAR_ENV}|g" /etc/php5/php-fpm.conf && \
    sed -i "s|include|;include|g" /etc/php5/php-fpm.conf && \

    sed -i "s|;*date.timezone =.*|date.timezone = ${TIMEZONE}|i" /etc/php5/php.ini && \
    sed -i "s|;*cgi.fix_pathinfo=.*|cgi.fix_pathinfo= 0|i" /etc/php5/php.ini && \

    mkdir -p /var/www/html && \
    apk del tzdata && \
    rm -rf /var/cache/apk/* && \

    chmod a+x /usr/bin/wrapper && apk add --update curl tar xz bash && \
    echo "http://dl-4.alpinelinux.org/alpine/edge/main" >> /etc/apk/repositories && \
    echo "http://dl-4.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories && \
    echo "http://dl-4.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories && \
    apk add erlang erlang erlang-mnesia erlang-public-key erlang-crypto erlang-ssl \
        erlang-sasl erlang-asn1 erlang-inets erlang-os-mon erlang-xmerl erlang-eldap \
        erlang-syntax-tools --update-cache --allow-untrusted && \
    cd /srv && \
    rmq_zip_url=https://github.com/rabbitmq/rabbitmq-server/releases/download && \
        rmq_zip_url=${rmq_zip_url}/rabbitmq_v$(echo $RABBITMQ_VERSION | tr '.' '_') && \
        rmq_zip_url=${rmq_zip_url}/rabbitmq-server-generic-unix-${RABBITMQ_VERSION}.tar.xz && \
    curl -Lv -o /srv/rmq.tar.xz $rmq_zip_url && \
    tar -xvf rmq.tar.xz && rm -f rmq.tar.xz && \
    touch /srv/rabbitmq_server-${RABBITMQ_VERSION}/etc/rabbitmq/enabled_plugins && \
    rabbitmq-plugins enable --offline rabbitmq_management && \
    rmq_ac_url=https://github.com/aweber/rabbitmq-autocluster/releases/download && \
        rmq_ac_url=${rmq_ac_url}/${RABBITMQ_AUTOCLUSTER_PLUGIN_VERSION} && \
        rmq_ac_url=${rmq_ac_url}/autocluster-${RABBITMQ_AUTOCLUSTER_PLUGIN_VERSION}.ez && \
    curl -Lv -o ${PLUGINS_DIR}/autocluster-${RABBITMQ_AUTOCLUSTER_PLUGIN_VERSION}.ez $rmq_ac_url && \
    apk del --purge tar xz && rm -Rf /var/cache/apk/* && \
    ln -sf $RABBITMQ_HOME /rabbitmq
    
COPY nginx.conf /etc/nginx/nginx.conf
COPY nginx.vh.default.conf /etc/nginx/conf.d/default.conf
COPY ./run.sh /root/run.sh
COPY ssl.config /srv/rabbitmq_server-${RABBITMQ_VERSION}/etc/rabbitmq/
COPY standard.config /srv/rabbitmq_server-${RABBITMQ_VERSION}/etc/rabbitmq/
COPY wrapper.sh /usr/bin/wrapper

EXPOSE 80 443

CMD ["/root/run.sh"]
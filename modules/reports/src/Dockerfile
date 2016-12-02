FROM dmitrovskiy/docker-nginx-php-fpm:1.0.0-alpine
MAINTAINER Andrew Markov <orionla2@gmail.com>
COPY ./default.conf /etc/nginx/conf.d/
COPY ../app /var/www/html/web/ 
RUN apk add --update vim EXPOSE 80 443
CMD ["/root/run.sh"]

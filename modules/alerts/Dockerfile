FROM node:6.9.2-alpine
COPY ./app/run.sh /root/
COPY ./app/ /var/www/html/web/
RUN chmod +x /root/run.sh 
CMD node /var/www/html/web/listener.js *.# & node /var/www/html/web/rmq-ls.js user *.*.user.*.* & node /var/www/html/web/rmq-ls.js booking *.*.booking.*.*
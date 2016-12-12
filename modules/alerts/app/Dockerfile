FROM node:6.9.2-alpine
COPY ./run.sh /root/
COPY ./ /var/www/html/web/
RUN chmod +x /root/run.sh 
CMD node /var/www/html/web/rmq-ls.js *.*.user.*.* & node /var/www/html/web/listener.js *.# > stdout.log



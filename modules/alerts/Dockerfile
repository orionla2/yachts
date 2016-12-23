FROM node:6.9.2-alpine
COPY ./app/run.sh /root/
COPY ./app/ /var/www/html/web/
RUN chmod +x /root/run.sh 
CMD node /var/www/html/web/listener.js *.# & \
node /var/www/html/web/rmq-ls.js user *.*.user.*.email & \
node /var/www/html/web/rmq-ls.js user *.*.user.*.sms & \
node /var/www/html/web/rmq-ls.js user *.*.user.*.push & \
node /var/www/html/web/rmq-ls.js booking *.*.booking.*.email & \
node /var/www/html/web/rmq-ls.js booking *.*.booking.*.sms & \
node /var/www/html/web/rmq-ls.js booking *.*.booking.*.push & \
node /var/www/html/web/rmq-ls.js invoice *.*.invoice.*.email & \
node /var/www/html/web/rmq-ls.js invoice *.*.invoice.*.sms & \
node /var/www/html/web/rmq-ls.js invoice *.*.invoice.*.push & \
node /var/www/html/web/rmq-ls.js paypal *.*.paypal.*.email & \
node /var/www/html/web/rmq-ls.js paypal *.*.paypal.*.sms & \
node /var/www/html/web/rmq-ls.js paypal *.*.paypal.*.push
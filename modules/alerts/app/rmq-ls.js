var amqp = require('amqplib/callback_api');

var args = process.argv.slice(3);

amqp.connect('amqp://admin:123456789@rabbitmq:5672', function(err, conn) {
  conn.createChannel(function(err, ch) {
    var ex = process.argv[2];

    ch.assertExchange(ex, 'topic', {durable: false});

    ch.assertQueue('', {exclusive: true}, function(err, q) {
      console.log(' [*] Waiting for logs on ' + ex + '. To exit press CTRL+C');

      args.forEach(function(key) {
        ch.bindQueue(q.queue, ex, key);
      });

      ch.consume(q.queue, function(msg) {
        console.log(" [x] %s:'%s'", msg.fields.routingKey, msg.content.toString());
      }, {noAck: true});
    });
  });
});
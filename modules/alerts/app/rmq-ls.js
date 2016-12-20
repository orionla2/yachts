var amqp = require('amqplib/callback_api');
var nodemailer = require('nodemailer');
var pgp = require('pg-promise')(/*options*/);

var cn = {
    host: 'postgresql', // server name or IP address;
    port: 5432,
    database: 'postgres',
    user: 'postgres',
    password: '1q2w3e4r'
};
var db = pgp(cn);
var args = process.argv.slice(3);

var emailSubject = {
  newUser: 'New account!',
  newBooking: 'New booking!',
  newInvoice: 'New invoice!',
  bookingApproved: 'Approved booking.',
  cancelledBooking: 'Canceled booking.'
};

var emailText = {
  newUser: 'Congratulations, you have been registrated on site.org. Your 🐴 is 🐸!',
  newBooking: 'New booking have been created! All hands on d_ck!',
  newInvoice: 'New invoice have been sent! All on board acros a board!',
  bookingApproved: 'Approved booking. With in one hour!',
  cancelledBooking: 'Canceled booking. Attention to details'
};

var emailHtml = {
  newUser: '<h1>New account!</h1><p>Html text</p>',
  newBooking: '<h1>New booking!</h1><p>Html text</p>',
  newInvoice: '<h1>New invoice!</h1><p>Html text</p>',
  bookingApproved: '<h1>Approved booking.</h1><p>Html text</p>',
  cancelledBooking: '<h1>Canceled booking.</h1><p>Html text</p>'
};

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

        var messanger = JSON.parse(msg.content.toString()).reduce(function (collector, current) {
           collector[Object.keys(current)[0]] = current[Object.keys(current)[0]];
           return collector;
        }, {});
        var emiter = null;
        var receiver = null;
        if (messanger.entity) {
          db.one("select email from my_yacht.user where id=$1", messanger.emiter)
          .then(function (user) {
              emiter = user.email;
          })
          .catch(function (error) {
              console.log(error); // print why failed;
          });
          db.one("select email from my_yacht.user where id=$1", messanger.receiver)
          .then(function (user) {
              receiver = user.email;
              //console.log(' [receiver] user:',receiver);
              //console.log(' [emiter] user:',emiter);
              var transporter = nodemailer.createTransport('smtps://orionla2%40gmail.com:85931210@smtp.gmail.com');
              var mailOptions = {
                  from: '"⛵ Dutch Oriental ⛵" <' + emiter + '>',
                  to: 'orionla2@gmail.com',//,receiver,
                  subject: emailSubject[messanger.event],
                  text: 'This message was sent from '+emiter+' to '+receiver,//emailText[messanger.event],
                  html: emailHtml[messanger.event]
              };
              // send mail with defined transport object 
              transporter.sendMail(mailOptions, function(error, info){
                  if(error){
                      return console.log(error);
                  }
                  console.log('Message sent: ' + info.response);
              });
          })
          .catch(function (error) {
              console.log(error); // print why failed;
          });
          emiter = null;
          receiver = null;
        }
        console.log(" [x] %s:'%s'", msg.fields.routingKey, msg.content.toString());
      }, {noAck: true});
    });
  });
});


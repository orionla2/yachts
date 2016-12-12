#!/usr/bin/env node

var amqp = require('amqplib/callback_api');
var PS = require('pg-pubsub');



var url  = 'postgres://postgres:1q2w3e4r@postgresql/postgres',//process.argv[2],
ps   = new PS(url);
var key = process.argv[2];

ps.addChannel('messanger', function(payload){
	amqp.connect('amqp://admin:123456789@rabbitmq:5672', function(err, conn) {
	  conn.createChannel(function(err, ch) {
	  	var router = payload.split('.');
	  	var routerArr = [];
	    routerArr.push({emiter: router[0]});
	    routerArr.push({receiver: router[1]});
	    routerArr.push({entity: router[2]});
	    routerArr.push({event: router[3]});
	    routerArr.push({type: router[4]});
	    ch.assertExchange(router[2], 'topic', {durable: false});
	    ch.publish(router[2], payload, new Buffer(JSON.stringify(routerArr)));
	    console.log(" [x] Messanger: key", payload, JSON.stringify(routerArr));
	  });
	});
});



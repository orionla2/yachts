var pgp = require('pg-promise')(/*options*/);
var string = '[{"emiter":"22"},{"receiver":"22"},{"entity":"user"},{"event":"newUser"},{"type":"email"}]';
var messanger = JSON.parse(string).reduce(function (collector, current) {
   collector[Object.keys(current)[0]] = current[Object.keys(current)[0]];
   return collector;
}, {});

console.log(' [x] user:',messanger.emiter);
var cn = {
    host: 'postgresql', // server name or IP address;
    port: 5432,
    database: 'postgres',
    user: 'postgres',
    password: '1q2w3e4r'
};
var db = pgp(cn);
db.one("select email from my_yacht.user where id=$1", messanger.emiter)
        .then(function (user) {
            var emiter = user.email;
            console.log(' [x] user:',emiter);
        })
        .catch(function (error) {
            console.log(error); // print why failed;
        });
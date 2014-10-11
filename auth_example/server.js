'use strict';

var express = require('express');
var path = require('path');
var invisible = require('../');
var User = require('./models/user');

var app = express();

app.get('/', function(req, res) {
  res.sendfile('index.html');
});

app.use(invisible.router({
  rootFolder: path.join(__dirname, 'models'),
  authenticate: User.authenticate
}));

var server = app.listen(3000);
invisible.addRealtime(server);

'use strict';

var express = require('express');
var path = require('path');
var invisible = require('../');

var app = express();

app.get('/', function(req, res) {
  res.sendfile('index.html');
});

app.use(invisible.router({
  rootFolder: path.join(__dirname, 'models')
}));

var server = app.listen(3000);
invisible.addRealtime(server);

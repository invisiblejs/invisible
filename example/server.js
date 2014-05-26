'use strict';

var express = require('express');
var path = require('path');
var invisible = require('../');
var bodyParser = require('body-parser');

var app = express();
app.use(bodyParser());

app.use(invisible.router({
  rootFolder: path.join(__dirname, 'models')
}));

app.get('/', function(req, res) {
  res.sendfile('index.html');
});

app.listen(3000);

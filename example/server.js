var express = require('express');
var path = require('path');
var invisible = require('../');
var bodyParser = require('body-parser');


var app = express();
app.use(bodyParser());
invisible.createServer(app, path.join(__dirname, 'models'));

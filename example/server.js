var express = require("express");
var path = require("path");
var invisible = require("../");

var app = express();
app.use(express.bodyParser());

invisible.createServer(app, path.join(__dirname, "models"));

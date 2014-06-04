'use strict';

var browserify = require('browserify');
var path = require('path');
var fs = require('fs');

module.exports = function (rootFolder, opt) {
  var b, modelFile, modelFiles, modelName, src, _i, _len;
  src = void 0;
  b = browserify();
  b.ignore('mongodb');
  b.ignore('./bundle');
  b.ignore('./routes');
  b.ignore('./router');
  b.ignore('./config');
  b.ignore('./auth');
  b.ignore('socket.io');
  modelFiles = fs.readdirSync(rootFolder);
  for (_i = 0, _len = modelFiles.length; _i < _len; _i++) {
    modelName = modelFiles[_i];
    modelFile = path.join(rootFolder, modelName);
    b.add(modelFile);
    require(modelFile);
  }
  b.bundle(function (err, compiled) {
    if (err != null) {
      throw err;
    }
    src = compiled;
    return console.log('Invisible: Created bundle');
  });
  return function (req, res, next) {
    if (req.path !== '/invisible.js') {
      return next();
    }
    res.contentType('application/javascript');
    return res.send(src);
  };
};

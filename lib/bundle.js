'use strict';

var browserify = require('browserify');
var path = require('path');
var fs = require('fs');

module.exports = function (rootFolder) {

  var src = null;
  var b = browserify();

  [ 'mongodb',
    './bundle',
    './routes',
    './router',
    './config',
    './auth',
    'socket.io'
  ].forEach(function(toIgnore) {
    b.ignore(toIgnore);
  });

  var modelFiles = fs.readdirSync(rootFolder);

  modelFiles.forEach(function(modelName) {
    var modelFile = path.join(rootFolder, modelName);
    b.add(modelFile);
    require(modelFile);
  });

  b.bundle(function (err, compiled) {
    if (err) {
      throw err;
    }

    src = compiled;
    console.log('Invisible: Created bundle');
  });

  return function (req, res, next) {
    if (req.path !== '/invisible.js') {
      return next();
    }
    res.contentType('application/javascript');
    res.send(src);
  };
};

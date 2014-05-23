'use strict';

var io_client = require('socket.io-client');
var io;
var _ = require('underscore');
var Invisible = require('../invisible');

if (!Invisible.isClient()) {
  io = require('socket.io').listen(Invisible.server);
  Invisible.io = io;
  io.set('log level', 1);
}

module.exports = function (InvisibleModel) {
  var localUrl, modelName;
  modelName = InvisibleModel.modelName;
  localUrl = typeof window !== 'undefined' && window !== null ? window.location.hostname : 'localhost';
  InvisibleModel.socket = io_client.connect('' + localUrl + '/' + modelName);
  if (!Invisible.isClient()) {
    InvisibleModel.serverSocket = io.of('/' + modelName);
  }
  InvisibleModel.onNew = function (cb) {
    return InvisibleModel.socket.on('new', function (data) {
      var model;
      model = new InvisibleModel();
      _.extend(model, data);
      return cb(model);
    });
  };
  InvisibleModel.onUpdate = function (cb) {
    return InvisibleModel.socket.on('update', function (data) {
      var model;
      model = new InvisibleModel();
      _.extend(model, data);
      return cb(model);
    });
  };
  return InvisibleModel.onDelete = function (cb) {
    return InvisibleModel.socket.on('delete', function (data) {
      var model;
      model = new InvisibleModel();
      _.extend(model, data);
      return cb(model);
    });
  };
};

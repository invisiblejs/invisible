'use strict';

var Invisible = require('../invisible');
var _ = require('underscore');
var io_client = require('socket.io-client');

module.exports = function (InvisibleModel) {
  var modelName = InvisibleModel.modelName;
  // var localUrl = window ? window.location.hostname : 'localhost';
  var localUrl = 'localhost';

  InvisibleModel.socket = io_client.connect('' + localUrl + '/' + modelName);

  InvisibleModel.onNew = function (cb) {
    InvisibleModel.socket.on('new', function (data) {
      var model = new InvisibleModel();
      _.extend(model, data);
      cb(model);
    });
  };

  InvisibleModel.onUpdate = function (cb) {
    InvisibleModel.socket.on('update', function (data) {
      var model = new InvisibleModel();
      _.extend(model, data);
      cb(model);
    });
  };

  InvisibleModel.onDelete = function (cb) {
    InvisibleModel.socket.on('delete', function (data) {
      var model = new InvisibleModel();
      _.extend(model, data);
      cb(model);
    });
  };

  if (!Invisible.isClient()) {
    InvisibleModel.emit = function(name, data) {
      if (InvisibleModel.serverSocket) {
        InvisibleModel.serverSocket.emit(name, data);
      }
    };
  }

};

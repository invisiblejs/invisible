'use strict';

var Invisible = require('../invisible');
var _ = require('underscore');
var io_client = require('socket.io-client');

module.exports = function (InvisibleModel) {
  var modelName = InvisibleModel.modelName;
  var localUrl = Invisible.getHostname();

  InvisibleModel.socket = io_client.connect('' + localUrl + '/' + modelName);

  InvisibleModel.on = function (event, cb) {
    InvisibleModel.socket.on(event, function (data) {
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

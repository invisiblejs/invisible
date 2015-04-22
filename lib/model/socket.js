'use strict';

var Invisible = require('../invisible');
var _ = require('underscore');
var ioClient = require('socket.io-client');

module.exports = function(InvisibleModel) {
  var modelName = InvisibleModel.modelName;
  var localUrl = Invisible.getHostname();

  InvisibleModel.socket = ioClient.connect('' + localUrl + '/' + modelName);

  InvisibleModel.on = function(event, cb) {
    InvisibleModel.socket.on(event, function(data) {
      var model = new InvisibleModel();
      _.extend(model, data);
      cb(model);
    });
  };

  if (!Invisible.isClient()) {

    var emit = function(name, model) {
      if (InvisibleModel.serverSocket) {
        InvisibleModel.serverSocket.emit(name, model);
      }
    };

    var authEmit = function(name, model) {
      if (InvisibleModel.serverSocket) {
        _.each(InvisibleModel.serverSocket.sockets, function(socket) {
          //individually emit to the authorized clients
          if (!socket.client.user) { return; }
          model.allowEvents(socket.client.user, function(err, authorized) {
            if (!err && authorized) {
              socket.emit(name, model);
            }
          });
        });
      }
    };

    InvisibleModel.emit = InvisibleModel.prototype.allowEvents ? authEmit : emit;
  }
};

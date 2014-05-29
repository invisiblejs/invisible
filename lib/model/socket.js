'use strict';

var Invisible = require('../invisible');
var _ = require('underscore');
var io_client = require('socket.io-client');

module.exports = function (InvisibleModel) {
  var modelName = InvisibleModel.modelName;
  var localUrl = Invisible.isClient() ? window.location.hostname : 'localhost';

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
};

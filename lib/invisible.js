'use strict';

var _ = require('underscore');

var Invisible = {
  models: {}
};

module.exports = Invisible;

Invisible.isClient = function() {
  return typeof window !== 'undefined' && window !== null;
};

if (Invisible.isClient()) {
  window.Invisible = Invisible;

  var authMethods = require('./auth/methods');
  Invisible.login = authMethods.login;
  Invisible.logout = authMethods.logout;
} else {
  Invisible.router = require('./router');

  Invisible.addRealtime = function(app) {
    var io = require('socket.io').listen(app);
    Invisible.io = io;
    io.set('log level', 1);

    _.each(Invisible.models, function(model) {
      model.serverSocket = io.of('/' + model.modelName);
    });
  };
}

Invisible.createModel = function(modelName, InvisibleModel) {
  InvisibleModel.modelName = modelName;

  require('./model/common')(InvisibleModel);
  require('./model/socket')(InvisibleModel);

  var addCrudOperations = Invisible.isClient() ? require('./model/client') : require('./model/server');
  addCrudOperations(InvisibleModel);

  Invisible.models[modelName] = InvisibleModel;

  return InvisibleModel;
};

'use strict';

var utils = require('./utils');
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
  Invisible.login = function(username, password, cb) {
    var http, req, setToken;
    http = require('http');
    setToken = function(err, data) {
      var t;
      if (err) {
        return cb(err);
      }
      if (data.expires_in) {
        t = new Date();
        data['expires_in'] = t.setSeconds(t.getSeconds() + data.expires_in);
      }
      Invisible.AuthToken = data;
      window.localStorage.InvisibleAuthToken = JSON.stringify(data);
      return cb(null);
    };
    req = http.request({
      path: '/invisible/authtoken/',
      method: 'POST',
      headers: {
        'content-type': 'application/json'
      }
    }, utils.handleResponse(setToken));
    req.write(JSON.stringify({
      grant_type: 'password',
      username: username,
      password: password
    }));
    return req.end();
  };
  Invisible.logout = function() {
    Invisible.AuthToken = {};
    return delete window.localStorage.InvisibleAuthToken;
  };
  if (window.localStorage.InvisibleAuthToken) {
    Invisible.AuthToken = JSON.parse(window.localStorage.InvisibleAuthToken);
  } else {
    Invisible.AuthToken = {};
  }
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

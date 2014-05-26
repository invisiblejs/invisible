var Invisible;
var utils = require('./utils');

module.exports = Invisible = {};

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
}

Invisible.createModel = function(modelName, InvisibleModel) {
  var addCrudOperations;
  InvisibleModel.modelName = modelName;
  require('./model/common')(InvisibleModel);
  require('./model/socket')(InvisibleModel);
  addCrudOperations = Invisible.isClient() ? require('./model/client') : require('./model/server');
  addCrudOperations(InvisibleModel);
  Invisible[modelName] = InvisibleModel;
  return InvisibleModel;
};

'use strict';

var utils = require('../utils');
var Invisible = require('../invisible');

if (window.localStorage.InvisibleAuthToken) {
  Invisible.AuthToken = JSON.parse(window.localStorage.InvisibleAuthToken);
} else {
  Invisible.AuthToken = {};
}

module.exports.login = function (username, password, cb) {
  var http, req, setToken;
  http = require('http');
  setToken = function (err, data) {
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

module.exports.logout = function () {
  Invisible.AuthToken = {};
  return delete window.localStorage.InvisibleAuthToken;
};

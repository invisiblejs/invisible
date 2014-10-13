'use strict';

var utils = require('../utils');
var Invisible = require('../invisible');
var _ = require('underscore');
var io_client = require('socket.io-client');

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
    socketAuth();
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

//TODO don't break if auth is on and real time is not
function socketAuth() {
  var localUrl = Invisible.getHostname();

  Invisible.socket = io_client.connect('' + localUrl + '/');
  Invisible.socket.on('connect', function(){
    Invisible.socket.emit('authenticate', {token: Invisible.AuthToken.access_token});
  });

}

module.exports.logout = function () {
  delete Invisible.AuthToken;
  delete window.localStorage.InvisibleAuthToken;
  Invisible.socket.emit('disconnect');
};

'use strict';

var config = require('../config');
var Invisible = require('../invisible');
var Token = require('./token');


var restrictedUrl = function (req) {
  /* Returns true if the request is to a url that should be restricted*/

  var userUrl;
  if (!config.authenticate || req.path.indexOf('/invisible/') !== 0) {
    return false;
  }
  userUrl = '/invisible/' + (config.userModel || 'User');
  if (req.method === 'POST' && req.path.indexOf(userUrl) === 0) {
    return false;
  }
  return true;
};

module.exports = function (req, res, next) {
  /*
  Auth middleware. If authentication is configured, exposes a 'authtoken'
  url to generate an access_token following OAuth2's password grant.
  All other endpoints will require the token in the Authorization header.
  */

  var header, token;
  if (!restrictedUrl(req)) {
    return next();
  }
  if (req.path.indexOf('/invisible/authtoken/') === 0) {
    return Token.route(req, res);
  }
  header = req.header('Authorization');
  if (!header || !header.indexOf('Bearer ') === 0) {
    return res.send(401);
  }
  
  var tokenData = {token: header.split(' ')[1]};
  Token.findUser(tokenData, function(err, user) {
    if (err) return res.send(401);
    req.user = user;
    return next();
  });
};

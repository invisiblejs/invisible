'use strict';

var mongo = require('mongodb');
var config = require('./config');
var Invisible = require('./invisible');
var crypto = require('crypto');
var col = void 0;

mongo.connect(config.db_uri, function (err, database) {
  if (err != null) {
    throw err;
  }
  return col = database.collection('AuthToken');
});

var generateToken = function (user, cb) {
  /* Takes a user model a generates a new access_token for it.*/

  return crypto.randomBytes(48, function (ex, buf) {
    var token;
    token = buf.toString('hex');
    return crypto.randomBytes(48, function (ex, buf) {
      var data, refresh, seconds, t;
      data = {
        token: token,
        user: user._id
      };
      seconds = config.authExpiration;
      if (seconds) {
        refresh = buf.toString('hex');
        t = new Date();
        t.setSeconds(t.getSeconds() + seconds + 10);
        data.refresh = refresh;
        data.expires = t;
      }
      return col.save(data, function (err, result) {
        if (err) {
          return cb(err);
        }
        token = {
          token_type: 'bearer',
          access_token: data.token,
          user_id: user._id.toString()
        };
        if (seconds) {
          token.refresh_token = refresh;
          token.expires_in = seconds;
        }
        return cb(null, token);
      });
    });
  });
};

var getToken = function (req, res) {
  /*
  Controller that generates and saves the access_token, either based on the
  client credentials or a previously generated refresh token.
  */

  var password, refresh, sendToken, username;
  sendToken = function (err, user) {
    if (err || !user) {
      return res.send(401);
    }
    return generateToken(user, function (err, token) {
      if (err) {
        return res.send(401);
      }
      return res.send(200, token);
    });
  };
  if (req.body.grant_type === 'password') {
    username = req.body.username;
    password = req.body.password;
    if (!username || !password) {
      return res.send(401);
    }
    return config.authenticate(username, password, sendToken);
  } else if (req.body.grant_type === 'refresh_token') {
    refresh = req.body.refresh_token;
    if (!refresh) {
      return res.send(401);
    }
    return col.findOne({
      refresh: refresh
    }, function (err, token) {
      if (err || !token) {
        return res.send(401);
      }
      return col.remove({
        refresh: token.refresh
      }, function (err) {
        return Invisible[config.userModel || 'User'].findById(token.user.toString(), sendToken);
      });
    });
  } else {
    return res.send(401);
  }
};

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
    return getToken(req, res);
  }
  header = req.header('Authorization');
  if (!header || !header.indexOf('Bearer ') === 0) {
    return res.send(401);
  }
  token = header.split(' ')[1];
  return col.findOne({
    token: token
  }, function (err, token) {
    if (err || !token) {
      return res.send(401);
    }
    if (token.expires && new Date() > token.expires) {
      return res.send(401);
    }
    return Invisible[config.userModel || 'User'].findById(token.user.toString(), function (err, user) {
      if (err) {
        return res.send(401);
      }
      req.user = user;
      return next();
    });
  });
};

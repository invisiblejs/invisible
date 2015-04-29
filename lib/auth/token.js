'use strict';

var crypto = require('crypto');
var config = require('../config');
var Invisible = require('../invisible');
var connectDB = require('../utils').connectDB;

var col = null;
connectDB(function(database) {
  col = database.collection('AuthToken');
});

function newToken(user, cb) {
  /* Takes a user model a generates a new access_token for it.*/

  return crypto.randomBytes(48, function(ex, buf) {
    var token;
    token = buf.toString('hex');
    return crypto.randomBytes(48, function(ex, buf) {
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
      return col.save(data, function(err) {
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
}

exports.findUser = function(tokenData, cb) {
  /* Given a token model, check the token is valid and find the associated user. */
  exports.check(tokenData, function(err, tokenModel) {
    if (err) {
      return cb(err);
    }

    var User = Invisible.models[config.userModel || 'User'];
    User.findById(tokenModel.user.toString(), function(err, user) {
      if (err) {
        return cb(err);
      }
      cb(null, user);
    });
  });
};

exports.check = function(tokenData, cb) {
  /*
  Checks the database for a valid, non expired token of the given value.
  */
  var token = tokenData.token;
  col.findOne({token: token}, function(err, token) {
    if (err || !token) {
      return cb(new Error('Token not found'));
    }
    if (token.expires && new Date() > token.expires) {
      return cb(new Error('Token expired'));
    }
    return cb(null, token);
  });

};

exports.route = function(req, res) {
  /*
  Controller that generates and saves the access_token, either based on the
  client credentials or a previously generated refresh token.
  */

  var password, refresh, sendToken, username;
  sendToken = function(err, user) {
    if (err || !user) {
      return res.sendStatus(401);
    }
    return newToken(user, function(err, token) {
      if (err) {
        return res.sendStatus(401);
      }
      return res.send(token);
    });
  };
  if (req.body.grant_type === 'password') {
    username = req.body.username;
    password = req.body.password;
    if (!username || !password) {
      return res.sendStatus(401);
    }
    return config.authenticate(username, password, sendToken);
  } else if (req.body.grant_type === 'refresh_token') {
    refresh = req.body.refresh_token;
    if (!refresh) {
      return res.sendStatus(401);
    }
    return col.findOne({
      refresh: refresh
    }, function(err, token) {
      if (err || !token) {
        return res.sendStatus(401);
      }
      return col.remove({
        refresh: token.refresh
      }, function() {
        return Invisible.models[config.userModel || 'User'].findById(token.user.toString(), sendToken);
      });
    });
  } else {
    return res.sendStatus(401);
  }
};

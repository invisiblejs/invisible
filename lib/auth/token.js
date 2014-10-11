
var crypto = require('crypto');
var config = require('../config');
var Invisible = require('../invisible');
var connectDB = require('../utils').connectDB;

var col = null;
connectDB(function (database) {
  col = database.collection('AuthToken');
});

function newToken(user, cb) {
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


exports.check = function(token, success, failure) {
	/* 
	Checks the database for a valid, non expired token of the given value.
	If it finds one, it calls success, otherwise it calls failure.
	*/
	col.findOne({token: token}, function (err, token) {
    failure = failure || function(){};
    success = success || function(){};
    if (err || !token) {
      return failure()
    }
    if (token.expires && new Date() > token.expires) {
      return failure()
    }
    return success(token);
	});

}

exports.route = function (req, res) {
  /*
  Controller that generates and saves the access_token, either based on the
  client credentials or a previously generated refresh token.
  */

  var password, refresh, sendToken, username;
  sendToken = function (err, user) {
    if (err || !user) {
      return res.send(401);
    }
    return newToken(user, function (err, token) {
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
        return Invisible.models[config.userModel || 'User'].findById(token.user.toString(), sendToken);
      });
    });
  } else {
    return res.send(401);
  }
};
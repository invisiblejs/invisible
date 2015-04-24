'use strict';

var crypto = require('crypto');
var Invisible = require('../../..');

var SALT = 'THIS IS MY SALT';

function User(username) {
  this.username = username;
}

User.prototype.setPassword = function(rawPassword) {
  var h = crypto.createHash('sha1');
  h.update(rawPassword);
  h.update(SALT);
  this.password = h.digest('base64');
};

User.prototype.checkPassword = function(rawPassword) {
  var h = crypto.createHash('sha1');
  h.update(rawPassword);
  h.update(SALT);
  return h.digest('base64') === this.password;
};

User.authenticate = function(username, password, done) {
  User.query({username: username}, function(err, users) {
    if (err) {
      return done(err);
    }

    if (users.length < 1) {
      return done(null, false);
    }

    var user = users[0];
    if (!user.checkPassword(password)) {
      return done(null, false);
    }
    done(null, user);
  });
};

module.exports = Invisible.createModel('User', User);

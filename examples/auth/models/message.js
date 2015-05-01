'use strict';

var Invisible = require('../../..');

function Message(fromId, toId, text) {
  this.from_id = fromId;
  this.to_id = toId;
  this.text = text;
}

Message.prototype.allowCreate = function(user, cb) {
  //a user can only create messages sent by him
  return cb(null, this.from_id === user._id);
};

Message.prototype.allowUpdate = function(user, cb) {
  //a user can only update messages sent by him
  return cb(null, this.from_id === user._id);
};

Message.prototype.allowFind = function(user, cb) {
  //a user can only get messages sent by him or to him
  return cb(null, this.from_id === user._id || this.to_id === user._id);
};

Message.prototype.allowDelete = function(user, cb) {
  //a user cannot delete messages
  return cb(null, false);
};

Message.prototype.allowEvents = function(user, cb) {
  //only sent events when a message is sent to the user
  return cb(null, this.to_id === user._id);
};

module.exports = Invisible.createModel('Message', Message);

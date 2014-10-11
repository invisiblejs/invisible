var Invisible = require('../..');

function Message(from, to, text){
    this.from = from._id.toString();
    this.to = to._id.toString();
    this.text = text;
}

Message.prototype.allowCreate = function(user, cb) {
    //a user can only create messages sent by him
    return cb(null, from === user._id.toString());
}

Message.prototype.allowUpdate = function(user, cb) {
    //a user can only update messages sent by him
    return cb(null, from === user._id.toString());
}

Message.prototype.allowFind = function(user, cb) {
    //a user can only get messages sent by him or to him
    return cb(null, from === user._id.toString() || to === user._id.toString());
}

Message.prototype.allowDelete = function(user, cb) {
    //a user cannot delete messages
    return cb(null, false);
}

module.exports = Invisible.createModel("Message", Message);
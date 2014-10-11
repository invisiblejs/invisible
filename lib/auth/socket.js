
var _ = require('underscore');
var Token = require('./token');

function forbidConnections(nsp) {
  /* 
  Set a listener so connections from unauthenticated sockets are not
  considered when emitting to the namespace. The connections will be
  restored after authentication succeeds.
  */
  nsp.on('connection', function(socket){
    if (!socket.auth) {
      console.log("removing socket from", nsp.name)
      nsp.connected[socket.id] = undefined;
    }
  });
}

function restoreConnection(nsp, socket) {
  /*
  If the socket attempted a connection before authentication, restore it.
  */
  if(_.findWhere(nsp.sockets, {id: socket.id})) {
    console.log("restoring socket to", nsp.name);
    nsp.connected[socket.id] = socket;
  }
}

module.exports = function(io){
  /* 
  Adds connection listeners to the given socket.io server, so clients
  are forced to authenticate before they can receive events.
  */
  _.each(io.nsps, forbidConnections);
  io.on('connection', function(socket){
    
    socket.auth = false;
    socket.on('authenticate', function(data){
      Token.check(data.token, function(){
        console.log("Authenticated socket ", socket.id);
        socket.auth = true;
        _.each(io.nsps, function(nsp) {
          restoreConnection(nsp, socket);
        });
      });
    });

    setTimeout(function(){
      //If the socket didn't authenticate after connection, disconnect it
      if (!socket.auth) {
        console.log("Disconnecting socket ", socket.id);
        socket.disconnect('unauthorized');
      }
    }, 1000);

  });
}
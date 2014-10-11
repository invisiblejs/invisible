'use strict';

var _ = require('underscore');

var Invisible = {
  models: {}
};

module.exports = Invisible;

Invisible.isClient = function() {
  return typeof window !== 'undefined' && window !== null;
};

Invisible.getHostname = function() {
  return Invisible.isClient() ? window.location.hostname : 'localhost';
};

if (Invisible.isClient()) {
  window.Invisible = Invisible;

  var authMethods = require('./auth/methods');
  Invisible.login = authMethods.login;
  Invisible.logout = authMethods.logout;
} else {
  Invisible.router = require('./router');

  Invisible.addRealtime = function(app) {
    var io = require('socket.io').listen(app);
    Invisible.io = io;

    _.each(Invisible.models, function(model) {
      model.serverSocket = io.of('/' + model.modelName);
    });

    //FIXME move all this crap
    //remove the inline requires

    var useAuth = require('./config').authenticate;
    if (useAuth) {
      _.each(io.nsps, function(nsp) {
        nsp.on('connection', function(socket){
          //don't consider connected until it authenticates
          if (!socket.auth) {
            console.log("removing socket from", nsp.name)
            nsp.connected[socket.id] = undefined;
          }
        });
      });

      io.on('connection', function(socket){
        socket.auth = false;

        socket.on('authenticate', function(data){
          //check access token exists in database
          var Token = require('./auth/token');
          Token.check(data.token, function(){
            console.log("Authenticated socket ", socket.id);
            socket.auth = true;
            //restore connections attempted before auth
            _.each(io.nsps, function(nsp) {
              if(_.findWhere(nsp.sockets, {id: socket.id})) {
                console.log("restoring socket to", nsp.name);
                nsp.connected[socket.id] = socket;
              }
            });
          });
        });

        setTimeout(function(){
          if (!socket.auth) {
            console.log("Disconnecting socket ", socket.id);
            socket.disconnect('unauthorized');
          }
        }, 2000);

      });
    }

  };
}

Invisible.createModel = function(modelName, InvisibleModel) {
  InvisibleModel.modelName = modelName;

  require('./model/common')(InvisibleModel);
  require('./model/socket')(InvisibleModel);

  var addCrudOperations = Invisible.isClient() ? require('./model/client') : require('./model/server');
  addCrudOperations(InvisibleModel);

  Invisible.models[modelName] = InvisibleModel;

  return InvisibleModel;
};

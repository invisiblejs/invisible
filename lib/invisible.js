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

    //FIXME move all this crap
    //TODO think how to auth once
    //remove the inline requires

    _.each(Invisible.models, function(model) {
      model.serverSocket = io.of('/' + model.modelName);
      
      var useAuth = require('./config').authenticate;
      if (useAuth) {

        var connectDB = require('./utils').connectDB;
        var col = null;
        connectDB(function (database) {
          col = database.collection('AuthToken');
        });

        model.serverSocket.on('connection', function(socket){
          //don't consider connected until it authenticates
          model.serverSocket.connected[socket.id] = undefined
          socket.auth = false;

          socket.on('authenticate', function(data){
            //check access token exists in database
            var Token = require('./auth/token');
            Token.check(data.token, function(){
              socket.auth = true;
              model.serverSocket.connected[socket.id] = socket
              console.log("Authenticated socket ", socket.id);
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

    });
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

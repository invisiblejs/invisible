'use strict';

var Invisible, checkAuth, query, remove, save, show, update, _;

_ = require('underscore');
Invisible = require('./invisible');

module.exports = function(app) {
  app.get('/invisible/:modelName', query);
  app.post('/invisible/:modelName', save);
  app.get('/invisible/:modelName/:id', show);
  app.put('/invisible/:modelName/:id', update);
  app['delete']('/invisible/:modelName/:id', remove);
};

checkAuth = function(req, res, model, method, cb) {
  /*
  If the user is defined in the request (i.e. authentication is on), and
  the given model has an allow method with the given name, execute it to
  check if the user is authorized to fulfill the request. If it's authorized
  call cb, otherwise send a 401 response.
  */

  if (req.user && model[method]) {
    return model[method](req.user, function(err, authorized) {
      if (err || !authorized) {
        return res.send(401);
      }
      return cb();
    });
  } else {
    return cb();
  }
};

query = function(req, res) {
  var Model, criteria, opts;
  if (req.query.query != null) {
    criteria = JSON.parse(req.query.query);
  } else {
    criteria = {};
  }
  if (req.query.opts != null) {
    opts = JSON.parse(req.query.opts);
  } else {
    opts = {};
  }
  Model = Invisible.models[req.params.modelName];
  return Model.query(criteria, opts, function(e, results) {
    return res.send(results);
  });
};

save = function(req, res) {
  var Model, instance;
  Model = Invisible.models[req.params.modelName];
  instance = new Model();
  _.extend(instance, req.body);
  return checkAuth(req, res, instance, 'allowCreate', function() {
    return instance.save(function(e, instance) {
      if (e) {
        return res.send(400, e);
      }
      return res.send(200, instance);
    });
  });
};

show = function(req, res) {
  var Model, e;
  Model = Invisible.models[req.params.modelName];
  try {
    return Model.findById(req.params.id, function(e, result) {
      if (result != null) {
        return checkAuth(req, res, result, 'allowFind', function() {
          var obj;
          obj = JSON.parse(JSON.stringify(result));
          return res.send(200, obj);
        });
      } else {
        return res.send(404);
      }
    });
  } catch (_error) {
    e = _error;
    return res.send(500, e);
  }
};

update = function(req, res) {
  var Model;
  Model = Invisible.models[req.params.modelName];
  return Model.findById(req.params.id, function(error, instance) {
    if (instance != null) {
      return checkAuth(req, res, instance, 'allowUpdate', function() {
        _.extend(instance, req.body);
        return instance.save(function(e, instance) {
          if (e) {
            return res.send(400, e);
          }
          return res.send(200, instance);
        });
      });
    } else {
      return res.send(404);
    }
  });
};

remove = function(req, res) {
  var Model;
  Model = Invisible.models[req.params.modelName];
  return Model.findById(req.params.id, function(e, instance) {
    if (instance != null) {
      return checkAuth(req, res, instance, 'allowDelete', function() {
        return instance['delete'](function(e, result) {
          return res.send(200);
        });
      });
    } else {
      return res.send(404);
    }
  });
};

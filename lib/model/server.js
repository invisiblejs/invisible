'use strict';

var mongo = require('mongodb');
var _ = require('underscore');
var config = require('../config');
var ObjectID = mongo.ObjectID;
var db = null;

console.log('Conecting to ' + config.db_uri);

mongo.connect(config.db_uri, function (err, database) {
  if (err != null) {
    throw err;
  }
  return db = database;
});

var cleanQuery = function (query) {
  var id;
  if (query._id) {
    if (typeof query._id === 'string') {
      return query._id = ObjectID(query._id);
    } else if (typeof query._id === 'object') {
      if (query._id.$in) {
        query._id.$in = (function () {
          var _i, _len, _ref, _results;
          _ref = query._id.$in;
          _results = [];
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            id = _ref[_i];
            if (typeof id === 'string') {
              _results.push(ObjectID(id));
            }
          }
          return _results;
        })();
      }
      if (query._id.$nin) {
        return query._id.$nin = (function () {
          var _i, _len, _ref, _results;
          _ref = query._id.$nin;
          _results = [];
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            id = _ref[_i];
            if (typeof id === 'string') {
              _results.push(ObjectID(id));
            }
          }
          return _results;
        })();
      }
    }
  }
};

module.exports = function (InvisibleModel) {
  InvisibleModel.findById = function (id, cb) {
    var col;
    col = db.collection(InvisibleModel.modelName);
    return col.findOne({
      _id: new ObjectID(id)
    }, function (err, result) {
      var model;
      if (err != null) {
        return cb(err);
      }
      if (result == null) {
        return cb(new Error('Inexistent id'));
      }
      model = _.extend(new InvisibleModel(), result);
      return cb(null, model);
    });
  };
  InvisibleModel.query = function (query, opts, cb) {
    var col;
    col = db.collection(InvisibleModel.modelName);
    if (cb == null) {
      if (opts == null) {
        cb = query;
        query = {};
      } else {
        cb = opts;
      }
      opts = {};
    }
    cleanQuery(query);
    return col.find(query, {}, opts).toArray(function (err, results) {
      var models, r;
      if (err) {
        return cb(err);
      }
      models = (function () {
        var _i, _len, _results;
        _results = [];
        for (_i = 0, _len = results.length; _i < _len; _i++) {
          r = results[_i];
          _results.push(_.extend(new InvisibleModel(), r));
        }
        return _results;
      })();
      return cb(null, models);
    });
  };
  InvisibleModel.prototype.save = function (cb) {
    var model;
    model = this;
    return this.validate(function (result) {
      var col, data, isNew, update;
      if (!result.valid) {
        return cb(result.errors);
      }
      update = function (err, result) {
        if (err != null) {
          return cb(err);
        }
        if (result == null) {
          return cb(new Error('No result when saving'));
        }
        model = _.extend(model, result);
        if (isNew) {
          InvisibleModel.serverSocket.emit('new', model);
        } else {
          InvisibleModel.serverSocket.emit('update', model);
        }
        if (cb != null) {
          return cb(null, model);
        }
      };
      col = db.collection(InvisibleModel.modelName);
      data = JSON.parse(JSON.stringify(model));
      isNew = !(data._id != null);
      if (data._id != null) {
        data._id = new ObjectID(data._id);
      }
      return col.save(data, update);
    });
  };
  InvisibleModel.prototype['delete'] = function (cb) {
    var col, model;
    model = this;
    col = db.collection(InvisibleModel.modelName);
    return col.remove({
      _id: this._id
    }, function (err, result) {
      if (cb != null) {
        if (err != null) {
          return cb(err);
        }
        if (result == null) {
          return cb(new Error('No result when saving'));
        }
        InvisibleModel.serverSocket.emit('delete', model);
        return cb(null, result);
      }
    });
  };
  return InvisibleModel;
};

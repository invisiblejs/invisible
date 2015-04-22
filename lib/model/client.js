'use strict';

var http = require('http');
var _ = require('underscore');
var Invisible = require('../invisible');
var utils = require('../utils');

/*
Sends a request that includes the required auth header. Uses the
AuthToken if present, and refreshes it if necessary. If no AuthToken is
present, it does not include authorization headers.
An optional payload is written to the request if present.
*/
var authRequest = function(opts, payload, cb) {

  if (!cb) {
    cb = payload;
    payload = undefined;
  }

  var Token = Invisible.AuthToken;

  function sendRequest() {
    if (Token && Token.access_token) {
      opts.headers = opts.headers || {};
      opts.headers.Authorization = 'Bearer ' + Token.access_token;
    }

    var req = http.request(opts, cb);
    if (payload) {
      req.write(payload);
    }
    req.end();
  }

  function setToken(err, data) {
    var t;
    t = new Date();
    data.expires_in = t.setSeconds(t.getSeconds() + data.expires_in);
    Invisible.AuthToken = Token = data;
    if (typeof window !== 'undefined' && window !== null) {
      window.localStorage.InvisibleAuthToken = JSON.stringify(data);
    }
    return sendRequest();
  }

  if (Token && Token.expires_in && new Date() > Token.expires_in) {
    var req = http.request({
      path: '/invisible/authtoken/',
      method: 'POST',
      headers: {
        'content-type': 'application/json'
      }
    }, utils.handleResponse(setToken));

    req.write(JSON.stringify({
      grant_type: 'refresh_token',
      refresh_token: Token.refresh_token
    }));

    req.end();
  } else {
    return sendRequest();
  }
};

module.exports = function(InvisibleModel) {

  InvisibleModel.findById = function(id, cb) {
    var processData = function(err, data) {
      var model;
      if (err) {
        return cb(err);
      }
      model = _.extend(new InvisibleModel(), data);
      return cb(null, model);
    };

    authRequest({
      path: '/invisible/' + InvisibleModel.modelName + '/' + id + '/',
      method: 'GET'
    }, utils.handleResponse(processData));
  };

  InvisibleModel.query = function(query, opts, cb) {
    if (!cb) {
      if (!opts) {
        cb = query;
        query = {};
      } else {
        cb = opts;
      }
      opts = {};
    }

    var qs = '?query=' + encodeURIComponent(JSON.stringify(query)) +
      '&opts=' + encodeURIComponent(JSON.stringify(opts));

    var processData = function(err, data) {
      if (err) {
        return cb(err);
      }

      var models = _.map(data, function(model) {
        return _.extend(new InvisibleModel(), model);
      });

      cb(null, models);
    };

    authRequest({
      path: '/invisible/' + InvisibleModel.modelName + '/' + qs,
      method: 'GET'
    }, utils.handleResponse(processData));
  };

  InvisibleModel.prototype.save = function(cb) {
    var model = this;
    var update = function(err, data) {
      if (err && cb) {
        return cb(err);
      }

      _.extend(model, data);

      if (cb) {
        return cb(null, model);
      }
    };

    this.validate(function(result) {
      if (!result.valid && cb) {
        return cb(result.errors);
      }

      var headers = {
        'content-type': 'application/json'
      };

      if (model._id) {
        authRequest({
          path: '/invisible/' + InvisibleModel.modelName + '/' + model._id + '/',
          method: 'PUT',
          headers: headers
        }, JSON.stringify(model), utils.handleResponse(update));
      } else {
        authRequest({
          path: '/invisible/' + InvisibleModel.modelName + '/',
          method: 'POST',
          headers: headers
        }, JSON.stringify(model), utils.handleResponse(update));
      }
    });
  };

  InvisibleModel.prototype.delete = function(cb) {
    if (this._id) {
      var model = this;

      authRequest({
        path: '/invisible/' + InvisibleModel.modelName + '/' + this._id + '/',
        method: 'DELETE'
      }, function(err) {
        if (cb) {
          if (err) {
            cb(err);
          } else {
            cb(null, model);
          }
        }
      });
    }
  };

  return InvisibleModel;
};

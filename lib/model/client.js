'use strict';

var http = require('http');
var _ = require('underscore');
var Invisible = require('../invisible');
var utils = require('../utils');

var authRequest = function (opts, payload, cb) {
  /*
  Sends a request that includes the required auth header. Uses the
  AuthToken if present, and refreshes it if necessary. If no AuthToken is
  present, it does not include authorization headers.
  An optional payload is written to the request if present.
  */

  var Token, req, sendRequest, setToken;
  if (!cb) {
    cb = payload;
    payload = void 0;
  }
  Token = Invisible.AuthToken;
  sendRequest = function () {
    var req;
    if (Token && Token.access_token) {
      opts.headers = opts.headers || {};
      opts.headers['Authorization'] = 'Bearer ' + Token.access_token;
    }
    req = http.request(opts, cb);
    if (payload) {
      req.write(payload);
    }
    return req.end();
  };
  if (Token && Token.expires_in && new Date() > Token.expires_in) {
    setToken = function (err, data) {
      var t;
      t = new Date();
      data['expires_in'] = t.setSeconds(t.getSeconds() + data.expires_in);
      Invisible.AuthToken = Token = data;
      if (typeof window !== 'undefined' && window !== null) {
        window.localStorage.InvisibleAuthToken = JSON.stringify(data);
      }
      return sendRequest();
    };
    req = http.request({
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
    return req.end();
  } else {
    return sendRequest();
  }
};

module.exports = function (InvisibleModel) {
  InvisibleModel.findById = function (id, cb) {
    var processData;
    processData = function (err, data) {
      var model;
      if (err) {
        return cb(err);
      }
      model = _.extend(new InvisibleModel(), data);
      return cb(null, model);
    };
    return authRequest({
      path: '/invisible/' + InvisibleModel.modelName + '/' + id + '/',
      method: 'GET'
    }, utils.handleResponse(processData));
  };
  InvisibleModel.query = function (query, opts, cb) {
    var processData, qs;
    if (cb == null) {
      if (opts == null) {
        cb = query;
        query = {};
      } else {
        cb = opts;
      }
      opts = {};
    }
    qs = '?query=' + encodeURIComponent(JSON.stringify(query)) + '&opts=' + encodeURIComponent(JSON.stringify(opts));
    processData = function (err, data) {
      var d, models;
      if (err) {
        return cb(err);
      }
      models = (function () {
        var _i, _len, _results;
        _results = [];
        for (_i = 0, _len = data.length; _i < _len; _i++) {
          d = data[_i];
          _results.push(_.extend(new InvisibleModel(), d));
        }
        return _results;
      })();
      return cb(null, models);
    };
    return authRequest({
      path: '/invisible/' + InvisibleModel.modelName + '/' + qs,
      method: 'GET'
    }, utils.handleResponse(processData));
  };
  InvisibleModel.prototype.save = function (cb) {
    var model, update;
    model = this;
    update = function (err, data) {
      if (err && cb) {
        return cb(err);
      }
      _.extend(model, data);
      if (cb != null) {
        return cb(null, model);
      }
    };
    return this.validate(function (result) {
      var headers;
      if (!result.valid) {
        return cb(result.errors);
      }
      headers = {
        'content-type': 'application/json'
      };
      if (model._id != null) {
        return authRequest({
          path: '/invisible/' + InvisibleModel.modelName + '/' + model._id + '/',
          method: 'PUT',
          headers: headers
        }, JSON.stringify(model), utils.handleResponse(update));
      } else {
        return authRequest({
          path: '/invisible/' + InvisibleModel.modelName + '/',
          method: 'POST',
          headers: headers
        }, JSON.stringify(model), utils.handleResponse(update));
      }
    });
  };
  InvisibleModel.prototype['delete'] = function (cb) {
    var model, _cb;
    if (this._id != null) {
      model = this;
      _cb = function (err, res) {
        if (cb) {
          if (err) {
            return cb(err);
          }
          return cb(null, model);
        }
      };
      authRequest({
        path: '/invisible/' + InvisibleModel.modelName + '/' + this._id + '/',
        method: 'DELETE'
      }, _cb);
    }
  };
  return InvisibleModel;
};

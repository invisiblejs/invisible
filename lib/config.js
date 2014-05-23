'use strict';

module.exports = {
  db_uri: 'mongodb://127.0.0.1:27017/invisible'
};

module.exports.customize = function (newConfig) {
  var config, k, v, _results;
  config = module.exports;
  _results = [];
  for (k in newConfig) {
    v = newConfig[k];
    _results.push(config[k] = v);
  }
  return _results;
};

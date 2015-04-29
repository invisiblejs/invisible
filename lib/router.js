'use strict';

var express = require('express');
var config = require('./config');
var bodyParser = require('body-parser');
var _ = require('underscore');

module.exports = function(userConfig) {
  var router = express.Router();

  _.extend(config, userConfig);

  router.use(bodyParser.json());
  router.use(require('./bundle')(config.rootFolder));
  router.use(require('./auth'));
  require('./routes')(router);

  return router;
};

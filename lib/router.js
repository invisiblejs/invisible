'use strict';

var express = require('express');
var config = require('./config');
var bodyParser = require('body-parser');

module.exports = function(userConfig) {
  var router = express.Router();

  config.customize(userConfig);

  router.use(bodyParser());
  router.use(require('./bundle')(config.rootFolder));
  router.use(require('./auth'));
  require('./routes')(router);

  return router;
};

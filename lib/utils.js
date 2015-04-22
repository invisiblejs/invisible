'use strict';

/*
 * Collects the response body, parses it as JSON and passes it to the callback.
 */
exports.handleResponse = function(cb) {
  return function(res) {
    var fullBody;
    fullBody = '';
    res.on('data', function(chunk) {
      return fullBody += chunk;
    });
    return res.on('end', function() {
      var data;
      if (res.statusCode !== 200) {
        return cb(new Error('Error'));
      }
      data = JSON.parse(fullBody);
      return cb(null, data);
    });
  };
};

exports.connectDB = function(cb) {
  var mongo = require('mongodb');
  var config = require('./config');

  mongo.connect(config.db_uri, function(err, database) {
    //TODO do this just once
    console.log('database connected at ' + config.db_uri);
    if (err) {
      console.error('Error connecting database');
      throw err;
    }
    cb(database);
  });
};

'use strict';

module.exports = {
  handleResponse: function (cb) {
    /*
    Collects the response body, parses it as JSON and passes it to the callback.
    */
    return function (res) {
      var fullBody;
      fullBody = '';
      res.on('data', function (chunk) {
        return fullBody += chunk;
      });
      return res.on('end', function () {
        var data;
        if (res.statusCode !== 200) {
          return cb(new Error('Error'));
        }
        data = JSON.parse(fullBody);
        return cb(null, data);
      });
    };
  }
};

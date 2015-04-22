'use strict';

var revalidator = require('revalidator');

module.exports = function(InvisibleModel) {

  InvisibleModel.prototype.validate = function(cb) {
    var validations = this.validations || {};

    // sync validations
    var result = revalidator.validate(this, validations);
    if (!result.valid || !validations.methods) {
      return cb(result);
    }

    // sync validations
    var methods = validations.methods.slice(0);
    var model = this;

    /*
      Traverses the methods list, calling each validation method while
      they're valid. When one is invalid or after all have been called,
      call the cb with the validations result.
      */
    var processValidation = function(model, methods, cb) {

      // take the next validation from the list
      var method = methods.shift();
      if (!method) {
        // if no next method, all were valid
        return cb({
          valid: true,
          errors: []
        });
      } else {
        // call the next method
        return model[method](function(result) {
          if (!result.valid) {
            // validation failed
            return cb(result);
          }

          // keep validating methods
          processValidation(model, methods, cb);
        });
      }
    };

    // start the validations
    return processValidation(model, methods, cb);
  };
};

'use strict';

var revalidator = require('revalidator');

module.exports = function (InvisibleModel) {
  return InvisibleModel.prototype.validate = function (cb) {
    var methods, model, processValidation, result, validations;
    validations = this.validations || {};
    result = revalidator.validate(this, validations);
    if (!result.valid || !validations.methods) {
      return cb(result);
    }
    methods = validations.methods.slice(0);
    model = this;
    processValidation = function (model, methods, cb) {
      /*
        Traverses the methods list, calling each validation method while
        they're valid. When one is invalid or after all have been called,
        call the cb with the validations result.
        */

      var method;
      method = methods.shift();
      if (!method) {
        return cb({
          valid: true,
          errors: []
        });
      } else {
        return model[method](function (result) {
          if (!result.valid) {
            return cb(result);
          }
          return processValidation(model, methods, cb);
        });
      }
    };
    return processValidation(model, methods, cb);
  };
};

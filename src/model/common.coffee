revalidator = require("revalidator")

module.exports = (InvisibleModel) ->

    InvisibleModel.prototype.validate = (cb)->
        #TODO pop out method validations
        #sync validations
        validations = @validations or {}
        result = revalidator.validate(this, validations)

        #TODO async validations
        return cb(result)

revalidator = require("revalidator")

module.exports = (InvisibleModel) ->

    InvisibleModel.prototype.validate = ()->
        validations = @validations or {}
        revalidator.validate(this, validations)
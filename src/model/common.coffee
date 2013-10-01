revalidator = require("revalidator")

module.exports = (InvisibleModel) ->

    InvisibleModel.prototype.validate = (cb)->

        validations = @validations or {}
        
        #sync validations
        result = revalidator.validate(this, validations)
        if not result.valid or not validations.methods
          return cb(result)

        #async validations
        methods = validations.methods[..]
        model = this
        processValidation = (model, methods, cb) ->
          ### 
          Traverses the methods list, calling each validation method while 
          they're valid. When one is invalid or after all have been called, 
          call the cb with the validations result.
          ###
          
          #take the next validation from the list
          method = methods.shift()
          if not method
            #if no next method, all were valid
            return cb(valid: true, errors: [])

          else
            #call the next method
            model[method] (result)->
              if not result.valid
                # validation failed
                return cb(result)

              # keep validating methods
              processValidation(model, methods, cb)

        #start the validations
        processValidation(model, methods, cb)


            
          
        

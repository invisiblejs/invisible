request = require("hyperquest")


Invisible = 
    _conf: {}

    createModel: (modelName, Model) ->
        console.log('Creating a Invisible Model: ' + modelName)
        
        class InvisibleModel extends Model
            @_modelName: modelName
            
            @query: (opts)-> 
                console.log("querying")
                #TODO implement
                return {}

            save: () -> 
                console.log("saving")
                
                update = (error, res, body) ->
                    if not error and res.statusCode == 200
                        console.log("got #{body}")

                if @id?
                    opts = 
                        path: "/#{@_modelName}/#{@id}/"
                    request.get(opts, update)
                else
                    opts = 
                        path: "/#{@_modelName}/"
                    request.post(opts, update)
            
            delete: ()-> 
                console.log("deleting")
                if @id?
                    opts = 
                        path: "/#{@_modelName}/#{@id}/"
                    request.delete(opts, update)

            serialize: () -> #TODO implement

        this[modelName] = InvisibleModel
        return InvisibleModel


if window?
    console.log('client')
    window.Invisible = Invisible
else
    console.log('server')

module.exports = Invisible


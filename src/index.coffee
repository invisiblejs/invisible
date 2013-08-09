request = require("hyperquest")


Invisible = 
    _conf: {}

    createModel: (modelName, Model) ->
        console.log('Creating a Invisible Model: ' + modelName)
        
        path = this._conf.path
        class InvisibleModel extends Model
            _modelName: modelName
            
            @query: (opts)-> 
                console.log("querying")
                #TODO implement
                return {}

            save: () -> 
                console.log("saving")
                
                update = (error, res, body) ->
                    console.log("updating saved model")

                    if not error and res.statusCode == 200
                        console.log("got #{body}")
                    return

                if @id?
                    request.get("/models/#{@_modelName}/#{@id}/", update).end()
                else
                    opts =
                        headers: 
                            'content-type': 'application/json'  
                    request.post("/models/#{@_modelName}/", opts, update).end()
                return
            
            delete: ()-> 
                console.log("deleting")
                if @id?
                    request.delete("#{path}/#{@_modelName}/#{@id}/", update).end()
                return

            serialize: () -> #TODO implement

        this[modelName] = InvisibleModel
        return InvisibleModel


if window?
    console.log('client')
    window.Invisible = Invisible
else
    console.log('server')

module.exports = Invisible


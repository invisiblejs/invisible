request = require("hyperquest")
_ = require("underscore")

Invisible = 
    _conf: {}

    createModel: (modelName, Model) ->
        console.log('Creating a Invisible Model: ' + modelName)
        
        class InvisibleModel extends Model
            _modelName: modelName
            
            @query: (opts)-> 
                console.log("querying")
                #TODO implement
                return {}

            save: () -> 
                console.log("saving")
                model = this
                
                update = (error, res) ->
                    fullBody = ''
                    res.on('data', (chunk) -> 
                        fullBody += chunk)
                    res.on('end', () ->
                        console.log("updating model with #{fullBody}")
                        _.extend(model, JSON.parse(fullBody)))

                #TODO add data (serialize this)
                if @id?
                    request.put("/models/#{@_modelName}/#{@id}/", update).end()
                else
                    request.post("/models/#{@_modelName}/", update).end()
                return
            
            delete: ()-> 
                console.log("deleting")
                if @id?
                    cb = (err, res) ->
                        #TODO handle error
                        console.log("deleted")
                    request.delete("/models/#{@_modelName}/#{@id}/", cb).end()
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


http = require("http")
_ = require("underscore")

isClient = () ->
    window?

Invisible = 
    _conf: {}

    createModel: (modelName, Model) ->
        console.log('Creating a Invisible Model: ' + modelName)
        
        if isClient()
            InvisibleModel = buildClientModel(modelName, Model)
        else
            InvisibleModel = buildServerModel(modelName, Model)

        this[modelName] = InvisibleModel
        return InvisibleModel


buildClientModel = (modelName, BaseModel)->
    class InvisibleModel extends BaseModel
            _modelName: modelName
            
            @query: (opts)-> 
                console.log("querying")
                #TODO implement
                return {}

            save: () -> 
                console.log("saving")
                model = this
                
                update = (res) ->
                    fullBody = ''
                    res.on('data', (chunk) -> 
                        fullBody += chunk)
                    res.on('end', () ->
                        console.log("updating model with #{fullBody}")
                        _.extend(model, JSON.parse(fullBody)))

                if @id?
                    req = http.request(
                        {path: "/models/#{@_modelName}/#{@id}/", method: "PUT"}, 
                        update)
                else
                    req = http.request(
                        {path: "/models/#{@_modelName}/", method: "POST"}, 
                        update)
                
                req.end(JSON.stringify(this))
                return
            
            delete: ()-> 
                console.log("deleting")
                if @id?
                    cb = (err, res) ->
                        #TODO handle error
                        console.log("deleted")

                    http.request({path: "/models/#{@_modelName}/#{@id}/", method: "DELETE"}, 
                        cb).end()
                return

    return InvisibleModel

#TODO test this one
buildServerModel = (modelName, BaseModel)->
    class InvisibleModel extends BaseModel
            _modelName: modelName
            
            @query: (opts)-> 
                console.log("server querying")
                #TODO implement
                return {}

            save: () -> 
                console.log("server saving")
                #TODO implement
                return
            
            delete: ()-> 
                console.log("server deleting")
                #TODO implement
                return

    return InvisibleModel

if isClient()
    console.log('client')
    window.Invisible = Invisible
else
    console.log('server')

module.exports = Invisible

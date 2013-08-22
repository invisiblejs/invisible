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


handleResponse = (cb) ->
    ###
    Collects the response body, parses it as JSON and passes it to the callback.
    ###
    return (res) ->
        fullBody = ''
        res.on 'data', (chunk) -> 
            fullBody += chunk
        res.on 'end', () ->
            data = JSON.parse(fullBody)
            cb(data)


buildClientModel = (modelName, BaseModel) ->
    class InvisibleModel extends BaseModel
            _modelName: modelName
            @_modelName: modelName #FIXME ugly
            
            @findById: (id, cb) -> 
                processData = (data) ->
                    model = _.extend(new InvisibleModel(), data)
                    cb(model)

                http.request(
                        {path: "/invisible/#{@_modelName}/#{id}", method: "GET"}, 
                        handleResponse(processData)).end()

            @query: (opts, cb) -> 
                #handle optional arg
                if cb?
                    qs = "?query=" + encodeURIComponent(JSON.stringify(opts))
                else
                    cb = opts
                    qs = ''

                processData = (data) ->
                    models = (_.extend(new InvisibleModel(), d) for d in data)
                    cb(models)
                
                http.request(
                        {path: "/invisible/#{@_modelName}/#{qs}", method: "GET"}, 
                        handleResponse(processData)).end()

            save: (cb) -> 
                model = this
                
                update = (data) ->
                    _.extend(model, data)
                    if cb?
                        cb(model)

                if @_id?
                    req = http.request(
                        {path: "/invisible/#{@_modelName}/#{@_id}/", method: "PUT",
                        headers: { 'content-type': "application/json" }}, 
                        handleResponse(update))
                else
                    req = http.request(
                        {path: "/invisible/#{@_modelName}/", method: "POST", 
                        headers: { 'content-type': "application/json" }}, 
                        handleResponse(update))
                
                req.write(JSON.stringify(this))
                req.end()
                return
            
            delete: (cb)-> 
                if @_id?
                    model = this
                    
                    _cb = (err, res) ->
                        #TODO handle error
                        console.log("deleted")
                        if cb?
                            cb(model)

                    http.request({path: "/invisible/#{@_modelName}/#{@_id}/", method: "DELETE"}, 
                        _cb).end()
                return

    return InvisibleModel

#TODO refactor, put each model in different files, and require only one
if not isClient()

    mongo = require('mongodb')
    ObjectID = mongo.ObjectID

    uri = 'mongodb://127.0.0.1:27017/invisible'
    db = undefined

    mongo.connect uri, (err, database) ->
        throw err if err?
        console.log("connected to #{uri}")
        db = database

buildServerModel = (modelName, BaseModel)->

    class InvisibleModel extends BaseModel
            _modelName: modelName
            @_modelName: modelName #FIXME ugly
            
            @findById: (id, cb) -> 
                col = db.collection(@_modelName)
                col.findOne {_id: new ObjectID(id)}, (err, result) ->
                    console.log(err) if err or not result?
                    model = _.extend(new InvisibleModel(), result)
                    cb(model)
            
            @query: (opts, cb) ->
                col = db.collection(@_modelName)
                if not cb?
                    cb = opts
                    opts = {}
                    
                col.find(opts).toArray (err, results) ->
                    console.log(err) if err or not result?
                    models = (_.extend(new InvisibleModel(), r) for r in results)
                    cb(models)   

            save: (cb) -> 
                model = this
                update = (err, result) ->
                    console.log(err) if err or not result?
                    model = _.extend(model, result)
                    if cb?
                        cb(model)

                col = db.collection(@_modelName)
                data = JSON.parse JSON.stringify this
                if data._id?
                    data._id = new ObjectID(data._id)
                col.save data, update
            
            delete: (cb)-> 
                model = this
                col = db.collection(@_modelName)
                col.remove {_id: ObjectID(@_id)}, (err, result) ->
                    console.log(err) if err or not result?
                    if cb?
                        cb(result)

    return InvisibleModel

if isClient()
    console.log('client')
    window.Invisible = Invisible
else
    console.log('server')

module.exports = Invisible

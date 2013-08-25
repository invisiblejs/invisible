mongo = require('mongodb')
_ = require("underscore")

ObjectID = mongo.ObjectID
uri = 'mongodb://127.0.0.1:27017/invisible'
db = undefined

mongo.connect uri, (err, database) ->
    throw err if err?
    console.log("connected to #{uri}")
    db = database

module.exports = (modelName, BaseModel)->

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
                col.remove {_id: @_id}, (err, result) ->
                    console.log(err) if err or not result?
                    if cb?
                        cb(result)

    return InvisibleModel
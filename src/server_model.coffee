mongo = require('mongodb')
_ = require("underscore")

ObjectID = mongo.ObjectID
uri = global.invisibledb or 'mongodb://127.0.0.1:27017/invisible'
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
                    if err?
                        return cb(err)
                    if not result?
                        return cb(new Error("Inexistent id"))

                    model = _.extend(new InvisibleModel(), result)
                    cb(null, model)
            
            @query: (query, opts, cb) ->
                col = db.collection(@_modelName)
                if not cb?
                    if not opts?
                        cb = query
                        query = {}
                    else
                        cb = opts
                    opts = {}
                    
                col.find(query, {}, opts).toArray (err, results) ->
                    if err
                        return cb(err)

                    models = (_.extend(new InvisibleModel(), r) for r in results)
                    cb(null, models)

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
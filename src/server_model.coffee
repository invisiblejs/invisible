mongo = require('mongodb')
_ = require("underscore")
revalidator = require("revalidator")

ObjectID = mongo.ObjectID
uri = global.invisibledb or 'mongodb://127.0.0.1:27017/invisible'
db = undefined

mongo.connect uri, (err, database) ->
    throw err if err?
    db = database

module.exports = (modelName, BaseModel, validations)->

    class InvisibleModel extends BaseModel
            #TODO factor out repeated lines
            _modelName: modelName
            @_modelName: modelName #FIXME 

            _validations: validations
            @_validations: validations

            validate: ()->
                validations = @validations or {}
                revalidator.validate(this, validations)
            
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

                result = @validate()
                if not result.valid
                    err = new Error("ValidationError")
                    err.errors = result.errors
                    throw err

                update = (err, result) ->
                    if err?
                        return cb(err)
                    if not result?
                        return cb(new Error("No result when saving"))

                    model = _.extend(model, result)
                    if cb?
                        return cb(null, model)

                col = db.collection(@_modelName)
                data = JSON.parse JSON.stringify this
                if data._id?
                    data._id = new ObjectID(data._id)
                col.save data, update
            
            delete: (cb)-> 
                model = this
                col = db.collection(@_modelName)
                col.remove {_id: @_id}, (err, result) ->
                    if cb?
                        if err?
                            return cb(err)
                        if not result?
                            return cb(new Error("No result when saving"))

                        return cb(null, result)

    return InvisibleModel
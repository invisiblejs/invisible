mongo = require('mongodb')
_ = require("underscore")
config = require('../config')

ObjectID = mongo.ObjectID
db = undefined

console.log("Conecting to #{config.db_uri}")
mongo.connect config.db_uri, (err, database) ->
    throw err if err?
    db = database

cleanQuery = (query) ->
    #Patches the query in case it refers to _id as a string
    if query._id
        if typeof query._id == 'string'
            query._id = ObjectID(query._id)
        else if typeof query._id == 'object'
            if query._id.$in
                query._id.$in = (ObjectID(id) for id in query._id.$in when typeof id == 'string')
            if query._id.$nin
                query._id.$nin = (ObjectID(id) for id in query._id.$nin when typeof id == 'string')



module.exports = (InvisibleModel)->

    InvisibleModel.findById = (id, cb) ->
        col = db.collection(InvisibleModel.modelName)
        col.findOne {_id: new ObjectID(id)}, (err, result) ->
            if err?
                return cb(err)
            if not result?
                return cb(new Error("Inexistent id"))

            model = _.extend(new InvisibleModel(), result)
            cb(null, model)

    InvisibleModel.query = (query, opts, cb) ->
        col = db.collection(InvisibleModel.modelName)
        if not cb?
            if not opts?
                cb = query
                query = {}
            else
                cb = opts
            opts = {}

        cleanQuery(query)

        col.find(query, {}, opts).toArray (err, results) ->
            if err
                return cb(err)

            models = (_.extend(new InvisibleModel(), r) for r in results)
            cb(null, models)

    InvisibleModel::save = (cb) ->
        model = this

        @validate (result) ->
            if not result.valid
                return cb(result.errors)

            update = (err, result) ->
                if err?
                    return cb(err)
                if not result?
                    return cb(new Error("No result when saving"))

                model = _.extend(model, result)
                if isNew
                    InvisibleModel.serverSocket.emit('new', model)
                else
                    InvisibleModel.serverSocket.emit('update', model)
                if cb?
                    return cb(null, model)

            col = db.collection(InvisibleModel.modelName)
            data = JSON.parse JSON.stringify model
            isNew = !(data._id?)
            if data._id?
                data._id = new ObjectID(data._id)
            col.save data, update

    InvisibleModel::delete = (cb)->
        model = this
        col = db.collection(InvisibleModel.modelName)
        col.remove {_id: @_id}, (err, result) ->
            if cb?
                if err?
                    return cb(err)
                if not result?
                    return cb(new Error("No result when saving"))

                InvisibleModel.serverSocket.emit('delete', model)
                return cb(null, result)

    return InvisibleModel

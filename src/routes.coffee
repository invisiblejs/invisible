_ = require("underscore")
Invisible = require('./invisible')

module.exports = (app) ->
    app.get("/invisible/:modelName", query)
    app.post("/invisible/:modelName", save)
    app.get("/invisible/:modelName/:id", show)
    app.put("/invisible/:modelName/:id", update)
    app.delete("/invisible/:modelName/:id", remove)

checkAuth = (req, res, model, method, cb)->
    ###
    If the user is defined in the request (i.e. authentication is on), and
    the given model has an allow method with the given name, execute it to
    check if the user is authorized to fulfill the request. If it's authorized
    call cb, otherwise send a 401 response.
    ###

    if req.user and model[method]
        model[method] req.user, (err, authorized)->
            if err or not authorized
                return res.send(401)
            return cb()
    else
        return cb()



#rest controllers
query = (req, res) ->
    if req.query.query?
        criteria = JSON.parse(req.query.query)
    else
        criteria = {}

    if req.query.opts?
        opts = JSON.parse(req.query.opts)
    else
        opts = {}

    Model = Invisible[req.params.modelName]
    Model.query criteria, opts, (e, results) ->
        res.send(results)

save = (req, res) ->
    Model = Invisible[req.params.modelName]
    instance = new Model()
    _.extend(instance, req.body)
    checkAuth req, res, instance, "allowCreate", ()->

        instance.save (e, instance) ->
            if e
                return res.send(400, e)
            res.send(200, instance)

show = (req, res) ->
    Model = Invisible[req.params.modelName]

    try
        Model.findById req.params.id, (e, result) ->
            if result?
                checkAuth req, res, result, "allowFind", ()->
                    obj = JSON.parse(JSON.stringify(result))
                    res.send(200, obj)
            else
                res.send(404)
    catch e
        res.send(500, e)

update = (req, res) ->
    Model = Invisible[req.params.modelName]

    Model.findById req.params.id, (error, instance) ->
        if instance?
            checkAuth req, res, instance, "allowUpdate", ()->
                _.extend(instance, req.body)
                instance.save (e, instance) ->
                    if e
                        return res.send(400, e)
                    res.send(200, instance)
        else
            res.send(404)

remove = (req, res) ->
    Model = Invisible[req.params.modelName]

    Model.findById req.params.id, (e, instance) ->
        if instance?
            checkAuth req, res, instance, "allowDelete", ()->
                instance.delete (e, result) ->
                    res.send(200)
        else
            res.send(404)

_ = require("underscore")
Invisible = require('./invisible')

module.exports = (app) ->
	app.get("/invisible/:modelName", query)
	app.post("/invisible/:modelName", save)
	app.get("/invisible/:modelName/:id", show)
	app.put("/invisible/:modelName/:id", update)
	app.delete("/invisible/:modelName/:id", remove)

#rest controllers
query = (req, res) -> 
    #TODO error handling
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
    instance.save (e, instance) ->
        res.send(200, instance)

show = (req, res) ->
    #TODO error handling
    Model = Invisible[req.params.modelName]
    
    Model.findById req.params.id, (e, result) ->
        if result?
            obj = JSON.parse(JSON.stringify(result))
            res.send(200, obj)
        else
            res.send(404)

update = (req, res) ->
    Model = Invisible[req.params.modelName]
    
    Model.findById req.params.id, (error, instance) ->
        try
            if instance?
                _.extend(instance, req.body)
                instance.save (e, instance) ->
                    res.send(200, instance)
            else
                res.send(404)
        catch e
            res.send(500, e)

remove = (req, res) ->
    Model = Invisible[req.params.modelName]

    Model.findById req.params.id, (e, instance) ->
        if instance?
            instance.delete (e, result) ->
                res.send(200)
        else
            res.send(404)

# mquery = require('mquery')
mongo = require('mongodb')
ObjectID = require('mongodb').ObjectID
Invisible = require('invisible')

db = undefined

uri = 'mongodb://127.0.0.1:27017/invisible'

mongo.connect uri, (err, database) ->
    throw err if err?
    db = database
    console.log("connected to #{uri}")


module.exports = (app) ->
	app.get("/invisible/:modelName", query)
	app.post("/invisible/:modelName", save)
	app.get("/invisible/:modelName/:id", show)
	app.put("/invisible/:modelName/:id", update)
	app.delete("/invisible/:modelName/:id", remove)

#rest controllers
query = (req, res) -> 
    col = db.collection(req.params.modelName)
    col.find().toArray (err, results) ->
        return next(err) if err?
        res.send(results)

save = (req, res) ->
    res.send({id: 1, firstName: "John"})

show = (req, res) ->
    col = db.collection(req.params.modelName)
    col.findOne {_id: new ObjectID(req.params.id)}, (err, result, a) ->
        return next(err) if err?
        res.send(result)

update = (req, res) ->
    res.send({id: req.params.id, firstName: "Greg"})

remove = (req, res) ->
    res.send("delete model: #{req.params.modelName} id: #{req.params.id}")

mongo = require('mongodb')
ObjectID = mongo.ObjectID

uri = 'mongodb://127.0.0.1:27017/invisible'
db = undefined

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
    if req.query.query?
        criteria = JSON.parse(req.query.query)
    else
        criteria = {}
        
    col.find(criteria).toArray (err, results) ->
        return next(err) if err?
        res.send(results)

save = (req, res) ->
    col = db.collection(req.params.modelName)
    col.insert req.body, safe:true, (err, result) ->
        return next(err) if err?
        res.send(200, result[0])

show = (req, res) ->
    col = db.collection(req.params.modelName)

    try
        id = new ObjectID(req.params.id)
    catch err
        console.log('Invalid Object Id')
        res.send(404)

    col.findOne {_id: new ObjectID(req.params.id)}, (err, result) ->
        return next(err) if err?
        if result?
            res.send(200, result)
        else
            res.send(404)

update = (req, res) ->
    col = db.collection(req.params.modelName)

    try
        id = new ObjectID(req.params.id)
    catch err
        console.log('Invalid Object Id')
        res.send(404)

    col.findAndModify { _id: id}, [['_id','asc']], {$set: req.body}, {new: true, upsert: false}, (err, result) ->
        return next(err) if err?
        if result
            res.send(200, result)
        else
            res.send(404)

remove = (req, res) ->
    col = db.collection(req.params.modelName)

    try
        id = new ObjectID(req.params.id)
    catch err
        console.log('Invalid Object Id')
        res.send(404)

    col.remove { _id: id}, (err, result) ->
        return next(err) if err?
        if result?
            res.send(200)
        else
            res.send(404)

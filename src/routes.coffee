
module.exports = (app) ->
	app.get("/models/:modelName", get_list)
	app.post("/models/:modelName", post_list)

	app.get("/models/:modelName/:id", get_detail)
	app.put("/models/:modelName/:id", put_detail)
	app.delete("/models/:modelName/:id", delete_detail)

#rest controllers
get_list = (req, res) -> 
    res.send("get list of model: #{req.params.modelName}")

post_list = (req, res) ->
    res.send({res: "everything coll"})

get_detail = (req, res) ->
    res.send("get detail of model: #{req.params.modelName} id: #{req.params.id}")

put_detail = (req, res) ->
    res.send("update model: #{req.params.modelName} id: #{req.params.id}")

delete_detail = (req, res) ->
    res.send("delete model: #{req.params.modelName} id: #{req.params.id}")

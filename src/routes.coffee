
module.exports = (app, path='') ->
    #FIXME save path in invisible or wipe away
	app.get("#{path}/:modelName", get_list)
	app.post("#{path}/:modelName", post_list)

	app.get("#{path}/:modelName/:id", get_detail)
	app.put("#{path}/:modelName/:id", put_detail)
	app.delete("/#{path}:modelName/:id", delete_detail)

#rest controllers
get_list = (req, res) -> 
    res.contentType('text/plain')
    res.send("get list of model: #{req.params.modelName}")

post_list = (req, res) ->
    res.contentType('text/plain')
    res.send("post list of model: #{req.params.modelName}")

get_detail = (req, res) ->
    res.contentType('text/plain')
    res.send("get detail of model: #{req.params.modelName} id: #{req.params.id}")

put_detail = (req, res) ->
    res.contentType('text/plain')
    res.send("update model: #{req.params.modelName} id: #{req.params.id}")

delete_detail = (req, res) ->
    res.contentType('text/plain')
    res.send("delete model: #{req.params.modelName} id: #{req.params.id}")


module.exports = Invisible = {}

Invisible.isClient = () -> window?

if Invisible.isClient()
    window.Invisible = Invisible
else
    Invisible.createServer = (app, rootFolder, config, cb) ->

        if typeof(config) == "function"
            cb = config
            config = undefined

        require('./config').customize(config)

        Invisible.server = require('http').createServer(app).listen app.get("port"), () ->
            cb() if cb?

        app.use(require('./bundle')(rootFolder))
        require('./routes')(app)

        return Invisible.server

Invisible.createModel = (modelName, InvisibleModel) ->

    InvisibleModel.modelName = modelName

    require('./model/common')(InvisibleModel)
    require('./model/socket')(InvisibleModel)

    addCrudOperations = if Invisible.isClient() then require('./model/client') else require('./model/server')
    addCrudOperations(InvisibleModel)

    Invisible[modelName] = InvisibleModel
    return InvisibleModel

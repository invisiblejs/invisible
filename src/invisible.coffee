
module.exports = Invisible = {}

Invisible.isClient = () -> window?

if Invisible.isClient()
    window.Invisible = Invisible
    Invisible.login = (username, password) ->
        window.sessionStorage.InvisibleUsername = username
        window.sessionStorage.InvisiblePassword = password
        Invisible.headers = {InvisibleUsername: username, InvisiblePassword: password}
        return

    Invisible.headers = {InvisibleUsername: window.sessionStorage.InvisibleUsername, InvisiblePassword: window.sessionStorage.InvisiblePassword}
else
    Invisible.createServer = (app, rootFolder, config, cb) ->

        if typeof(config) == "function"
            cb = config
            config = undefined

        require('./config').customize(config)

        Invisible.server = require('http').createServer(app).listen app.get("port"), () ->
            cb() if cb?

        app.use(require('./bundle')(rootFolder))
        app.use(require('./auth'))
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

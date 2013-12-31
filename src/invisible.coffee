
utils = require('./utils')
module.exports = Invisible = {}

Invisible.isClient = () -> window?

if Invisible.isClient()
    window.Invisible = Invisible
    Invisible.login = (username, password, cb) ->
        http = require("http")

        setToken = (err, data)->
            Invisible.headers.InvisibleAuthToken = data.token
            cb()

        http.request(
                path: "/invisible/authtoken/" 
                method: "GET", 
                headers:
                    InvisibleUsername: username
                    InvisiblePassword: password 
                utils.handleResponse(setToken)).end()


    Invisible.logout = () ->
        Invisible.headers = {}
        delete window.sessionStorage.InvisibleAuthToken

    if window.sessionStorage.InvisibleAuthToken
        Invisible.headers.InvisibleAuthToken = window.sessionStorage.InvisibleAuthToken
    else
        Invisible.headers = {}

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

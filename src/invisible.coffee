
utils = require('./utils')
module.exports = Invisible = {}

Invisible.isClient = () -> window?

if Invisible.isClient()
    window.Invisible = Invisible
    Invisible.login = (username, password, cb) ->
        http = require("http")

        setToken = (err, data)->
            t = new Date()
            data['expires_in'] = t.setSeconds(t.getSeconds() + data.expires_in)
            Invisible.AuthToken = data
            cb()

        req = http.request(
                path: "/invisible/authtoken/" 
                method: "POST", 
                utils.handleResponse(setToken))

        req.write JSON.stringify
            grant_type: "password"
            username: username
            password: password

        req.end()


    Invisible.logout = () ->
        Invisible.AuthToken = {}
        delete window.sessionStorage.InvisibleAuthToken

    if window.sessionStorage.InvisibleAuthToken
        Invisible.AuthToken = window.sessionStorage.InvisibleAuthToken
    else
        Invisible.AuthToken = {}

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

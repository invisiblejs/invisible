
module.exports = Invisible = {}

Invisible.isClient = () -> window?

Invisible.createModel = (modelName, Model) ->
    console.log('Creating a Invisible Model: ' + modelName)

    if Invisible.isClient()
        InvisibleModel = require('./client_model')(modelName, Model)
    else
        InvisibleModel = require('./server_model')(modelName, Model)

    this[modelName] = InvisibleModel
    return InvisibleModel

if Invisible.isClient()
    window.Invisible = Invisible
else
    Invisible.server = (app, rootFolder) ->
        app.use(require('./bundle')(rootFolder))
        require('./routes')(app)

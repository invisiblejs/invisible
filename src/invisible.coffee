
module.exports = Invisible = {}

Invisible.isClient = () -> window?

Invisible.createModel = (modelName, Model, validations) ->
    if not validations?
        validations = {}

    if Invisible.isClient()
        InvisibleModel = require('./client_model')(modelName, Model, validations)
    else
        InvisibleModel = require('./server_model')(modelName, Model, validations)

    this[modelName] = InvisibleModel
    return InvisibleModel

if Invisible.isClient()
    window.Invisible = Invisible
else
    Invisible.server = (app, rootFolder) ->
        app.use(require('./bundle')(rootFolder))
        require('./routes')(app)

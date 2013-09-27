revalidator = require("revalidator")
io_client = require('socket.io-client')
module.exports = Invisible = {}

Invisible.isClient = () -> window?

Invisible.createModel = (modelName, Model) ->

    class InvisibleModel extends Model
        _modelName: modelName
        @_modelName: modelName #FIXME ugly
        @socket = io_client.connect("http://localhost:3001/#{modelName}")

        validate: ()->
            validations = @validations or {}
            revalidator.validate(this, validations)

        
    if Invisible.isClient()
        require('./client_model')(InvisibleModel)
    else
        InvisibleModel.serverSocket = io.of("/#{modelName}")
        InvisibleModel.serverSocket.on 'connection', (socket) ->
            return

        require('./server_model')(InvisibleModel)

    this[modelName] = InvisibleModel
    return InvisibleModel

if Invisible.isClient()
    window.Invisible = Invisible
else
    io = require('socket.io').listen(3001)
    Invisible.server = (app, rootFolder) ->
        app.use(require('./bundle')(rootFolder))
        require('./routes')(app)

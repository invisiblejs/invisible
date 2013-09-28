io_client = require('socket.io-client')
_ = require("underscore")
module.exports = Invisible = {}

Invisible.isClient = () -> window?

Invisible.createModel = (modelName, Model) ->

    class InvisibleModel extends Model
        @modelName: modelName
        @socket = io_client.connect("http://localhost:3001/#{modelName}")

    InvisibleModel.onNew = (cb) ->
        InvisibleModel.socket.on 'new', (data) ->
            model = new InvisibleModel()
            _.extend(model, data)
            cb(model)

    InvisibleModel.onUpdate = (cb) ->
        InvisibleModel.socket.on 'update', (data) ->
            model = new InvisibleModel()
            _.extend(model, data)
            cb(model)

    InvisibleModel.onDelete = (cb) ->
        InvisibleModel.socket.on 'delete', (data) ->
            model = new InvisibleModel()
            _.extend(model, data)
            cb(model)

    require('./model/common')(InvisibleModel)

    if Invisible.isClient()
        require('./model/client')(InvisibleModel)
    else
        InvisibleModel.serverSocket = io.of("/#{modelName}")
        InvisibleModel.serverSocket.on 'connection', (socket) ->
            return
        require('./model/server')(InvisibleModel)

    this[modelName] = InvisibleModel
    return InvisibleModel

if Invisible.isClient()
    window.Invisible = Invisible
else
    io = require('socket.io').listen(3001)
    io.set('log level', 1)
    Invisible.server = (app, rootFolder) ->
        app.use(require('./bundle')(rootFolder))
        require('./routes')(app)

browserify = require('browserify')
path = require('path')
fs = require('fs')
coffeeify = require('coffeeify')

module.exports = (rootFolder, opt) ->

    src = undefined

    b = browserify()
    b.ignore('mongodb')
    b.ignore('./bundle')
    b.ignore('./routes')
    b.ignore('./config')
    b.ignore('./auth')
    b.ignore('socket.io')


    # walk through model files
    modelFiles = fs.readdirSync(rootFolder)
    for modelName in modelFiles
        modelFile = path.join(rootFolder, modelName)
        b.add(modelFile)
        #Require all bundled models so they can be accesed in the server
        require(modelFile)

    # Support for CoffeeScript
    b.transform(coffeeify)

    # create bundle (invisible.js)
    b.bundle (err, compiled) ->
        throw err if err?
        src = compiled
        console.log('Invisible: Created bundle')

    # Express middleware, serve invisible.js
    return (req, res, next) ->

        if req.path != '/invisible.js'
            return next()

        res.contentType('application/javascript')
        res.send(src)

browserify = require('browserify')
path = require('path')
fs = require('fs')
coffeeify = require('coffeeify')

module.exports = (rootFolder, opt) ->

    src = undefined

    b = browserify()
    b.ignore 'mongodb'


    # walk through model files
    modelFiles = fs.readdirSync(rootFolder)
    for modelFile in modelFiles
        console.log(modelFile)
        b.add(path.join(rootFolder, modelFile))
        #Require all bundled models so they can be accesed in the server
        require(path.join(rootFolder, modelFile))

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

        console.log('Invisible: serve bundle')
        res.contentType('application/javascript')
        res.send(src)

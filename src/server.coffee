browserify = require('browserify')
path = require('path')
fs = require('fs')

module.exports = (rootFolder, opt) ->

    src = undefined

    b = browserify()

    # walk through model files
    modelFiles = fs.readdirSync(rootFolder)
    for modelFile in modelFiles
        console.log(modelFile)
        b.add(path.join(rootFolder, modelFile))

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

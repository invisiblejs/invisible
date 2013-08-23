
isClient = () ->
    window?

Invisible = 
    _conf: {}

    createModel: (modelName, Model) ->
        console.log('Creating a Invisible Model: ' + modelName)
        
        if isClient()
            InvisibleModel = require('./clientmodel')(modelName, Model)
        else
            InvisibleModel = require('./servermodel')(modelName, Model)

        this[modelName] = InvisibleModel
        return InvisibleModel

if isClient()
    console.log('client')
    window.Invisible = Invisible
else
    console.log('server')

module.exports = Invisible

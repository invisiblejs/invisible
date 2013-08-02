Invisible = {}

Invisible.createModel = (modelName, Model) ->
    console.log('Creating a Invisible Model: ' + modelName)
    this[modelName] = Model
    return Model

if window?
    console.log('client')
    window.Invisible = Invisible
else
    console.log('server')

module.exports = Invisible


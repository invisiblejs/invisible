
module.exports = {
    db_uri : 'mongodb://127.0.0.1:27017/invisible'
}

module.exports.customize = (newConfig) ->
    config = module.exports

    for k,v of newConfig
        config[k] = v

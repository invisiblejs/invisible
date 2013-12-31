mongo = require('mongodb')
config = require('./config')
Invisible = require('./invisible')
crypto = require('crypto')

col = undefined
mongo.connect config.db_uri, (err, database) ->
    throw err if err?
    col = database.collection('AuthToken')
    
createToken = (req, res) ->
    #FIXME use oauth conventions instead of custom header
    username = req.header('InvisibleUsername')
    password = req.header('InvisiblePassword')
    if !username or !password
        return res.send(401)

    config.authenticate username, password, (err, user) ->
        if err or not user
            return res.send(401)

        crypto.randomBytes 48, (ex, buf)->
            token = buf.toString('hex')
            
            #TODO add expiry and refresh token
            data = 
                token: token
                user: user._id

            col.save data, (err, result)->
                if not err
                    return res.send(200, token: token)

                return res.send(401)


module.exports = (req, res, next) ->

    if not config.authenticate
        return next()

    if req.path.indexOf('/invisible/authtoken/') == 0
        # exchange credentials per token
        return createToken(req, res)

    #FIXME use oauth conventions instead of custom header
    token = req.header('InvisibleAuthToken')
    if not token
        return res.send(401)

    
    col.findOne {token: token}, (err, token) ->
        if err
            return res.send(401)
        
        Invisible[config.userModel or 'User'].findById token.user.toString(), (err, user)->
            if err
                return res.send(401)

            req.user = user
            next()

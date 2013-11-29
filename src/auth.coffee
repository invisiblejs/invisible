config = require('./config')
Invisible = require('./invisible')

module.exports = (req, res, next) ->

        if not config.authenticate
            return next()

        username = req.header('InvisibleUsername')
        password = req.header('InvisiblePassword')
        if !username or !password
            res.send(401)

        config.authenticate username, password, (err, success) ->
            if err then return next(err)
            if success
                req.user = success
                next()
            else
                res.send(401)
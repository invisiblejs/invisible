http = require("http")
_ = require("underscore")
Invisible = require('../invisible')
utils = require('../utils')


authRequest = (opts, payload, cb)->
    ###
    Sends a request that includes the required auth header. Uses the 
    AuthToken if present, and refreshes it if necessary. If no AuthToken is 
    present, it does not include authorization headers.
    An optional payload is written to the request if present.
    ###

    if not cb
        cb = payload
        payload = undefined

    Token = Invisible.AuthToken

    sendRequest = ()->
        if Token and Token.access_token
            #build auth header
            opts.headers = opts.headers or {}
            opts.headers['Authorization'] = 'Bearer ' + Token.access_token

        req = http.request(opts, cb)
        if payload
            req.write(payload)
        req.end()

    #Check if token refresh required
    if Token and Token.expires_in and new Date() > Token.expires_in
        
        setToken = (err, data)->
            t = new Date()
            data['expires_in'] = t.setSeconds(t.getSeconds() + data.expires_in)
            Invisible.AuthToken = Token = data
            sendRequest()

        req = http.request(
                path: "/invisible/authtoken/" 
                method: "POST", 
                utils.handleResponse(setToken))

        req.write JSON.stringify
            grant_type: "refresh_token"
            refresh_token: Token.refresh_token
        
        req.end()

    else
        sendRequest()


module.exports = (InvisibleModel) ->

    InvisibleModel.findById = (id, cb) -> 
        processData = (err, data) ->
            if err
                return cb(err)
            model = _.extend(new InvisibleModel(), data)
            cb(null, model)

        authRequest(
                {path: "/invisible/#{InvisibleModel.modelName}/#{id}/", method: "GET"}, 
                utils.handleResponse(processData))

    InvisibleModel.query = (query, opts, cb) -> 

        #handle optional arg
        if not cb?
            if not opts?
                cb = query
                query = {}
            else
                cb = opts
            opts = {}
        
        qs = ("?query=" + encodeURIComponent(JSON.stringify(query)) +
            "&opts=" + encodeURIComponent(JSON.stringify(opts)))

        processData = (err, data) ->
            if err
                return cb(err)
            models = (_.extend(new InvisibleModel(), d) for d in data)
            cb(null, models)
        
        authRequest(
                {path: "/invisible/#{InvisibleModel.modelName}/#{qs}", method: "GET"}, 
                utils.handleResponse(processData))

    InvisibleModel::save = (cb) -> 
        model = this

        update = (err, data) ->
            if err and cb
                return cb(err)
            
            _.extend(model, data)
            if cb?
                cb(null, model)
        
        @validate (result) ->
            if not result.valid
                return cb(result.errors)

            headers = 
                'content-type': "application/json"

            if model._id?
                authRequest(
                    {path: "/invisible/#{InvisibleModel.modelName}/#{model._id}/", method: "PUT",
                    headers: headers}, JSON.stringify(model),
                    utils.handleResponse(update))
            
            else
                authRequest(
                    {path: "/invisible/#{InvisibleModel.modelName}/", method: "POST", 
                    headers: headers}, JSON.stringify(model),
                    utils.handleResponse(update))
            
    InvisibleModel::delete = (cb)-> 
        if @_id?
            model = this
            
            _cb = (err, res) ->
                if cb
                    if err
                        return cb(err)

                    cb(null, model)

            authRequest({path: "/invisible/#{InvisibleModel.modelName}/#{@_id}/", method: "DELETE"}, 
                _cb)
        return

    return InvisibleModel
http = require("http")
_ = require("underscore")
Invisible = require('../invisible')
utils = require('../utils')


authRequest = (opts, cb)->
    ###
    Returns a request that includes the required auth hedaer. Uses the 
    AuthToken if present, and refreshes it if necessary. If no AuthToken is 
    present, it does not include authorization headers.
    ###

    if opts.AuthToken and opts.AuthToken.access_token
        #build auth header
        opts.headers = opts.headers or {}

        if opts.AuthToken.expires_in and new Date() > opts.AuthToken.expires_in
            #TODO refresh token
            return

        opts.headers['Authorization'] = 'Bearer ' + opts.AuthToken.access_token

    return http.request(opts, cb)


module.exports = (InvisibleModel) ->

    InvisibleModel.findById = (id, cb) -> 
        processData = (err, data) ->
            if err
                return cb(err)
            model = _.extend(new InvisibleModel(), data)
            cb(null, model)

        authRequest(
                {path: "/invisible/#{InvisibleModel.modelName}/#{id}/", method: "GET"}, 
                utils.handleResponse(processData)).end()

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
                utils.handleResponse(processData)).end()

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
                req = authRequest(
                    {path: "/invisible/#{InvisibleModel.modelName}/#{model._id}/", method: "PUT",
                    headers: headers}, 
                    utils.handleResponse(update))
            
            else
                req = authRequest(
                    {path: "/invisible/#{InvisibleModel.modelName}/", method: "POST", 
                    headers: headers}, 
                    utils.handleResponse(update))
            
            req.write(JSON.stringify(model))
            req.end()
    
    InvisibleModel::delete = (cb)-> 
        if @_id?
            model = this
            
            _cb = (err, res) ->
                if cb
                    if err
                        return cb(err)

                    cb(null, model)

            authRequest({path: "/invisible/#{InvisibleModel.modelName}/#{@_id}/", method: "DELETE"}, 
                _cb).end()
        return

    return InvisibleModel
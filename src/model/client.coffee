http = require("http")
_ = require("underscore")
Invisible = require('../invisible')

handleResponse = (cb) ->
    ###
    Collects the response body, parses it as JSON and passes it to the callback.
    ###
    return (res) ->
        fullBody = ''
        res.on 'data', (chunk) -> 
            fullBody += chunk
        res.on 'end', () ->
            if res.statusCode != 200
                return cb(new Error("Error"))

            data = JSON.parse(fullBody)
            cb(null, data)

module.exports = (InvisibleModel) ->

    InvisibleModel.findById = (id, cb) -> 
        processData = (err, data) ->
            if err
                return cb(err)
            model = _.extend(new InvisibleModel(), data)
            cb(null, model)

        http.request(
                {path: "/invisible/#{InvisibleModel.modelName}/#{id}/", method: "GET", headers: Invisible.headers}, 
                handleResponse(processData)).end()

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
        
        http.request(
                {path: "/invisible/#{InvisibleModel.modelName}/#{qs}", method: "GET", headers: Invisible.headers}, 
                handleResponse(processData)).end()

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

            headers = Invisible.headers
            headers['content-type'] = "application/json"

            if model._id?
                req = http.request(
                    {path: "/invisible/#{InvisibleModel.modelName}/#{model._id}/", method: "PUT",
                    headers: headers}, 
                    handleResponse(update))
            
            else
                req = http.request(
                    {path: "/invisible/#{InvisibleModel.modelName}/", method: "POST", 
                    headers: headers}, 
                    handleResponse(update))
            
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

            http.request({path: "/invisible/#{InvisibleModel.modelName}/#{@_id}/", method: "DELETE", headers: Invisible.headers}, 
                _cb).end()
        return

    return InvisibleModel
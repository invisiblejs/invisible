http = require("http")
_ = require("underscore")
revalidator = require("revalidator")

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
                return cb(new Error("Bad request"))

            data = JSON.parse(fullBody)
            cb(null, data)


module.exports = (modelName, BaseModel, validations) ->
    class InvisibleModel extends BaseModel
            #TODO factor out repeated lines
            _modelName: modelName
            @_modelName: modelName #FIXME ugly
            
            _validations: validations

            validate: ()->
                revalidator.validate(this, @_validations)

            @findById: (id, cb) -> 
                processData = (err, data) ->
                    if err
                        return cb(err)
                    model = _.extend(new InvisibleModel(), data)
                    cb(null, model)

                http.request(
                        {path: "/invisible/#{@_modelName}/#{id}/", method: "GET"}, 
                        handleResponse(processData)).end()

            @query: (query, opts, cb) -> 
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
                        {path: "/invisible/#{@_modelName}/#{qs}", method: "GET"}, 
                        handleResponse(processData)).end()

            save: (cb) -> 
                model = this
                
                update = (err, data) ->
                    if err and cb
                        return cb(err)
                    
                    _.extend(model, data)
                    if cb?
                        cb(null, model)

                if @_id?
                    req = http.request(
                        {path: "/invisible/#{@_modelName}/#{@_id}/", method: "PUT",
                        headers: { 'content-type': "application/json" }}, 
                        handleResponse(update))
                
                else
                    req = http.request(
                        {path: "/invisible/#{@_modelName}/", method: "POST", 
                        headers: { 'content-type': "application/json" }}, 
                        handleResponse(update))
                
                req.write(JSON.stringify(this))
                req.end()
                return
            
            delete: (cb)-> 
                if @_id?
                    model = this
                    
                    _cb = (err, res) ->
                        if cb
                            if err
                                return cb(err)

                            cb(null, model)

                    http.request({path: "/invisible/#{@_modelName}/#{@_id}/", method: "DELETE"}, 
                        _cb).end()
                return

    return InvisibleModel
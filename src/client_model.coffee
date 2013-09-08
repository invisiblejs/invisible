http = require("http")
_ = require("underscore")

handleResponse = (cb) ->
    ###
    Collects the response body, parses it as JSON and passes it to the callback.
    ###
    return (res) ->
        fullBody = ''
        res.on 'data', (chunk) -> 
            fullBody += chunk
        res.on 'end', () ->
            data = JSON.parse(fullBody)
            cb(data)


module.exports = (modelName, BaseModel) ->
    class InvisibleModel extends BaseModel
            _modelName: modelName
            @_modelName: modelName #FIXME ugly
            
            #FIXME handle errors
            @findById: (id, cb) -> 
                processData = (data) ->
                    model = _.extend(new InvisibleModel(), data)
                    cb(null, model)

                http.request(
                        {path: "/invisible/#{@_modelName}/#{id}/", method: "GET"}, 
                        handleResponse(processData)).end()

            #FIXME add query
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

                processData = (data) ->
                    models = (_.extend(new InvisibleModel(), d) for d in data)
                    cb(null, models)
                
                http.request(
                        {path: "/invisible/#{@_modelName}/#{qs}", method: "GET"}, 
                        handleResponse(processData)).end()

            save: (cb) -> 
                model = this
                
                update = (data) ->
                    _.extend(model, data)
                    if cb?
                        cb(null, model)

                #FIXME handle errors
                if @_id?
                    req = http.request(
                        {path: "/invisible/#{@_modelName}/#{@_id}/", method: "PUT",
                        headers: { 'content-type': "application/json" }}, 
                        handleResponse(update))
                
                #FIXME handle errors
                else
                    req = http.request(
                        {path: "/invisible/#{@_modelName}/", method: "POST", 
                        headers: { 'content-type': "application/json" }}, 
                        handleResponse(update))
                
                req.write(JSON.stringify(this))
                req.end()
                return
            
            #FIXME handle errors
            delete: (cb)-> 
                if @_id?
                    model = this
                    
                    _cb = (err, res) ->
                        #TODO handle error
                        if cb?
                            cb(null, model)

                    http.request({path: "/invisible/#{@_modelName}/#{@_id}/", method: "DELETE"}, 
                        _cb).end()
                return

    return InvisibleModel
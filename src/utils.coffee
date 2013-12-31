module.exports = 
    handleResponse: (cb) ->
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
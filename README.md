# Invisible.js ![image](https://david-dm.org/sammla/invisible.png)

Invisible is a JavaScript (and CoffeeScript!) library that leverages 
[browserify](https://github.com/substack/node-browserify) to achieve the Holy Grail of web programming: 
model reuse in the client and the server.

## Usage

First wire up Invisible middleware and REST routes:



To make your models available everywhere, define them and call `Invisible.createModel`

```
Invisible = require("invisible")
crypto = require("crypto")
_s = require("underscore.string")

class Person
    constructor: (@firstName, @lastName, @email) ->
    
    fullName: () -> "#{@firstName} #{@lastName}"

    getAvatarUrl: () ->
        cleanMail = _s.trim(@email).toLowerCase()
        hash = crypto.createHash("md5").update(cleanMail).digest("hex")
        return "http://www.gravatar.com/avatar/" + hash

module.exports = Invisible.createModel("Person", Person)
```

Require your models as usual in the server:

In the client, just add the invisible script and your models will be available under the Invisible 
namespace:


Invisible extends your models to handle your MongoDB persistence, no matter if you are at the client or 
the server:

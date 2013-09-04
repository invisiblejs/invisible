# Invisible.js [![Build Status](https://secure.travis-ci.org/sammla/invisible.png)](http://travis-ci.org/sammla/invisible) ![image](https://david-dm.org/sammla/invisible.png)

Invisible is a JavaScript (and CoffeeScript!) library that leverages 
[browserify](https://github.com/substack/node-browserify) to achieve the Holy Grail of web programming: 
model reuse in the client and the server.

## Usage

First wire up Invisible into your app:

```javascript
express = require("express");
path = require("path");
invisible = require("invisible");

app = express();
invisible.server(app, path.join(__dirname, "models"))
```

To make your models available everywhere, define them and call `Invisible.createModel`

```javascript
Invisible = require("invisible");
crypto = require("crypto");
_s = require("underscore.string");

function Person(firstName, lastName, email){
    this.firstName = firstName;
    this.lastName = lastName;
    this.email = email;
}

Person.prototype.fullName = function(){
    return this.firstName + ' ' + this.lastName;
}

Person.prototype.getAvatarUrl = function(){
    cleanMail = _s.trim(this.email).toLowerCase();
    hash = crypto.createHash("md5").update(cleanMail).digest("hex");
    return "http://www.gravatar.com/avatar/" + hash;
}

module.exports = Invisible.createModel("Person", Person);
```

Require your models as usual in the server:

```javascript
Person = require("./models/person");
john = new Person("John", "Doe", "john.doe@mail.com");
john.fullName(); //John Doe
```

In the client, just add the invisible script and your models will be available under the Invisible 
namespace:

```html
<script src="invisible.js"></script>
<script>
    jane = new Invisible.Person("Jane", "Doe", "jane.doe@mail.com");
    alert(jane.fullName()); //Jane Doe
</script>
```


Invisible extends your models to handle your MongoDB persistence, no matter if you are at the client or 
the server:

```javascript
jane.save();
Invisible.Person.query({firstName: "Jane"}, function(results){
    console.log(results[0].fullName()); //Jane Doe
});
```

# Invisible.js [![Build Status](https://secure.travis-ci.org/sammla/invisible.png)](http://travis-ci.org/sammla/invisible) [![Dependencies](https://david-dm.org/sammla/invisible.png)](https://david-dm.org/sammla/invisible)

Invisible is a JavaScript (and CoffeeScript!) library that leverages 
[browserify](https://github.com/substack/node-browserify) to achieve the Holy Grail of web programming: 
model reuse in the client and the server.

## Installation and setup

Install with npm:
```
npm install invisible
```

Wire up Invisible into your [express](http://expressjs.com/) app:
```javascript
express = require("express");
path = require("path");
invisible = require("invisible");

app = express();
invisible.server(app, path.join(__dirname, "models"))
```

## Extending models

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

Invisible.js uses [browserify](https://github.com/substack/node-browserify) to expose you server defined 
models in the browser, so you can use any broserify-able library to implement them. Note that this
integration is seamless, no need to build a bundle, Invisible.js does that for you on the fly.

## REST and MongoDB integration

In addition to making your models available everywhere, Invisible extends them with methods to handle 
persistence. In the server this means interacting with MongoDB and in the client making requests to an
auto-generated REST API, that subsequently performs the same DB action.

### Save
```javascript
jane.save(function(err, result){
    if (err){
        console.log("something went wrong");
    } else {
        console.log("Jane's id is " + jane._id);
        console.log("which equals " + result._id);
    }
})
```
The first time the save method is called, it creates the model in the database and sets its `_id` attribute. 
Subsequent calls update the model. Validations are called upon saving, see the validations section for details.

Note that a full Invisible model instance is passed to the callback, and the calling instance is also updated
when the process is done.

### Delete
```javascript
jane.delete(function(err, result){
    if (err){
        console.log("something went wrong");
    } else {
        console.log("Jane is no more.");
    }
})
```
### Query

```javascript
Invisible.Person.query(function(err, results){
    if (err){
        console.log("something went wrong");
    } else {
        console.log("Saved persons are:");
        for (var i = 0; i < results.length; i++){
            console.log(results[i].fullName());
        }
    }
});

Invisible.Person.query({firstName: "Jane"}, function(err, results){
    if (err){
        console.log("something went wrong");
    } else {
        console.log("Persons named Jane are:");
        for (var i = 0; i < results.length; i++){
            console.log(results[i].fullName());
        }
    }
});

Invisible.Person.query({}, {sort: "lastName", limit: 10}, function(err, results){
    if (err){
        console.log("something went wrong");
    } else {
        console.log("First 10 persons are:");
        for (var i = 0; i < results.length; i++){
            console.log(results[i].fullName());
        }
    }
});
```

Queries the database for existent models. The first two optional arguments correspond to the 
[Query object](http://mongodb.github.io/node-mongodb-native/markdown-docs/queries.html#query-object) 
and [Query options](http://mongodb.github.io/node-mongodb-native/markdown-docs/queries.html#query-options) 
in the MongoDB Node.JS driver. The one difference is that when using ids you can pass strings, 
that will be converted to ObjectID when necessary. 

### Find by id
```javascript
Invisible.Person.findById(jane._id, function(err, model){
    if (err){
        console.log("something went wrong");
    } else {
        console.log("Jane's name is " + model.firstName);
        console.log("But we knew that!");
    }
})
```

Looks into the database for a model with the specified `_id` value. As in the query method, you can pass
a string id instead of an ObjectID instance.

## Validations

TODO: explain revalidator integration

TODO: explain custom validation metthods

## Real time events

TODO: explain socket.io integration and avaiable methods

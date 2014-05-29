# [Invisible.js](http://invisiblejs.github.io) [![Build Status](https://secure.travis-ci.org/invisiblejs/invisible.png)](http://travis-ci.org/invisiblejs/invisible) [![Dependencies](https://david-dm.org/invisiblejs/invisible.png)](https://david-dm.org/invisiblejs/invisible)

Invisible is a JavaScript library that leverages 
[browserify](https://github.com/substack/node-browserify) to achieve the Holy Grail of web programming: 
model reuse in the client and the server.

## Installation and setup

Install with npm:
```
npm install invisible
```

Wire up Invisible into your [express](http://expressjs.com/) (Works only with Express 4.x) app:
```javascript
var express = require("express");
var path = require("path");
var invisible = require("invisible");

var app = express();

app.use(invisible.router({
  rootFolder: path.join(__dirname, 'models')
}));

var server = app.listen(3000);
```

## Extending models

To make your models available everywhere, define them and call `Invisible.createModel`.

```javascript
// models/person.js
var Invisible = require("invisible");
var crypto = require("crypto");
var _s = require("underscore.string");

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

Now your models will be available under the Invisible namespace. Require as usual in the server:

```javascript
var Invisible = require("invisible")
var john = new Invisible.models.Person("John", "Doe", "john.doe@mail.com");
john.fullName(); //John Doe
```

In the client, just add the invisible script:

```html
<script src="invisible.js"></script>
<script>
    var jane = new Invisible.models.Person("Jane", "Doe", "jane.doe@mail.com");
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

Invisible.js integrates with [revalidator](https://github.com/flatiron/revalidator) to handle model validations. 
A `validate` method is added to each model which looks for a defined validation schema, and is executed each time 
a model is saved, both in the client and the server. For example:

```javascript
function Person(email){
    this.email = email;
}

Person.prototype.validations = {
    properties: {
        email: {
            format: 'email',
            required: true
        }
    }
}

var john = new Person("john.doe@none.com");
john.save(function(err, result){
    console.log("All OK here.");
});

john.email = "invalid";
john.save(function(err, result){
    console.log(err); 
    /* Prints: {valid: false, errors: [{attribute: 'format', 
        property: 'email', message: 'is not a valid email'}]} */
})
```

Invisible.js also introduces "method" validations, which allow you to specify a method which should be called
in the validation process. This way asynchronic validations, such as querying the database, can be performed:

```javascript
Person.prototype.validations = {
    methods: ['checkUnique']
}

Person.prototype.checkUnique = function(cb) {
    Invisible.Person.query({email: this.email}, function(err, res){
        if (res.length > 0){
            cb({valid: false, errors: ["email already registered"]});
        } else {
            cb({valid: true, errors: []});
        }
    });
}
```

The custom validation method takes a callback and should call it with the return format of revalidator: an object
with a "valid" boolean field and an "errors" list. Note that the method validations are only called if the 
properties validations succeed, and stop the validation process upon the first failure.

## Real time events

Invisible.js uses [socket.io](http://socket.io/) to emmit an event whenever something changes for a model, and lets you add listener 
functions to react to those changes in realtime.

To add realtime features:
```javascript
var server = app.listen(3000);
invisible.addRealtime(server);
```javascript

And then in yuor code:
```javascript
Invisible.Person.onNew(function(model){
    console.log(model.fullName() + " has been created");
});

Invisible.Person.onUpdate(function(model){
    console.log(model.fullName() + " has been updated");
});

Invisible.Person.onDelete(function(model){
    console.log(model.fullName() + " has been deleted");
});
```

## Authentication

Invisible.js provides a default method to authenticate the requests to the REST API, based on OAuth2's [Resource
Owner Password flow](http://techblog.hybris.com/2012/06/11/oauth2-resource-owner-password-flow/). This means than when activating authentication, a route is exposed that exchanges user
credentials for a request token used to sign the rest of the API calls. Unsigned calls will get a 401 response.

To use authentication, you must first define a user model in whatever way you like; the only constraint is that 
you must be able to identify a user with a pair of credentials such as username/password. By default the `User` 
name is assumed for the model, but this can be overriden via the `userModel` configuration.

```javascript
//models/user.js
function User(email){
    this.email = email;
}

User.prototype.setPassword = function(rawPassword){
    this.hashedPassword = someHashFunction(rawPassword);
}

User.prototype.isPassword = function(rawPassword){
    return this.hashedPassword == someHashFunction(rawPassword);
}

module.exports = Invisible.createModel("User", User);
```

Once the User model is defined, authentication is activated by defining an `authenticate` function in the 
configuration, that takes the credentials and returns the authenticated user:

```javascript
//auth.js
module.exports = function authenticateUser(email, password, done){

    Invisible.User.query({email: email}, function(err, users){
        if (err) {
            return done(err);
        }
        if (users.length < 1){
            return done(null, false);
        }
        var user = users[0];
        if (!user.isPassword(password)) {
            return done(null, false);
        }
        return done(null, user);
    });
}

//app.js
//...express and invisible configurations...
auth = require("./auth");
invisible.createServer(app, path.join(__dirname, "models"), {authenticate: auth});
```

Optionally, an `authExpiration` configuration can be included to specify the amount of seconds the acess token
can be used before requiring a refresh. The token refresh is managed seamlessly by the client models.

In order for the client model to get an access token to sign its requests, a `login` function must be called when
the user enters his credentials; note that these are used for the exchange and not stored for further use:

```javascript
//...get credentials from login form...
Invisible.login(email, password, function(err){
   if(err){
    console.log("Invalid credentials!");
   } else {
    console.log("User logged, requests signed");
   }
});
```

Once login is successful, the calls to the REST API will be allowed to the client models. A `logout` method is also
provided to drop the tokens from being used in further model requests.

The only endpoint which does not require a signed request is the POST to the user model, to allow user registration.

## Authorization
Once you can identify the user making requests, you'll usually want to establish what he can and can't do with the data.
The models provide hooks to authorize a user to call its methods: `allowCreate`, `allowUpdate`, `allowFind` and `allowDelete`. All of them take the user instance and should callback telling if the method is allowed to that user:

```javascript
function Message(from, to, text){
    this.from = from._id.toString();
    this.to = to._id.toString();
    this.text = text;
}

Message.prototype.allowCreate(user, cb) {
    //a user can only create messages sent by him
    return cb(null, from === user._id.toString());
}

Message.prototype.allowUpdate(user, cb) {
    //a user can only update messages sent by him
    return cb(null, from === user._id.toString());
}

Message.prototype.allowFind(user, cb) {
    //a user can only get messages sent by him or to him
    return cb(null, from === user._id.toString() || to === user._id.toString());
}

Message.prototype.allowDelete(user, cb) {
    //a user cannot delete messages
    return cb(null, false);
}

module.exports = Invisible.createModel("User", User);
```

Another hook, `baseQuery`, is available to restrict what segment of the database the user should have access to.
It also takes the user, and callbacks with a criteria object like the one for the [query method](/#query). This base criteria
is and-ed with the criteria used in `query` to filter out unauthorized data. Following the previous example:

```javascript
Message.baseQuery = function(user, cb){
    //only expose message sent to or by the user
    return cb(null, {$or: [{from: user._id.toString()}, {to: user._id.toString()}]})
}
```
Now when calling `Invisible.Message.query` in the client, only messages sent by and to the logged user will be 
received.



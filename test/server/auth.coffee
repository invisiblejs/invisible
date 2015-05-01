assert = require('assert')
Invisible = require('../../')
request = require('supertest')
mongo = require('mongodb')
express = require('express')
config = require('../../lib/config')
bodyParser = require('body-parser')
sinon = require('sinon')

config.db_uri = 'mongodb://127.0.0.1:27017/invisible-test'

app = express()
app.use(bodyParser.json());
app.use(require('../../lib/auth'))
require('../../lib/routes')(app)

user = undefined
config.authenticate = (username, password, cb) ->
    if username == "Facundo" and password == "pass"
        return cb(null, user)
    return cb("failed!")
config.authExpiration = 10

describe 'Authentication routes', () ->

    db = undefined

    before (done) ->
        class User
            constructor: (@user, @pass) ->

        Invisible.createModel("User", User)
        user = new Invisible.models.User("Facundo", "pass")

        mongo.connect config.db_uri, (err, database) ->
            db = database
            db.dropDatabase ()->
                user.save ()->
                    done()

    it 'Should send a 401 when authentication is configured', (done)->
        request(app)
        .get('/invisible/User/')
        .end (err, res) ->
            assert.equal(res.statusCode, 401)
            done()

    it 'Should send send a 200 when including a valid token', (done)->
        expires = new Date()
        expires.setSeconds(expires.getSeconds() + 10)
        token =
            token: "access"
            refresh: "refresh"
            expires: expires
            user: user._id

        col = db.collection("AuthToken")
        col.save token, (err, token)->
            request(app)
            .get('/invisible/User/')
            .set('Authorization', 'Bearer access')
            .end (err, res) ->
                assert.equal(res.statusCode, 200)
                assert not err
                done()

    it 'Should send send a 401 when including an invalid token', (done)->
        request(app)
        .get('/invisible/User/')
        .set('Authorization', 'Bearer invalid')
        .end (err, res) ->
            assert.equal(res.statusCode, 401)
            done()

    it 'Should send send a 401 when the token has expired', (done)->
        expires = new Date()
        expires.setSeconds(expires.getSeconds() - 10)
        token =
            token: "expired"
            refresh: "refresh"
            expires: expires
            user: user._id

        col = db.collection("AuthToken")
        col.save token, (err, token)->
            request(app)
            .get('/invisible/User/')
            .set('Authorization', 'Bearer expired')
            .end (err, res) ->
                assert.equal(res.statusCode, 401)
                done()

    it 'Should generate a new token when authenticated', (done)->
        request(app)
        .get('/invisible/authtoken/')
        .send(grant_type: "password", username: "Facundo", password: "pass")
        .end (err, res) ->
            assert.equal(res.statusCode, 200)
            assert.equal(res.body.token_type, "bearer")
            assert res.body.access_token
            assert res.body.expires_in
            assert res.body.refresh_token
            done()

    it 'Should not generate a token when not authenticated', (done)->
        request(app)
        .get('/invisible/authtoken/')
        .send(grant_type: "password")
        .end (err, res) ->
            assert.equal(res.statusCode, 401)
            done()

    it 'Should not generate a token when the credentials are invalid', (done)->
        request(app)
        .get('/invisible/authtoken/')
        .send(grant_type: "password", username: "Facundo", password: "wrong")
        .end (err, res) ->
            assert.equal(res.statusCode, 401)
            done()

    it 'Should refresh the token when given a valid refresh token', (done)->
        expires = new Date()
        expires.setSeconds(expires.getSeconds() - 10)
        token =
            token: "expired"
            refresh: "refresh"
            expires: expires
            user: user._id

        col = db.collection("AuthToken")
        col.save token, (err, token)->
            request(app)
            .get('/invisible/authtoken/')
            .send(grant_type: "refresh_token", refresh_token: "refresh")
            .end (err, res) ->
                assert.equal(res.statusCode, 200)
                assert.equal(res.body.token_type, "bearer")
                assert res.body.access_token
                assert res.body.expires_in
                assert res.body.refresh_token
                done()


    it 'Should not refresh the token when not given a refresh token', (done)->
        request(app)
        .get('/invisible/authtoken/')
        .send(grant_type: "refresh_token")
        .end (err, res) ->
            assert.equal(res.statusCode, 401)
            done()

    it 'Should not refresh the token when given an invalid refresh token', (done)->
        request(app)
        .get('/invisible/authtoken/')
        .send(grant_type: "refresh_token", refresh_token: "wrong")
        .end (err, res) ->
            assert.equal(res.statusCode, 401)
            done()

    it 'Should not allow reusing the refresh token', (done)->
        expires = new Date()
        expires.setSeconds(expires.getSeconds() - 10)
        token =
            token: "expired"
            refresh: "refresh"
            expires: expires
            user: user._id

        col = db.collection("AuthToken")
        col.save token, (err, token)->
            request(app)
            .get('/invisible/authtoken/')
            .send(grant_type: "refresh_token", refresh_token: "refresh")
            .end (err, res) ->
                request(app)
                .get('/invisible/authtoken/')
                .send(grant_type: "refresh_token", refresh_token: "refresh")
                .end (err, res) ->
                    assert.equal(res.statusCode, 401)
                    done()

    #FIXME authtoken should work with POST only

    describe 'Authorization methods', () ->

        db = undefined
        m1 = undefined
        m2 = undefined
        facundo = undefined
        martin = undefined

        before (done)->
            class User
                constructor: (@user, @pass) ->
            Invisible.createModel("User", User)

            class Message
                constructor: (@text, @from) ->
            Invisible.createModel("Message", Message)

            facundo = new Invisible.models.User("Facundo", "pass")
            martin = new Invisible.models.User("Martin", "pass")

            mongo.connect config.db_uri, (err, database) ->
                db = database
                db.dropDatabase ()->
                    facundo.save ()->
                        expires = new Date()
                        expires.setSeconds(expires.getSeconds() + 10)
                        token =
                            token: "access"
                            refresh: "refresh"
                            expires: expires
                            user: facundo._id

                        col = db.collection("AuthToken")
                        col.save token, (err, token)->
                            martin.save ()->
                                m1 = new Invisible.models.Message("Hey", facundo._id)
                                m1.save ()->
                                    m2 = new Invisible.models.Message("Bye", martin._id)
                                    m2.save ()->
                                        done()

        it 'Should authorize any authenticated user if method not defined', (done)->
            request(app)
            .get("/invisible/Message/#{m2._id}/")
            .set('Authorization', 'Bearer access')
            .end (err, res) ->
                assert.equal(res.statusCode, 200)
                assert not err
                done()

        it 'Should allow authorized create', (done)->
            Invisible.models.Message.prototype.allowCreate = (user, cb)->
                console.log(user._id, typeof(user._id))
                console.log(this.from, typeof(this.from))
                return cb(null, this.from == user._id)

            request(app)
            .post("/invisible/Message/")
            .send({text:"howdy", from:facundo._id})
            .set('Authorization', 'Bearer access')
            .end (err, res) ->
                assert.equal(res.statusCode, 200)
                assert not err
                done()

        it 'Should send a 401 for unauthorized create', (done)->
            Invisible.models.Message.prototype.allowCreate = (user, cb)->
                return cb(null, this.from == user._id)

            request(app)
            .post("/invisible/Message/")
            .send({text:"howdy", from:martin._id})
            .set('Authorization', 'Bearer access')
            .end (err, res) ->
                assert.equal(res.statusCode, 401)
                done()

        it 'Should allow authorized update', (done)->
            Invisible.models.Message.prototype.allowUpdate = (user, cb)->
                return cb(null, this.from == user._id)

            request(app)
            .put("/invisible/Message/#{m1._id}/")
            .send({text:"howdy", from:facundo._id})
            .set('Authorization', 'Bearer access')
            .end (err, res) ->
                assert.equal(res.statusCode, 200)
                assert not err
                done()

        it 'Should send a 401 for unauthorized update', (done)->
            Invisible.models.Message.prototype.allowUpdate = (user, cb)->
                return cb(null, this.from == user._id)

            request(app)
            .put("/invisible/Message/#{m2._id}/")
            .send({text:"howdy", from:facundo._id})
            .set('Authorization', 'Bearer access')
            .end (err, res) ->
                assert.equal(res.statusCode, 401)
                done()

        it 'Should allow authorized find', (done)->
            Invisible.models.Message.prototype.allowFind = (user, cb)->
                return cb(null, this.from == user._id)

            request(app)
            .get("/invisible/Message/#{m1._id}/")
            .set('Authorization', 'Bearer access')
            .end (err, res) ->
                assert.equal(res.statusCode, 200)
                assert not err
                done()

        it 'Should send a 401 for unauthorized find', (done)->
            Invisible.models.Message.allowFind = (user, cb)->
                return cb(null, this.from == user._id)

            request(app)
            .get("/invisible/Message/#{m2._id}/")
            .set('Authorization', 'Bearer access')
            .end (err, res) ->
                assert.equal(res.statusCode, 401)
                done()

        it 'Should allow authorized delete', (done)->
            Invisible.models.Message.prototype.allowDelete = (user, cb)->
                return cb(null, this.from == user._id)

            request(app)
            .del("/invisible/Message/#{m1._id}/")
            .set('Authorization', 'Bearer access')
            .end (err, res) ->
                assert.equal(res.statusCode, 200)
                assert not err
                done()

        it 'Should send a 401 for unauthorized delete', (done)->
            Invisible.models.Message.prototype.allowDelete = (user, cb)->
                return cb(null, this.from == user._id)

            request(app)
            .del("/invisible/Message/#{m2._id}/")
            .set('Authorization', 'Bearer access')
            .end (err, res) ->
                assert.equal(res.statusCode, 401)
                done()

EventEmitter = require('events').EventEmitter;

class NamesPaceMock extends EventEmitter
    constructor: (@name)->
        @sockets = []
        @connected = {}
    connect: (client)->
        @sockets.push(client)
        @connected[client.id] = client
        @emit('connection', client)

class ServerSocketMock extends EventEmitter
    constructor: ()->
        @nsps = {
            "/User": new NamesPaceMock("/User"),
            "/Message": new NamesPaceMock("/Message")
        }
    connect: (nsp, client)->
        @emit('connection', client)
        @nsps[nsp].connect(client)


class ClientSocketMock extends EventEmitter
    constructor: (@id)->
        @client = {}
    disconnect: ()->
        @emit('disconnect')

describe 'Server socket authentication', () ->

    server = undefined
    client = undefined
    facundo = undefined
    db = undefined

    before (done)->
        #TODO make the socket login independent from the tokens
        class User
            constructor: (@user, @pass) ->
        Invisible.createModel("User", User)

        facundo = new Invisible.models.User("Facundo", "pass")

        mongo.connect config.db_uri, (err, database) ->
            db = database
            db.dropDatabase ()->
                facundo.save ()->
                    token =
                        token: "access"
                        refresh: "refresh"
                        user: facundo._id

                    col = db.collection("AuthToken")
                    col.save token, (err, token)->
                        expires = new Date()
                        expires.setSeconds(expires.getSeconds() - 10)
                        token = {
                            token: "expired",
                            expires: expires,
                            user: facundo._id
                        }
                        col.save token, done


    beforeEach () ->
        #FIXME copy pasted
        Token = require('../../lib/auth/token')
        server = new ServerSocketMock()
        require('socketio-auth')(server, {
            timeout:80,
            authenticate: Token.check
            })
        client = new ClientSocketMock(5)

    it 'Should mark the socket as unauthenticated upon connection', (done)->
        assert client.auth == undefined
        server.connect("/User", client)
        process.nextTick ()->
            assert client.auth == false
            done()

    it 'Should not send messages to unauthenticated sockets', (done)->
        server.connect("/User", client)
        process.nextTick ()->
            assert !server.nsps['/User'][5]
            done()

    it 'Should disconnect sockets that do not authenticate', (done)->
        server.connect("/User", client)
        client.on 'disconnect', ()->
            done()

    #TODO decouple socket from token tests
    it 'Should authenticate with a valid token', (done)->
        server.connect("/User", client)
        process.nextTick ()->
            client.on 'authenticated', ()->
                assert client.auth
                done()
            client.emit('authentication', {token: "access"})

    it 'Should call post auth function', (done)->
        #FIXME copy pasted
        Token = require('../../lib/auth/token')
        server = new ServerSocketMock()
        client = new ClientSocketMock(5)

        postAuth = (socket, tokenData) ->
            assert.equal tokenData.token, "access"
            assert.equal socket, client
            done()

        require('socketio-auth')(server, {
            timeout:80,
            authenticate: Token.check
            postAuthenticate: postAuth
            })

        server.connect("/User", client)
        process.nextTick ()->
            client.emit('authentication', {token: "access"})

    it 'Should send updates to authenticated sockets', (done)->
        server.connect("/User", client)
        process.nextTick ()->
            client.on 'authenticated', ()->
                assert.equal server.nsps['/User'].connected[5], client
                done()
            client.emit('authentication', {token: "access"})

    it 'Should not authenticate without an auth token', (done)->
        server.connect("/User", client)
        process.nextTick ()->
            client.once 'disconnect', ()->
                done()
            client.emit('authentication', {})

    it 'Should not authenticate with an invalid token', (done)->
        server.connect("/User", client)
        process.nextTick ()->
            client.once 'disconnect', ()->
                done()
            client.emit('authentication', {token: "invalid"})

    it 'Should not authenticate with an expired token', (done)->
        server.connect("/User", client)
        process.nextTick ()->
            client.once 'disconnect', ()->
                done()
            client.emit('authentication', {token: "expired"})


describe 'Server socket authorization', () ->
    client = undefined
    server = undefined
    facundo = undefined
    martin = undefined

    before (done)->
        class User
            constructor: (@user, @pass) ->
        Invisible.createModel("User", User)

        class Message
            constructor: (@text, @from, @to) ->
            allowEvents: (user, cb)->
                cb(null, user._id == @to)

        Invisible.createModel("Message", Message)
        facundo = new Invisible.models.User("Facundo", "pass")
        facundo.save()
        martin = new Invisible.models.User("Martin", "pass")
        martin.save()
        client = new ClientSocketMock(5)
        server = new ServerSocketMock()

        Invisible.models.User.serverSocket = server.nsps["/User"]
        Invisible.models.Message.serverSocket = server.nsps["/Message"]

        client.auth = true
        client.client.user = facundo
        done()

    it 'Should send events to any client if allow method not defined', (done)->
        server.connect("/User", client)
        person = new Invisible.models.User()

        #allow not defined, the namespace does regular broadcast
        Invisible.models.User.serverSocket.once 'new', (model)->
            assert.equal person, model
            done()

        person.save ()->
            undefined

    it 'Should send events to authorized clients', (done)->
        server.connect("/Message", client)
        msg = new Invisible.models.Message("hi", martin._id, facundo._id)

        client.once 'new', (model)->
            assert.equal msg, model
            done()

        msg.save ()->
            undefined

    it 'Should not send events to unauthorized clients', (done)->
        server.connect("/Message", client)
        msg = new Invisible.models.Message("hi", facundo._id, martin._id)

        callback = sinon.spy()
        client.once 'new', callback

        msg.save ()->
            sinon.assert.notCalled(callback)
            done()



assert = require('assert')
Invisible = require('../../')
request = require('supertest')
mongo = require('mongodb')
express = require('express')
config = require('../../lib/config')

config.db_uri = 'mongodb://127.0.0.1:27017/invisible-test'

app = express()
app.use express.bodyParser()
app.use(require('../../lib/auth'))
require('../../lib/routes')(app)


describe 'Auth routes', () ->

    user = undefined
    db = undefined

    before (done) ->
        config.authenticate = (username, password, cb) ->
            if username == "Facundo" and password == "pass"
                return cb(null, user)
            return cb("failed!")
        config.authExpiration = 10

        class User
            constructor: (@user, @pass) ->

        Invisible.createModel("User", User)
        user = new Invisible.User("Facundo", "pass")
        
    
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
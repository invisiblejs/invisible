assert = require('assert')
Invisible = require('../../')
nock = require('nock')
EventEmitter = require('events').EventEmitter;
proxyquire =  require('proxyquire')

class Person
    constructor: (@name) ->
    getName: ()-> return @name

class SocketMock extends EventEmitter
    connect: (url)->
        self = @
        self.connected = true
        process.nextTick ()->
            self.emit('connect')
        return self

socketMock = new SocketMock()

describe 'Client Authenticated methods', () ->

    person = undefined

    before () ->
        global.window = {location: {hostname: "localhost"}, localStorage: {}}
        
        authMethods = proxyquire('../../lib/auth/methods', {
            'socket.io-client': socketMock
            })

        Invisible.login = authMethods.login
        Invisible.logout = authMethods.logout
        nock.disableNetConnect()
        #mocking client
        Invisible.isClient = () -> return true
        Invisible.getHostname = () -> return "localhost"

        class Person
            constructor: (@name) ->
        Invisible.createModel('Person', Person)
        person = new Invisible.models.Person("Martin")

    after () ->
        delete global.window
        nock.enableNetConnect()

    beforeEach ()->
        Invisible.AuthToken =
            access_token: "MyToken"

    it 'Should not include the Authorization header when auth not configured', (done)->
        Invisible.AuthToken = undefined

        findreq = nock('http://localhost:80')
        .get('/invisible/Person/theid/')
        .matchHeader("Authorization", undefined)
        .reply(200, _id:'theid', name: 'Carlos')

        Invisible.models.Person.findById "theid", (err, model)->
            assert findreq.isDone()
            done()

    it 'Should include the Authorization header on save', (done)->
        savereq = nock('http://localhost:80')
        .post('/invisible/Person/', {name: "Martin"})
        .matchHeader("Authorization", "Bearer MyToken")
        .reply(200, {_id: "someid"})
        person.save () ->
            assert savereq.isDone()
            done()

    it 'Should include the Authorization header on update', (done)->
        updatereq = nock('http://localhost:80')
        .put('/invisible/Person/someid/', {_id: "someid", name: "Martin"})
        .matchHeader("Authorization", "Bearer MyToken")
        .reply(200, {_id: "someid"})
        person.save () ->
            assert updatereq.isDone()
            done()

    it 'Should include the Authorization header on query', (done)->
        queryreq = nock('http://localhost:80')
        .get('/invisible/Person/?query=%7B%7D&opts=%7B%22limit%22%3A1%7D')
        .matchHeader("Authorization", "Bearer MyToken")
        .reply(200, [{name: "Martin", _id:"2"}])

        Invisible.models.Person.query {}, limit: 1, (e, models) ->
            assert queryreq.isDone()
            done()

    it 'Should include the Authorization header on findById', (done)->
        findreq = nock('http://localhost:80')
        .get('/invisible/Person/theid/')
        .matchHeader("Authorization", "Bearer MyToken")
        .reply(200, _id:'theid', name: 'Carlos')

        Invisible.models.Person.findById "theid", (err, model)->
            assert findreq.isDone()
            done()

    it 'Should include the Authorization header on delete', (done)->
        deletereq = nock('http://localhost:80')
        .delete('/invisible/Person/someid/')
        .matchHeader("Authorization", "Bearer MyToken")
        .reply(200)
        person.delete () ->
            assert deletereq.isDone()
            done()

    it 'Should refresh the AuthToken when expired', (done)->
        d = new Date()
        d.setSeconds(d.getSeconds() - 10)

        Invisible.AuthToken =
            access_token: "MyToken"
            refresh_token: "MyRefresh"
            expires_in: d

        findreq = nock('http://localhost:80')
        .post('/invisible/authtoken/', {refresh_token: "MyRefresh", grant_type: "refresh_token"})
        .reply(200, access_token:'MyNewToken', refresh_token: 'MyNewRefresh', expires_in: 3600)
        .get('/invisible/Person/theid/')
        .matchHeader("Authorization", "Bearer MyNewToken")
        .reply(200, _id:'theid', name: 'Martin')

        Invisible.models.Person.findById "theid", (err, model)->
            assert findreq.isDone()
            assert.equal(Invisible.AuthToken.refresh_token, "MyNewRefresh")
            assert Invisible.AuthToken.expires_in > new Date()
            done()

    it 'Should set the AuthToken on login', (done)->
        tokenreq = nock('http://localhost:80')
        .post('/invisible/authtoken/', {username: "user", password: "pass", grant_type: "password"})
        .reply(200, access_token:'otherToken', refresh_token: 'otherRefresh', expires_in: 3600)

        Invisible.login "user", "pass", ()->
            assert.equal Invisible.AuthToken.access_token, 'otherToken'
            assert.equal Invisible.AuthToken.refresh_token, 'otherRefresh'
            token = JSON.parse window.localStorage.InvisibleAuthToken
            assert.deepEqual Invisible.AuthToken, token
            done()

    it 'Should remove the AuthToken on logout', ()->
        assert Invisible.AuthToken
        assert window.localStorage.InvisibleAuthToken
        Invisible.logout()
        assert !Invisible.AuthToken
        assert !window.localStorage.InvisibleAuthToken

    it 'Should connect socket after login', (done)->
        socketMock.connected = false
        tokenreq = nock('http://localhost:80')
        .post('/invisible/authtoken/', {username: "user", password: "pass", grant_type: "password"})
        .reply(200, access_token:'otherToken', refresh_token: 'otherRefresh', expires_in: 3600)

        Invisible.login "user", "pass", ()->
            assert socketMock.connected
            done()

    it 'Should authenticate socket after connect', (done)->
        socketMock.once 'authenticate', (data)->
            assert.equal data.token, "otherToken"
            done()

        tokenreq = nock('http://localhost:80')
        .post('/invisible/authtoken/', {username: "user", password: "pass", grant_type: "password"})
        .reply(200, access_token:'otherToken', refresh_token: 'otherRefresh', expires_in: 3600)

        Invisible.login "user", "pass", ()->
            undefined

    it 'Should disconnect socket on logout', (done)->
        socketMock.once 'disconnect', (data)->
            done()
        Invisible.logout()

#TODO test auth fails gracefully
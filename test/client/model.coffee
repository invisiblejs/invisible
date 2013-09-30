assert = require('assert')
Invisible = require('../../')
nock = require('nock')

class Person
    constructor: (@name) ->
    getName: ()-> return @name
    validations: 
        properties: name: type: 'string'
        methods: ['validateValid1', 'validateValid2']
    validateValid1: (cb) ->
        cb(valid: true, errors:[])
    validateValid2: (cb) ->
        cb(valid: true, errors:[])
    validateInvalid: (cb) ->
        cb(valid: false, errors:['something failed'])

describe 'Client createModel()', () ->
    person = undefined

    before () ->
        #mocking client
        Invisible.isClient = () -> return true

        Invisible.createModel('Person', Person)
        person = new Invisible.Person("Martin")

    it 'should be at the client', () ->
        assert(Invisible.isClient())

    it 'should call the original constructor', () ->
        assert.equal(person.name, "Martin")

    it 'should extend the object with CRUD methods', () ->
        assert(person.save?, "Has no save method")
        assert(person.delete?, "Has no delete method")

describe 'Client InvisibleModel', () ->
    person = undefined

    before () ->
        nock.disableNetConnect()
        #mocking client
        Invisible.isClient = () -> return true

        Invisible.createModel('Person', Person)
        person = new Invisible.Person("Martin")

    after () ->
        nock.enableNetConnect()

    it 'should send a POST when saving a new instance and set the _id', (done)->
        savereq = nock('http://localhost:80').post('/invisible/Person/', 
            {name: "Martin"}).reply(200, {_id: "someid"})
        person.save () ->
            assert.equal(person._id, "someid")
            assert savereq.isDone()
            done()

    it 'should send a PUT when saving an existent instace and update its values', (done)->
        person.name = "Facundo"
        updatereq = nock('http://localhost:80').put('/invisible/Person/someid/', 
            {_id: "someid", name: "Facundo"}).reply(200, {_id: "someid"})
        person.save () ->
            assert.equal(person._id, "someid")
            assert updatereq.isDone()
            done()

    it 'should raise an error when updating an unexistent instance', ()->
        #TODO
        assert(true)

    it 'should send a DELETE when removing an instance', (done)->
        deletereq = nock('http://localhost:80').delete('/invisible/Person/someid/').reply(200)
        person.delete () ->
            assert deletereq.isDone()
            done()

    it 'should do nothing when deleting an unsaved instance', ()->
        #TODO
        assert(true)

    it 'should raise an error when deleting an unexistent instance', ()->
        #TODO
        assert(true)

    it 'should send a GET to an id when finding by id, and return the result', (done)->
        findreq = nock('http://localhost:80')
        .get('/invisible/Person/anotherid/')
        .reply(200, _id:'anotherid', name: 'Carlos')
        
        Invisible.Person.findById 'anotherid', (e, model) ->
            assert.equal(model._id, 'anotherid')
            assert.equal(model.getName(), 'Carlos')
            assert findreq.isDone()
            done()

    it 'should raise an error when finding by an invalid id', (done)->
        invalidreq = nock('http://localhost:80')
        .get('/invisible/Person/invalidid/')
        .reply(500)
        
        Invisible.Person.findById 'invalidid', (e, model) ->
            assert e
            assert invalidreq.isDone()
            done()

    it 'should raise an error when finding by an unexistent id', (done)->
        missingreq = nock('http://localhost:80')
        .get('/invisible/Person/missingid/')
        .reply(404)
        
        Invisible.Person.findById 'missingid', (e, model) ->
            assert e
            assert missingreq.isDone()
            done()

    it 'should send a GET to the resource when finding and return a list of instances', (done)->
        queryreq = nock('http://localhost:80')
        .get('/invisible/Person/?query=%7B%7D&opts=%7B%7D')
        .reply(200, [{name: "Facundo", _id:"2"},{name: "Martin", _id:"1"}])
        
        Invisible.Person.query (e, models) ->
            assert.equal(models[0].getName(), 'Facundo')
            assert.equal(models[1].getName(), 'Martin')
            assert queryreq.isDone()
            done()

    it 'should send a GET with query parameters when finding and return a list of instances', (done)->
        queryreq = nock('http://localhost:80')
        .get('/invisible/Person/?query=%7B%22name%22%3A%22Facundo%22%7D&opts=%7B%7D')
        .reply(200, [{name: "Facundo", _id:"2"}])
        
        Invisible.Person.query name:"Facundo", (e, models) ->
            assert.equal(models[0].getName(), 'Facundo')
            assert queryreq.isDone()
            done()

    it 'should send a GET with options when finding and return a list of instances', (done)->
        queryreq = nock('http://localhost:80')
        .get('/invisible/Person/?query=%7B%7D&opts=%7B%22limit%22%3A1%7D')
        .reply(200, [{name: "Facundo", _id:"2"}])
        
        Invisible.Person.query {}, limit: 1, (e, models) ->
            assert.equal(models[0].getName(), 'Facundo')
            assert queryreq.isDone()
            done()

    it 'should return a validation error when invalid', (done)->
        person = new Invisible.Person("Luis")
        person.validate (result) ->
            assert(result.valid)
            assert.equal(result.errors.length, 0)
            
            person.name = 15 #invalid
            person.validate (result) ->
                assert(not result.valid)
                assert.equal(result.errors.length, 1)
                done()

    it 'should fail on custom validation methods when invalid', (done)->
        person = new Invisible.Person("Luis")
        person.validate (result) ->
            assert(result.valid)
            person.validations.methods = ['validateValid1', 'validateInvalid', 'validateValid2']
            person.validate (result) ->
                assert(not result.valid)
                assert.deepEqual(result.errors, ['something failed'])
                done()

    it 'should not save an invalid instance', (done)->
        person = new Invisible.Person(15)
        person.save (err, result)->
            assert(err)
            done()

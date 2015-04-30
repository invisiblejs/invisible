Invisible = require('../../')
assert = require('assert')
mongo = require('mongodb')
config = require('../../lib/config')

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

db = undefined
before (done) ->
    config.db_uri = 'mongodb://127.0.0.1:27017/invisible-test'

    mongo.connect config.db_uri, (err, database) ->
        db = database
        db.dropDatabase(done)

describe 'Server createModel()', () ->
    person = undefined

    before () ->
        Invisible.createModel('Person', Person)
        person = new Invisible.models.Person("Martin")

    it 'should call the original constructor', () ->
        assert.equal(person.name, "Martin")

    it 'should extend the object with CRUD methods', () ->
        assert(person.save?, "Has no save method")
        assert(person.delete?, "Has no delete method")

describe 'Server InvisibleModel', () ->

    martin = undefined
    facundo = undefined

    before () ->
        Invisible.createModel('Person', Person)
        martin = new Invisible.models.Person('Martin')
        facundo = new Invisible.models.Person('Facundo')


    it 'should update id and create document on save', (done) ->
        assert(not martin._id?)
        assert(not facundo._id?)
        martin.save ()->
            assert(martin._id?)

            db.collection("Person").findOne {_id: new mongo.ObjectID(martin._id)}, (err, result) ->
                assert(result?)
                assert.equal(result.name, 'Martin')
                done()

    it 'should update the document when saving a modified instance', (done) ->
        assert(martin._id?)
        martin.name = "Carlos"
        martin.save ()->
            db.collection("Person").findOne {_id: new mongo.ObjectID(martin._id)}, (err, result) ->
                assert(result?)
                assert.equal(result.name, 'Carlos')
                done()

    it 'should remove the document on delete', (done) ->
        martin.delete (err)->
            assert(not err?)
            db.collection("Person").findOne {_id: new mongo.ObjectID(martin._id)}, (err, result) ->
                assert(not result?)
                done()

    it 'should find instance by id', (done) ->
        martin._id = undefined
        martin.save () ->
            id = martin._id
            Invisible.models.Person.findById id, (e, result) ->
                assert.equal(martin.name, result.name)
                assert.equal(martin._id, result._id)
                done()

    it 'should raise an error for finding by an unexistent id', (done) ->
        nonExistentId = '507f1f77bcf86cd700000000'
        Invisible.models.Person.findById nonExistentId, (e, result)->
            assert(e)
            done()

    it 'should raise an error for finding by an invalid id', (done)->
        assert.throws () ->
            Invisible.models.Person.findById "asdadadsd", (e, result)->
                assert.fail("Shouldn't call this")
            , Error
        done()

    it 'should find instances with query', (done) ->
        facundo.save () ->
            assert(facundo._id)
            assert(martin._id)
            Invisible.models.Person.query (e, results)->
                assert.equal(results.length, 2)
                #use getName to assure its a model and not a plain object
                assert(facundo.name == results[0].getName() or facundo.name == results[1].getName())
                assert(martin.name == results[0].getName() or martin.name == results[1].getName())
                done()

    it 'should apply filters on query', (done) ->
        Invisible.models.Person.query name: "Facundo", (e, results)->
            assert.equal(results.length, 1)
            assert.equal(results[0].getName(), "Facundo")
            assert.equal(facundo._id, results[0]._id)
            done()

    it 'should allow querying by _id string', (done) ->

        Invisible.models.Person.query _id: facundo._id, (e, results)->
            assert.equal(results.length, 1)
            assert.equal(results[0].getName(), "Facundo")

            Invisible.models.Person.query _id: $in: [facundo._id], (e, results)->
                assert.equal(results.length, 1)
                assert.equal(results[0].getName(), "Facundo")

                Invisible.models.Person.query _id: $nin: [martin._id], (e, results)->
                    assert.equal(results.length, 1)
                    assert.equal(results[0].getName(), "Facundo")

                    done()

    it 'should apply query options', (done) ->
        Invisible.models.Person.query {}, limit: 1, (e, results)->
            assert.equal(results.length, 1)
            done()

    it 'should return a validation error when invalid', (done)->
        person = new Invisible.models.Person("Luis")
        person.validate (result) ->
            assert(result.valid)
            assert.equal(result.errors.length, 0)

            person.name = 15 #invalid
            person.validate (result) ->
                assert(not result.valid)
                assert.equal(result.errors.length, 1)
                done()

    it 'should fail on custom validation methods when invalid', (done)->
        person = new Invisible.models.Person("Luis")
        person.validate (result) ->
            assert(result.valid)
            person.validations.methods = ['validateValid1', 'validateInvalid', 'validateValid2']
            person.validate (result) ->
                assert(not result.valid)
                assert.deepEqual(result.errors, ['something failed'])
                #restore validations
                person.validations.methods = ['validateValid1', 'validateValid2']
                done()

    it 'should not save an invalid instance', (done)->
        person = new Invisible.models.Person(15)
        person.save (err, result)->
            assert(err)
            done()

class SocketMock
    constructor: () ->
        @listeners = {}
    on: (event, cb) ->
        @listeners[event] = cb
    emit: (event, data) ->
        @listeners[event](data)

describe 'Server real time events', () ->
    person = undefined

    before () ->
        Invisible.createModel('Person', Person)
        person = new Invisible.models.Person("Martin")

    it "should emit 'new' when creating an instance", (done) ->
        socket = new SocketMock()
        socket.on 'new', (model)->
            assert.equal(model.getName(), "Martin")
            done()
        Invisible.models.Person.serverSocket = socket
        person.save ()->
            undefined

    it "should emit 'update' when updating an instance", (done) ->
        socket = new SocketMock()
        socket.on 'update', (model)->
            assert.equal(model.getName(), "Facundo")
            done()
        Invisible.models.Person.serverSocket = socket
        person.name = "Facundo"
        person.save ()->
            undefined

    it "should emit 'delete' when deleting an instance", (done) ->
        socket = new SocketMock()
        socket.on 'delete', (model)->
            assert.equal(model.getName(), "Facundo")
            done()
        Invisible.models.Person.serverSocket = socket
        person.delete ()->
            undefined

# TODO should the user handle string ids, mongo ids or both?

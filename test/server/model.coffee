Invisible = require('../../')
assert = require('assert')
mongo = require('mongodb')

class Person
    constructor: (@name) ->
    getName: ()-> return @name
    validations: 
        properties: name: type: 'string'

db = undefined
before (done) ->
    global.invisibledb = 'mongodb://127.0.0.1:27017/invisible-test'
    
    mongo.connect global.invisibledb, (err, database) ->
        db = database
        db.dropDatabase(done)

describe 'Server createModel()', () ->
    person = undefined

    before () ->
        Invisible.createModel('Person', Person)
        person = new Invisible.Person("Martin")

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
        martin = new Invisible.Person('Martin')
        facundo = new Invisible.Person('Facundo')
        

    it 'should update id and create document on save', (done) ->
        assert(not martin._id?)
        assert(not facundo._id?)
        martin.save ()->
            assert(martin._id?)
            
            db.collection("Person").findOne {_id: martin._id}, (err, result) ->
                assert(result?)
                assert.equal(result.name, 'Martin')
                done()

    it 'should update the document when saving a modified instance', (done) ->
        assert(martin._id?)
        martin.name = "Carlos"
        martin.save ()->
            db.collection("Person").findOne {_id: martin._id}, (err, result) ->
                assert(result?)
                assert.equal(result.name, 'Carlos')
                done()

    it 'should remove the document on delete', (done) ->
        martin.delete (err)->
            assert(not err?)
            db.collection("Person").findOne {_id: martin._id}, (err, result) ->
                assert(not result?)
                done()

    it 'should find instance by id', (done) ->
        martin._id = undefined
        martin.save () ->
            id = martin._id.toString()
            Invisible.Person.findById id, (e, result) ->
                assert.equal(martin.name, result.name)
                assert.equal(martin._id.toString(), result._id.toString())
                done()

    it 'should raise an error for finding by an unexistent id', (done) ->
        nonExistentId = '507f1f77bcf86cd700000000'
        Invisible.Person.findById nonExistentId, (e, result)->
            assert(e)
            done()

    it 'should raise an error for finding by an invalid id', (done)->
        assert.throws () ->
            Invisible.Person.findById "asdadadsd", (e, result)->
                assert.fail("Shouldn't call this")
            , Error
        done()

    it 'should find instances with query', (done) ->
        facundo.save () ->
            assert(facundo._id)
            assert(martin._id)
            Invisible.Person.query (e, results)->
                assert.equal(results.length, 2)
                #use getName to assure its a model and not a plain object
                assert(facundo.name == results[0].getName() or facundo.name == results[1].getName())
                assert(martin.name == results[0].getName() or martin.name == results[1].getName())
                done()

    it 'should apply filters on query', (done) ->
        Invisible.Person.query name: "Facundo", (e, results)->
            assert.equal(results.length, 1)
            assert.equal(results[0].getName(), "Facundo")
            assert.equal(facundo._id.toString(), results[0]._id.toString())
            done()

    it 'should allow querying by _id string', (done) ->
        facundo_id = facundo._id.toString()
        martin_id = martin._id.toString()
        
        Invisible.Person.query _id: facundo_id, (e, results)->
            assert.equal(results.length, 1)
            assert.equal(results[0].getName(), "Facundo")

            Invisible.Person.query _id: $in: [facundo_id], (e, results)->
                assert.equal(results.length, 1)
                assert.equal(results[0].getName(), "Facundo")

                Invisible.Person.query _id: $nin: [martin_id], (e, results)->
                    assert.equal(results.length, 1)
                    assert.equal(results[0].getName(), "Facundo")

                    done()        

    it 'should apply query options', (done) ->
        Invisible.Person.query {}, limit: 1, (e, results)->
            assert.equal(results.length, 1)
            done()

    it 'should return a validation error when invalid', ()->
        person = new Invisible.Person("Luis")
        result = person.validate()
        assert(result.valid)
        assert.equal(result.errors.length, 0)
        
        person.name = 15 #invalid
        result = person.validate()
        assert(not result.valid)
        assert.equal(result.errors.length, 1)

    it 'should not save an invalid instance', ()->
        person = new Invisible.Person(15)
        assert.throws () -> 
                person.save()
            , Error

# TODO should the user handle string ids, mongo ids or both?
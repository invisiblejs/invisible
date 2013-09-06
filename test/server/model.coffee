Invisible = require('../../')
assert = require('assert')
mongo = require('mongodb')

class Person
    constructor: (@name) ->

db = undefined

before (done) ->
    global.invisibledb = 'mongodb://127.0.0.1:27017/invisible-test'
    
    mongo.connect global.invisibledb, (err, database) ->
        db = database
        db.dropDatabase(done)

describe 'Invisible.createModel()', () ->
    person = undefined

    before () ->
        Invisible.createModel('Person', Person)
        person = new Invisible.Person("Martin")

    it 'should call the original constructor', () ->
        assert.equal(person.name, "Martin")

    it 'should extend the object with CRUD methods', () ->
        assert(person.save?, "Has no save method")
        assert(person.delete?, "Has no delete method")

describe 'InvisibleModel', () ->

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
        assert(martin._id?)
        martin.delete ()->
            db.collection("Person").findOne {_id: martin._id}, (err, result) ->
                assert(not result?)
                done()

    it 'should find instance by id', (done) ->
        martin._id = undefined
        martin.save () ->
            id = martin._id.toString()
            Invisible.Person.findById id, (result)->
                assert.equal(martin.name, result.name)
                assert.equal(martin._id.toString(), result._id.toString())
                done()

    it 'should find instances with query', (done) ->
        facundo.save () ->
            assert(facundo._id)
            assert(martin._id)
            Invisible.Person.query (results)->
                assert.equal(results.length, 2)
                assert(facundo.name == results[0].name or facundo.name == results[1].name)
                assert(martin.name == results[0].name or martin.name == results[1].name)
                done()

    it 'should apply filters on query', () ->
        Invisible.Person.query name: "Facundo", (results)->
            assert.equal(results.length, 1)
            assert.equal(results[0].name, "Facundo")
            assert.equal(facundo._id.toString(), results[0]._id.toString())
            done()

# TODO test unhappy paths
    #find unexistent id
    #invalid id
    #update unexistent instance
    #delete unexistent instance
    #invalid mongo filters on query

# TODO should the user handle string ids, mongo ids or both?
# TODO invisible model equals?
# TODO should the id be erased after save?
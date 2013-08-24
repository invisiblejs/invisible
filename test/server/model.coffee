Invisible = require('../../')
assert = require('assert')

class Person
    constructor: (@name) ->

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

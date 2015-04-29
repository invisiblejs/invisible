assert = require('assert')
Invisible = require('../../')
request = require('supertest')
mongo = require('mongodb')
express = require('express')
path = require('path')
app = express()
bodyParser = require('body-parser');

config = require('../../lib/config')
app.use(bodyParser.json());
require('../../lib/routes')(app)


describe 'REST routes', () ->

    person_id = undefined

    before (done) ->
        config.db_uri = 'mongodb://127.0.0.1:27017/invisible-test'

        mongo.connect config.db_uri, (err, database) ->
            database.dropDatabase(done)

        class Person
            constructor: (@name) ->
            getName: ()-> return @name

        Invisible.createModel('Person', Person)

    it 'should create a new instance on POST', (done) ->
        request(app)
        .post('/invisible/Person/')
        .send({name: "Facundo"})
        .end (err, res) ->
            assert.equal(res.statusCode, 200)
            assert not err
            assert(res.body._id)
            person_id = res.body._id #lazy ass
            assert.equal(res.body.name, "Facundo")
            done()

    it 'should update instance on PUT', (done) ->
        request(app)
        .put('/invisible/Person/' + person_id)
        .send({name: "Martin"})
        .end (err, res) ->
            assert.equal(res.statusCode, 200)
            assert not err
            assert.equal(res.body._id, person_id)
            assert.equal(res.body.name, "Martin")
            done()

    it 'should return instance on GET id', (done) ->
        request(app)
        .get('/invisible/Person/' + person_id)
        .end (err, res) ->
            assert.equal(res.statusCode, 200)
            assert not err
            assert.equal(res.body._id, person_id)
            assert.equal(res.body.name, "Martin")
            done()

    it 'should return error on GET unexistent id', (done) ->
        nonExistentId = '507f1f77bcf86cd700000000'
        request(app)
        .get('/invisible/Person/' + nonExistentId)
        .end (err, res) ->
            assert.equal(res.statusCode, 404)
            done()

    it 'should return error on GET invalid id', (done) ->
        request(app)
        .get('/invisible/Person/1234')
        .end (err, res) ->
            assert.equal(res.statusCode, 500)
            done()

    it 'should return list of instances on GET list', (done) ->
        request(app)
        .get('/invisible/Person/')
        .end (err, res) ->
            assert.equal(res.statusCode, 200)
            assert not err
            assert.equal(res.body.length, 1)
            assert.equal(res.body[0].name, "Martin")
            done()

    it 'should correctly parse query criteria an opts in GET list', (done) ->
        request(app)
        .get('/invisible/Person/')
        .query(query: JSON.stringify(name: "Martin"))
        .end (err, res) ->
            assert.equal(res.statusCode, 200)
            assert not err
            assert.equal(res.body.length, 1)
            assert.equal(res.body[0].name, "Martin")
            done()

    it 'should correctly parse query criteria an opts in GET list', (done) ->
        request(app)
        .get('/invisible/Person/')
        .query(opts: JSON.stringify(limit: 1))
        .end (err, res) ->
            assert.equal(res.statusCode, 200)
            assert not err
            assert.equal(res.body.length, 1)
            assert.equal(res.body[0].name, "Martin")
            done()

    it 'should remove instance on DELETE', (done) ->
        request(app)
        .del('/invisible/Person/' + person_id)
        .end (err, res) ->
            assert.equal(res.statusCode, 200)
            request(app)
            .get('/invisible/Person/' + person_id)
            .end (err, res) ->
                assert.equal(res.statusCode, 404)
                done()

    it 'should send an error when saving an invalid instance', (done) ->
        class FailingPerson
            constructor: (@name) ->
            getName: ()-> return @name
            validations: methods: ['failingMethod']
            failingMethod: (cb)->
                cb(valid: false, errors: ['it fails'])

        Invisible.createModel('FailingPerson', FailingPerson)

        request(app)
        .post('/invisible/FailingPerson/')
        .send({name: "Facundo"})
        .end (err, res) ->
            assert.equal(res.statusCode, 400)
            done()

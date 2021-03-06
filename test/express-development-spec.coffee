{describe,beforeEach,afterEach,it,expect} = global
sinon            = require 'sinon'
request          = require 'request'
ExpressServer    = require './express-server'
OctobluRaven     = require '../'

describe 'Express Development', ->
  beforeEach ->
    @logFn = sinon.spy()
    @octobluRaven = new OctobluRaven({ @logFn, dsn: null })
    @server = new ExpressServer { @octobluRaven }

  afterEach ->
    @server.destroy()

  describe 'GET /throw/error', ->
    beforeEach (done) ->
      @server.start done

    beforeEach (done) ->
      options = {
        baseUrl: @server.baseUrl()
        uri: '/throw/error'
        json: true,
      }
      request.get options, (error, @response, @body) =>
        done error

    it 'should yield a 500', ->
      expect(@response.statusCode).to.equal 500

  describe 'GET /uncaught/error', ->
    beforeEach (done) ->
      @server.start done

    beforeEach (done) ->
      options = {
        baseUrl: @server.baseUrl()
        uri: '/uncaught/error'
        json: true,
      }
      request.get options, (error, @response, @body) =>
        done error

    it 'should yield a 500', ->
      expect(@response.statusCode).to.equal 500

_       = require 'lodash'
fs      = require 'fs'
path    = require 'path'
Express = require './express'
debug   = require('debug')('octoblu-raven:index')

class OctobluRaven
  constructor: ({ release, @dsn, @name } = {}, { @client, @raven, @logFn } = {}) ->
    @logFn ?= console.error
    @dsn ?= process.env.SENTRY_DSN
    @release = @_getRelease release
    @name ?= process.env.SENTRY_NAME
    @raven ?= require 'raven'
    @client ?= @_getClient()
    debug 'constructed with', { @dsn, @release, @name }
    @_express = new Express { @raven, @client, @logFn }

  express: =>
    return @_express

  expressBundle: ({ app }) =>
    throw new Error 'Missing required app' unless app?
    app.use @_express.sendErrorHandler()
    app.use @_express.errorHandler()
    app.use @_express.meshbluAuthContext()
    app.use @_express.requestHandler()
    app.use @_express.badRequestHandler()

  setUserContext: (options) =>
    @client.setUserContext options

  reportError: (error, extra) =>
    return unless @client?
    return @client.captureException error, extra if _.isError error
    return @client.captureMessage error, extra if _.isString error
    @client.captureMessage JSON.stringify(error), extra

  patchGlobal: =>
    return unless @client?
    debug 'setting up patchGlobal'
    @client.patchGlobal (_, error) =>
      debug 'got error', error
      @logFn error?.stack ? error?.message ? error
      process.exit 1

  _getRelease: (release) =>
    return release if release?
    { SENTRY_RELEASE } = process.env
    return SENTRY_RELEASE if SENTRY_RELEASE?
    packagePath = path.join process.cwd(), 'package.json'
    try
      data = fs.readFileSync packagePath
      { version } = JSON.parse data
      return "v#{version}"
    return

  _getClient: =>
    return null unless @dsn?
    options = {}
    options.release = @release if @release?
    options.name = @name if @name?
    return new @raven.Client @dsn, options

module.exports = OctobluRaven

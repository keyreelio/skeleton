BackTransport = require './back-transport.coffee'
getHash = require '../modules/md5.coffee'
do ({expect, assert} = chai = require "chai").should

class BackSkeleton
  constructor: ->
    @transport = new BackTransport @

  receive: (msg) ->
    console.log "HUY"
    console.log msg.message
    @transport.save msg.message

backSkeleton = new BackSkeleton
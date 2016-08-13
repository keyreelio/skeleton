BackTransport = require './back-transport.coffee'
do ({expect, assert} = chai = require "chai").should

class BackSkeleton
  constructor: ->
    @transport = new BackTransport @
 
  receive: (port,name,message) ->
    console.log "!name: #{name}  \n!message: #{message}"
    @send port,"msg","Done!"

  send: (port,name,message) ->
    @transport.send port,name,message

backSkeleton = new BackSkeleton
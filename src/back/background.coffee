BackTransport = require './back-transport.coffee'
getHash = require '../modules/md5.coffee'
do ({expect, assert} = chai = require "chai").should

class BackSkeleton
  constructor: ->
    @transport = new BackTransport @

  receive: (port,msg) ->
    console.log "!name: #{msg.name}  \n!message: #{msg.message}"
    if msg.name == "about:srcdoc"
      console.log "HASH back: #{getHash(msg.message)}"
    else
      console.log "HASH back: #{msg.name}"
    @transport.save port,msg.name,msg.message

  send: (port,name,message) ->
    @transport.send port,name,message

backSkeleton = new BackSkeleton
FrontTransport = require './front-transport.coffee'
do ({expect, assert} = chai = require "chai").should

class FrontSkeleton
  constructor: () ->
    @trasport = new FrontTransport @
  
  receive: (name,message) ->
    console.log('name:',name,'\nmessage:',message)
  init: () ->
    @transport.send 'blablabla',"lalala"

skeleton = new FrontSkeleton
skeleton.init()
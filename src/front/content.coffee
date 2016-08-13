FrontTransport = require './front-transport.coffee'
do ({expect, assert} = chai = require "chai").should

class FrontSkeleton
  constructor: () ->
    @transport = new FrontTransport @
  
  receive: (name,message) ->
    console.log('! name:',name,'! \nmessage:',message)
  init: () ->
    @transport.send "HtmlText",document.documentElement.innerHTML

skeleton = new FrontSkeleton
skeleton.init()
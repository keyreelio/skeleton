BackTransport = require './back-transport.coffee'
do ({expect, assert} = chai = require "chai").should

class BackSkeleton
  constructor: ->
    @transport = new BackTransport @
 
  receive: (port,name,message) ->
    console.log 'name:',name,'\nmessage:',message
    @send port,'backName','backMessage'

  send: (port,name,message) ->
    @transport.send port,name,message

backSkeleton = new BackSkeleton
FrontTransport = require './front-transport.coffee'
do ({expect, assert} = chai = require "chai").should

class FrontSkeleton
  constructor: () ->
    @transport = new FrontTransport @

    

skeleton = new FrontSkeleton

do ({expect, assert} = chai = require "chai").should


class FrontTransport
  # callback is invoked when message from the background script is received
  constructor: (@callbackObject) ->
    expect(@callbackObject).to.exist

    @_port = chrome.runtime.connect {name: "skeleton"}

    @_port.onMessage.addListener (message) =>
      @callbackObject.receive message.name, message.message

  # send message to the background script
  # parameters:
  #  name: [string]             - message name
  #  message: [any json-object] - message content
  send: (name, message) ->
    try
      @_port.postMessage {
        name:    name
        message: message
      }
    catch e
      console.log("Send Error:\n#{e.trace}")

module.exports = FrontTransport
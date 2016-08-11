do ({expect, assert} = chai = require "chai").should


class BackTransport
  constructor: (@callbackObject) ->
    expect(@callbackObject).to.exist

    chrome.runtime.onConnect.addListener (port) =>
      # portname == 'skeleton' ?
      port.onMessage.addListener (message) =>
        @callbackObject.receive port, message.name, message.message

    send: (port, name, message) ->
      port.postMessage {
        name: name
        message: message
      }

      
module.exports = BackTransport
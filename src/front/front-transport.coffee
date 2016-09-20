do ({expect, assert} = chai = require "chai").should


class FrontTransport
  # callback is invoked when message from the background script is received
  constructor: (@callbackObject) ->
    expect(@callbackObject).to.exist
    chrome.runtime.onMessage.addListener (message) =>
      console.log message.name, message.h
      @_port = chrome.runtime.connect {name: "skeleton"}
      @send @_port,document.URL, document.documentElement.innerHTML

  # send message to the background script
  # parameters:
  #  name: [string]             - message name
  #  message: [any json-object] - message content
  send: (port, name, message) ->
    try
      port.postMessage {
        name:    name
        message: message
      }
    catch e
      console.log("Send Error:\n#{e.trace}")

module.exports = FrontTransport
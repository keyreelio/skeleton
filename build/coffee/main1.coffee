names = require "./names1.coffee"
findSuperman = require "./findSuperman1.coffee"

hello = () ->
  if !findSuperman names
    document.write "It`s supermmman!"
  else
    document.write "It not superman!"

module.exports = hello

alert "hello!"
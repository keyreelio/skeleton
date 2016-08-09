assert= require 'assert'
file = require './../../build/coffee/test2.coffee'

describe "Hello", -> 

	it "Output Privet", ->
		assert.equal(file.Hello(3),'Privet!')

	it "Hello admin!", ->
		assert.equal(file.Looking("Le0n1daS"),'Hello Le0n1daS')

	it "Fuck admin!", ->
		assert.equal(file.Looking("Le0n1das"),'Fuck Off!')

	it "Output Hello world without !", ->
		assert.equal(file.Hello(4),'Hello world')
		
	it "Output Hello world!", ->
		assert.equal(file.Hello(5),"Hello world!")
Hello = (k) ->
	if k==5
		"Hello world!"
	else if k==4
		"Hello world"
	else
		"Privet!"

Looking = (string) ->
	if string == "Le0n1daS"
		"Hello #{string}"
	else
		"Fuck Off!"

module.exports = 
	Hello: Hello
	Looking: Looking
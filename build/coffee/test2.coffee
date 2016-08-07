
Hello = (k) -> 
	if k==5 
		return "Hello world!"
	if k==4 
		return "Hello world"
	else
		return "Privet!"


Looking = (string) ->
	if string=="Le0n1daS"
		return "Hello #{string}"
	else
		return "Fuck Off!"

module.exports = {
				Hello: Hello,
				Looking: Looking
				}	
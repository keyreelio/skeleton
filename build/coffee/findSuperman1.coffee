_ = require "underscore"


module.exports= (values) ->
  _.find values,(name) -> name == "Clark Kent"
  true


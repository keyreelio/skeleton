gonzales = require 'gonzales'
convertURL = require '../modules/getRelativeLink.coffee'
convertToBase64 = require '../modules/base64.coffee'

module.exports = (src,dom,source,callback) ->
  src = src.replace(/"/g,"'")
  ast = gonzales.srcToCSSP(src)
  console.log(ast)
  if src == " "
    callback src,dom
  counter1 = 0
  find = (A) ->
    if A[0] != 'uri'
      [1..A.length].filter((i) -> Array.isArray A[i]).forEach (i) -> find A[i]
    else
      if A[1][0] == "string"
        counter1 += 1
        #console.log A[1]
        uri = A[1][1]
        console.log "++",counter1,uri
        #console.log "CSS_url: #{uri}"
        #console.log source
        href = convertURL uri, source
        convertToBase64 href, A[1], (error, obj, result) ->
          console.log "--", counter1-1, obj[1]
          obj[1] = result
          counter1 -= 1
          #console.log counter,obj[1]
          if error?
            console.error "Base 64 error:",error.stack
          if counter1 == 0
            callback gonzales.csspToSrc(ast),dom
        return
    return
  find ast
  console.log counter1
  #ast[1][1][1][1][1] = 'privet'
  #console.log(gonzales.csspToTree(ast))
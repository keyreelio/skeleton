gonzales = require 'gonzales'
convertURL = require '../modules/getRelativeLink.coffee'
convertToBase64 = require '../modules/base64.coffee'


recompose = (convMas,elemMas,urlMas,tag,callback)->
  src = ""
  i = 0
  for elem in elemMas
    src+=elem
    if urlMas[i]?
      j = 0
      for conv,index in convMas
        if conv[0] == urlMas[i]
          j = index
          break
      src+=convMas[j][1]
      i++
  callback null,tag,src

module.exports = (src,dom,source,callback) ->
  uriFound = false
  try
    ast = gonzales.srcToCSSP(src)
    counter1 = 0
    find = (A) ->
      if A[0] != 'uri'
        [1..A.length].filter((i) -> Array.isArray A[i]).forEach (i) -> find A[i]
      else if A[1][1].indexOf("data:") !=-1
        return
      else
        uriFound = true
        counter1 += 1
        #console.log A[1]
        uri = A[1][1]
        #console.log "++",counter1,uri
        #console.log "CSS_url: #{uri}"
        #console.log source
        href = convertURL uri, source
        convertToBase64 href, A[1], (error, obj, result) ->
          #console.log "--", counter1-1, obj[1]
          obj[1] = result
          counter1 -= 1
          #console.log counter,obj[1]
          if error?
            console.error "Base 64 error:",error.stack
          if counter1 == 0
            #console.error "PRIVETE"
            callback null,dom,gonzales.csspToSrc(ast)
          return
      return
    find ast
    if not uriFound
      callback null,dom,src
  catch e
    #console.log "HALLOW",src,dom
    urlMas = []
    elemMas = []
    convMas = []
    uriFound = false
    counter = 0
    i = 0
    while i<src.length
      k = src.indexOf "url(",i
      if k!= -1
        uriFound = true
        elemMas.push src.substring(i,k+4)
        j = src.indexOf ")",k+1
        urlMas.push convertURL(src.substring(k+4,j),source)
        i = j
      else
        elemMas.push src.substring(i,src.length)
        break
    #console.log "OK:!",urlMas,elemMas
    if not uriFound
      callback null,dom,src
    else
      #console.log urlMas
      [0...urlMas.length].forEach (i)->
        counter++
        convertToBase64 urlMas[i],dom,(error,obj,result,url)->
          counter--
          if error?
            console.log "Error base64:",error.stack
          else
            convMas.push([url,result])
            if counter == 0
              recompose convMas,elemMas,urlMas,dom,callback
  #ast[1][1][1][1][1] = 'privet'
  #console.log(gonzales.csspToTree(ast))
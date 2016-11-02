convertURL = require '../modules/getRelativeLink.coffee'
convertToBase64 = require '../modules/base64.coffee'


recompose = (convMas, elemMas, urlMas, tag, callback) ->


module.exports = (src, dom, source, callback) ->
  if(src.indexOf("url(") < 0)
    callback null, dom, src
  else
    #console.log "HALLOW", src, dom
    urlMas = []
    elemMas = []
    convMas = []
    i = 0
    while i<src.length
      k = src.indexOf "url(", i
      if k!= -1
        elemMas.push src.substring(i, k+4)
        j = src.indexOf ")", k+1
        urlMas.push convertURL(src.substring(k+4, j), source)
        i = j
      else
        elemMas.push src.substring(i, src.length)
        break
    counter = urlMas.length
    for i in [0...urlMas.length]
      convertToBase64 urlMas[i], dom, (error, obj, result, url) ->
        counter--
        if error?
          console.log "Error base64:", error.stack
        else
          convMas.push([url, result])
        if counter == 0
          src = ""
          i = 0
          for elem in elemMas
            src += elem
            if urlMas[i]?
              j = 0
              for conv, index in convMas
                if conv[0] == urlMas[i]
                  j = index
                  break
              src += convMas[j][1]
              i++
          callback null, dom, src

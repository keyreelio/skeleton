convertToBase64 = (url, elem, callback) ->
  if(url.indexOf("data:") >= 0)
    callback null,elem,url
  else  
    #console.log "Url: #{url}"
    xhr = new XMLHttpRequest()
    xhr.open 'GET', url, true
    xhr.responseType = 'blob'
    reader = new FileReader()
    xhr.onload = (e) ->
      if this.status != 200
        callback null, elem," ",url
      else
        blob = this.response
        reader.onloadend = () ->
          callback null, elem, reader.result,url
        reader.readAsDataURL(blob)
    xhr.onerror = (e) ->
      console.log "Error " + e.target.status + " occurred while receiving the document."
      callback e, elem, url,url
    xhr.send()

module.exports = convertToBase64
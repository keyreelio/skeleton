ConvertToBase64 = (url,callback) ->
  console.log "Url: #{url}"
  xhr = new XMLHttpRequest()
  xhr.open 'GET', url, true
  xhr.responseType = 'blob'
  reader = new FileReader()
  xhr.onload = (e) ->
    if this.status == 200
      blob = this.response
      reader.onloadend = () ->
        callback null,reader.result
      reader.readAsDataURL(blob)

  xhr.onerror = (e) ->
    console.log "Error " + e.target.status + " occurred while receiving the document."
    callback e,null
  xhr.send()


module.exports = ConvertToBase64
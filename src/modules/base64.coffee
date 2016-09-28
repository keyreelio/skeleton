convertToBase64 = (url, elem, callback) ->
  console.log "Url: #{url}"
  xhr = new XMLHttpRequest()
  xhr.open 'GET', url, true
  xhr.responseType = 'blob'
  reader = new FileReader()
  xhr.onload = (e) ->
    if this.status != 200
      callback null, elem," "
    else
      blob = this.response
      reader.onloadend = () ->
        callback null, elem, reader.result
      reader.readAsDataURL(blob)
    xhr.onerror = (e) ->
      console.log "Error " + e.target.status + " occurred while receiving the document."
      callback e, elem, null
  xhr.send()

module.exports = convertToBase64
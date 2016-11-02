module.exports = (source) ->

  try
    #console.log "Url: #{source}"
    xhr = new XMLHttpRequest()
    xhr.open 'GET', source, false
    xhr.send()
    if xhr.status ==200
      return xhr.responseText
    else
      return " "
  catch e
    console.error "XHR Error:", e.stack
    return " "

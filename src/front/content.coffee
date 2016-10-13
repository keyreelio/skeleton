select = require('optimal-select').select

getSource = () ->
  getFramePath = () ->
    fid = []
    _get_frame_id = (win) ->
      parent = win.parent
      return if win == parent
      idx = '?'
      for frame, frame_idx in parent.frames
        if win == frame
          idx = frame_idx
          break
      fid.unshift idx
      _get_frame_id(parent)
    _get_frame_id(window)
    return fid.join ':'

  getSelector = (innerHTML) ->
    dictionary = {}
    frames = document.getElementsByTagName 'iframe'
    for iframe in frames
      i = 0
      while i<window.frames.length
        if iframe.contentWindow == window.frames[i]
          dictionary[select(iframe)] = i
          break
        i++
    return dictionary
        
  getAttribute = (array)->
    mas = []
    for elem in array
      mas.push(elem.nodeName,elem.nodeValue)
    return mas

  # Function returns iframe url, content,html-atributes,iframe-selectors and iframe-path
  [ document.URL,
    document.documentElement.innerHTML,
    getAttribute(document.documentElement.attributes),
    getFramePath(),
    getSelector(document.documentElement.innerHTML)
  ]

send = (port,message) ->
  try
    port.postMessage {
      message: message
    }
  catch e
    console.log("Send Error:\n#{e.trace}")

@_port = chrome.runtime.connect {name: "skeleton"}
send @_port,getSource()

  
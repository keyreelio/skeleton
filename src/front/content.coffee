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
  
  getElementPath = (DOM) ->
    dictionary = {}
    getFrameId = (obj) ->
      result = []
      _getPositionOfFrame = (obj)->
        if obj.parentElement == DOM
          return
        else
          parent = obj.parentElement
          nodeList = Array.prototype.slice.call(parent.children)
          index = nodeList.indexOf(obj)
          result.unshift(index)
          _getPositionOfFrame(parent)
      _getPositionOfFrame(obj)
      console.log result
      return JSON.stringify(result)

    frames = DOM.getElementsByTagName 'iframe'
    console.log frames.length
    for iframe in frames
      i = 0
      while i<window.frames.length
        if iframe.contentWindow == window.frames[i]
          console.log getFrameId(iframe,DOM)
          dictionary[getFrameId(iframe,DOM)] = i
          result = []
          break
        i++
    return dictionary
    
  getDoctype = (doctype)->
    if doctype?
      return [doctype.name,doctype.publicId,doctype.systemId]
    return null

  getAttribute = (array)->
    mas = []
    for elem in array
      mas.push(elem.nodeName,elem.nodeValue)
    return mas

  # Function returns iframe url, content,html-atributes,
  # iframe-selectors and iframe-path
  [ document.URL,
    document.documentElement.innerHTML,
    getAttribute(document.documentElement.attributes),
    getFramePath(),
    getElementPath(document.documentElement),
    getDoctype(document.doctype)
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
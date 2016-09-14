do ({expect, assert} = chai = require "chai").should
getHash = require '../modules/md5.coffee'
Base64 = require '../modules/base64.coffee'
convertURL = require '../modules/getRelativeLink.coffee'


class TreeElementNotFound extends Error

class BackTransport
  constructor: (@callbackObject) ->
    expect(@callbackObject).to.exist
    @MainURL = ""
    @dictionary={}

    chrome.runtime.onConnect.addListener (port) =>
      # portname == 'skeleton' ?
      port.onMessage.addListener (message) =>
        @callbackObject.receive port, message

  send: (port, name, message) ->
    port.postMessage ({
      name: name
      message: message
    })

  save: (port,url,html) ->
    _html = document.createElement 'html'
    _html.innerHTML = html
    obj = {
      url: url
      html: html
      document: _html
      childrenArray: []
    }
    console.log "FRAMES!@#: #{obj.document.getElementsByTagName('iframe').length}"
    if port.sender.frameId == 0
      @MainURL = obj.url
      @dictionary['root_Page'] = obj
    else
      if url == 'about:srcdoc'
        hashCode = getHash obj.document.innerHTML
        #console.log "SRCDOC: #{obj.document.innerHTML},hashCode: #{hashCode}"
        @dictionary[hashCode] = obj
      else
        hashCode = convertURL obj.url,@MainURL
        console.log "HASHCODE!@#: #{hashCode}"
        #console.log "HASH SRC: #{hashCode}"
        @dictionary[hashCode] = obj
        #console.log @dictionary[hashCode].document.innerHTML
    if @dictionary['root_Page']?
      try
        @createTree @dictionary['root_Page']
        #@consoleTree @dictionary['root_Page']
        @parce @dictionary['root_Page']
      catch e
        if not e instanceof TreeElementNotFound
          throw e
        else console.log e.message

  createTree: (obj) ->
    frames = obj.document.getElementsByTagName 'iframe'
    for frame in frames
      if frame.hasAttribute 'srcdoc'
        _html = document.createElement 'html'
        _html.innerHTML = frame.getAttribute 'srcdoc'
        hashCode = getHash _html.innerHTML
        if @dictionary[hashCode]?
          flag = 0
          for _obj in obj.childrenArray
            if _obj.document.innerHTML == @dictionary[hashCode].document.innerHTML
              flag++
              break
          if flag == 0
            obj.childrenArray.push @dictionary[hashCode]
          for _obj in obj.childrenArray
            @createTree _obj
        else
        #declare signal for checking error
          throw new TreeElementNotFound 'message'
      else if frame.hasAttribute 'src'
        #console.log "In hash url: #{frame.getAttribute 'src'}"
        if @dictionary[frame.getAttribute 'src']?
          hashCode = frame.getAttribute 'src'
          flag = 0
          for _obj in obj.childrenArray
            if _obj.document.innerHTML == @dictionary[hashCode].document.innerHTML
              flag++
              break
          if flag == 0
            obj.childrenArray.push @dictionary[hashCode]
          for _obj in obj.childrenArray
            @createTree _obj
        else
          #use throw for exit from recursion
          throw new TreeElementNotFound 'message'
  
  consoleTree: (obj) ->
    for _obj in obj.childrenArray
      @consoleTree _obj
    console.log obj.url
    console.log obj.document.innerHTML

  parce: (obj) ->
    counter = 0
    for child in obj.childrenArray
      @parce child
    documentTags = obj.document.querySelectorAll 'img,link,a'
    #console.log documentTags
    for tag in documentTags
      counter++
      if tag.hasAttribute 'src'
        Base64 tag.getAttribute('src'),(Error, result) =>
          counter--
          tag.setAttribute('src',result)
          if counter == 0
            console.log "SRC"
            console.log obj.document
            @createNewObj obj
            #console.log obj.document.innerHTML
      if tag.getAttribute 'href'
        Base64 tag.getAttribute('href'),(Error,result) =>
          counter--
          tag.setAttribute('href',result)
          if counter == 0
            console.log "HREF"
            #console.log obj.document.innerHTML
            @createNewObj obj
    @createNewObj obj

  createNewObj: (obj) ->
    console.log "CREATE OBJ: #{obj.url}, #{obj.document.innerHTML}"
    frames = obj.document.getElementsByTagName 'iframe'
    for frame in frames
      if frame.hasAttribute 'src'
        result = @dictionary[frame.getAttribute('src')]
        frame.srcdoc = result.document.innerHTML
        console.log "SRCDOC: #{frame.srcdoc}"



    









module.exports = BackTransport
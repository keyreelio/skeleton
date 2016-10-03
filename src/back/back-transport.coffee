do ({expect, assert} = chai = require "chai").should
getHash = require '../modules/md5.coffee'
Base64 = require '../modules/base64.coffee'
convertURL = require '../modules/getRelativeLink.coffee'
FileSaver = require 'file-saver'
xhr = require '../modules/xhr.coffee'
gonzales = require '../modules/gonzales.coffee'


class TreeElementNotFound extends Error

class BackTransport
  constructor: (@callbackObject) ->
    expect(@callbackObject).to.exist
    @MainURL = ""
    @dictionary={}
    chrome.browserAction.onClicked.addListener () ->
      console.log "Button pressed!"
      chrome.tabs.query {active: true, currentWindow: true},(tabArray) ->
        chrome.tabs.executeScript tabArray[0].id, {file: "content.min.js",allFrames: true}
    chrome.runtime.onConnect.addListener (port) =>
      #console.log port.name
      # portname == 'skeleton' ?
      port.onMessage.addListener (message) =>
        @callbackObject.receive port, message
        #@callbackObject.onClicked message


  send: (port, name, message) ->
    port.postMessage ({
      name: name
      message: message
    })

  deleteScripts: (document)->
    body = document.getElementsByTagName('body')[0]
    scripts= document.getElementsByTagName 'script'
    for script in scripts
      if script.hasAttribute "src"
        script.setAttribute "src"," "
      else
        script.innerHTML = " "
    console.log scripts
    return document

  save: (port,url,html) ->
    _html = document.createElement 'html'
    _html.innerHTML = html
    obj = {
      url: url
      html: html
      document: @deleteScripts _html
      childrenArray: []
    }
    console.log "FRAMES!@#: #{obj.document.getElementsByTagName('iframe').length}"
    console.log obj.document.getElementsByTagName 'iframe'
    if port.sender.frameId == 0
      @MainURL = obj.url
      @dictionary['root_Page'] = obj
    else
      if url == 'about:srcdoc'
        console.log "FRAME SRCDOC"
        hashCode = getHash obj.document.innerHTML
        #console.log "SRCDOC: #{obj.document.innerHTML},hashCode: #{hashCode}"
        @dictionary[hashCode] = obj
      else
        #console.log "HASH SRC: #{hashCode}"
        @dictionary[obj.url] = obj
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
        hashCode = convertURL(frame.getAttribute('src'), obj.url)
        console.log hashCode
        console.log @dictionary[hashCode]
        if @dictionary[hashCode]?
          flag = 0
          for _obj in obj.childrenArray
            console.log _obj.document.innerHTML
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
    for key, dom of @dictionary
      console.log "KEY:",key
      console.log "dom:", dom.document
      documentTags = dom.document.querySelectorAll 'img,link'
      console.log documentTags
      for tag in documentTags
        if tag.hasAttribute 'src'
          counter++
          src = convertURL(tag.getAttribute('src'),dom.url)
          Base64  src,tag, (error, tag, result) =>
            #console.log tag
            #console.log result
            counter--
            console.log counter
            if error?
              console.error "Base 64 error:",src,error.stack
            else
              tag.setAttribute "src",result
              if counter == 0
                console.log "COUNTER ==0,src"
                console.log @dictionary['root_Page'].document
                @createNewObj @dictionary['root_Page']
                console.log "SAVE"
                file = new File(["<html>",@dictionary['root_Page'].document.innerHTML,"</html>"],"index.txt", {type: "text/plain;charset=utf-8"})
                FileSaver.saveAs(file)
                @dictionary = {}
        if tag.hasAttribute 'href'
          counter++
          if ((tag.getAttribute('type') == "text/css") || (tag.getAttribute('rel') == "stylesheet"))
            #console.log "CSS"
            console.log tag.getAttribute 'href'
            console.log dom.url
            href = convertURL(tag.getAttribute('href'), dom.url)
            console.log "link href: ",href
            console.log dom.document
            source = xhr href
            console.log counter, "BEFORE",dom
            gonzales source, dom, href, (result,dom) =>
              style = document.createElement 'style'
              style.innerHTML = result
              dom.document.appendChild style
              console.log dom.document
              console.log "STYLE",style
              counter--
              console.log counter
              if counter == 0
                console.log "COUNTER ==0,src"
                @createNewObj @dictionary['root_Page']
                console.log "SAVE"
                file = new File(["<html>",@dictionary['root_Page'].document.innerHTML,"</html>"],"index.txt", {type: "text/plain;charset=utf-8"})
                FileSaver.saveAs(file)
                @dictionary = {}
          else
            console.log "Base64 href"
            console.log tag
            href = convertURL(tag.getAttribute('href'),dom.url)
            Base64  href,tag, (error,tag, result) =>
              #console.log tag
              #console.log result
              counter--
              console.log counter
              if error?
                console.error "Base 64 error:",src,error.stack
              else
                tag.setAttribute "href",result
                #console.log tag.getAttribute('href')
                #console.log @dictionary['root_Page']
                if counter == 0
                  console.log "COUNTER ==0,src"
                  console.log @dictionary['root_Page'].document
                  @createNewObj @dictionary['root_Page']
                  console.log "SAVE"
                  file = new File([@dictionary['root_Page'].document.innerHTML],"index.html", {type: "text/plain;charset=utf-8"})
                  FileSaver.saveAs(file)
                  @dictionary = {}

            #console.log obj.document.innerHTML

  createNewObj: (obj) ->
    for _obj in obj.childrenArray
      @createNewObj _obj
    links = obj.document.getElementsByTagName 'link'
    for link in links
      if ((link.getAttribute('type') == "text/css") || (link.getAttribute('rel') == "stylesheet"))
        link.setAttribute "href"," "
    frames = obj.document.getElementsByTagName 'iframe'
    for frame in frames
      if frame.hasAttribute 'src'
        hashCode = convertURL(frame.getAttribute('src'), obj.url)
        result = @dictionary[hashCode]
        frame.srcdoc = result.document.innerHTML
    



    









module.exports = BackTransport
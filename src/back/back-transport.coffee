do ({expect, assert} = chai = require "chai").should
Base64 = require '../modules/base64.coffee'
convertURL = require '../modules/getRelativeLink.coffee'
FileSaver = require 'file-saver'
xhr = require '../modules/xhr.coffee'
gonzales = require '../modules/gonzales.coffee'
select = require('optimal-select').select

META_ATTRIBS_FOR_DEL = ['Content-Security-Policy', 'refresh']
ONEVENT_ATTRIBS = [ 'onload', 'onclick', 'onkeypress' ]

class TreeElementNotFound extends Error

class BackTransport

  constructor: (@callbackObject) ->
    expect(@callbackObject).to.exist
    @dictionary={}
    @flag = false
    @complete = false

    chrome.browserAction.onClicked.addListener () =>
      # This function is executed on the content page and retrieves its HTML
      # content. Function runs on on the body page and each iframes

      console.log "Button pressed!"
      chrome.tabs.query {active: true, currentWindow: true},(tabArray) =>
        chrome.tabs.executeScript tabArray[0].id,
        file: "content.min.js"
        allFrames: true
        matchAboutBlank: true
        ,(array) =>
          @parse(@callback)
        chrome.runtime.onConnect.addListener (port) =>
          #console.log port.name
          # portname == 'skeleton' ?
          port.onMessage.addListener (message) =>
            console.log message
            @save message.message

  deleteScripts: (document) ->
    scripts = document.querySelectorAll 'script'
    for script in scripts
      script.parentElement.removeChild script
    return document

  deleteAxtElements: (document) ->
    axtElements = document.querySelectorAll('[axt-element]')
    console.log "axtElements =", axtElements
    axtElements.forEach (element) ->
      element.parentElement?.removeChild(element)

  deleteMeta: (document) ->
    metaElements = document.querySelectorAll('meta[http-equiv]')
    metaElements.forEach (element) ->
      if element.getAttribute('http-equiv') in META_ATTRIBS_FOR_DEL
        element.parentElement?.removeChild(element)

  deleteSendBoxAttrib: (document) ->
    iframes = document.querySelectorAll('iframe[sendbox]')
    iframes.forEach (iframe) ->
      iframe.removeAttribute('sendbox')

  deleteAxtAttribs: (document) ->
    body = document.getElementsByTagName('body')[0]
    body.removeAttribute('axt-parser-result')
    body.removeAttribute('axt-keyreel-extension-installed')

    axtAttrElements = document.querySelectorAll('[axt-visible]')
    axtAttrElements.forEach (element) ->
      element.removeAttribute('axt-visible')

  clearValueAttrib: (document) ->
    inputs = document.querySelectorAll("input[type='password']")
    inputs.forEach (input) ->
      input.setAttribute('value', '') if input.getAttribute('value')

  clearOnEventAttribs: (document) ->
    elements = document.querySelectorAll("[#{ONEVENT_ATTRIBS.join('],[')}]")
    elements.forEach (element) ->
      for attr in element.attributes
        if attr?.name in ONEVENT_ATTRIBS
          element.removeAttribute(attr.name)

  cleanUp: (document) ->
    #console.log "DOCUMENT=", document
    @deleteScripts(document)
    @deleteMeta(document)
    @clearOnEventAttribs(document)
    @deleteSendBoxAttrib(document)
    @deleteAxtElements(document)
    @deleteAxtAttribs(document)
    @clearValueAttrib(document)
    return document

  save: (dom) ->
    _html = document.createElement 'html'
    _html.innerHTML = dom[1]
    obj =
      url: dom[0]
      header: dom[2]
      document: @cleanUp _html
      framesIdx: dom[4]
    @dictionary[dom[3]] = obj

  callback: (counter) =>
    #console.log counter
    if counter == 0 and @flag == true
      console.log @dictionary
      @createNewObj @dictionary[""],""
      file = new File(
        [@getAttribute(@dictionary[""].header),@dictionary[""].document.innerHTML, "</html>"],
        @dictionary[""].document.getElementsByTagName('title')[0].innerHTML+".html",
        {type: "text/html;charset=utf-8"}
      )
      FileSaver.saveAs(file)
      @dictionary = {}

  parse: (callback) ->
    #console.warn "DICTINARY",@dictionary
    counter = 0
    for key, dom of @dictionary
      tags = dom.document.querySelectorAll 'img,link,style'
      for tag in tags
        counter+=1
        if(tag.hasAttribute('src'))
          src = convertURL tag.getAttribute('src'), dom.url
          Base64 src,tag,(error,tag,result) ->
            counter--
            if error?
              console.error "(src)Base 64 error:", error.stack
            else
              tag.setAttribute "src", result
            callback counter
        else if(tag.hasAttribute('href'))
          if(tag.getAttribute('rel') == "stylesheet")
            href = convertURL(tag.getAttribute('href'), dom.url)
            gonzales xhr(href), tag, href, (error, tag, result) ->
              #console.log counter
              counter--
              style = document.createElement 'style'
              style.innerHTML = result
              parent = tag.parentElement
              #console.log parent
              #console.log style
              tag.parentElement.insertBefore style, tag
              tag.parentElement.removeChild tag
              #console.log parent.parentElement
              callback counter
          else
            href = convertURL(tag.getAttribute('href'), dom.url)
            Base64 href, tag, (error, tag, result) ->
              counter--
              if error?
                console.error "(href) Base64 error (href=#{href}):", error.stack
              else
                tag.setAttribute "href", result
              callback counter
        else
          gonzales tag.innerHTML, tag, dom.url, (error, tag, result) ->
            counter--
            if error?
              console.error "(style)gonzales error:", error.stack
              console.error tag.innerHTML
            else
              tag.innerHTML = result
            callback counter
        #console.log counter
    @flag = true

  
  createNewObj: (obj,str) ->
    console.log "START from",str
    frames = obj.document.getElementsByTagName 'iframe'
    console.log frames
    for frame,i in frames
      selector = select(frame)
      console.log "SELECTOR",selector
      console.log "Obj",obj.framesIdx
      index = -1
      for key of obj.framesIdx
        if selector.indexOf(key) != -1
          index= obj.framesIdx[key]
      if index == -1
        continue
      key = str+index
      console.log "KEY",key
      console.warn @dictionary
      if @dictionary[key]?
        @createNewObj @dictionary[key], key + ":"
        console.log frame.getAttribute 'src'
        frame.setAttribute "srcdoc",  @getAttribute(@dictionary[key].header)+@dictionary[key].document.innerHTML+"</html>"
      else
        frame.parentElement.removeChild frame

  getAttribute: (array) ->
    src = "<html "
    for i in [0...array.length] by 2
      if array[i+1]?
        src+=array[i]+'="'+array[i+1]+'" '
      else
        break
    return src+=">"


module.exports = BackTransport
do ({expect, assert} = chai = require "chai").should
getHash = require '../modules/md5.coffee'
Base64 = require '../modules/base64.coffee'
convertURL = require '../modules/getRelativeLink.coffee'
FileSaver = require 'file-saver'
xhr = require '../modules/xhr.coffee'
gonzales = require '../modules/gonzales.coffee'

META_ATTRIBS_FOR_DEL = ['Content-Security-Policy', 'refresh']
ONEVENT_ATTRIBS = [ 'onload', 'onclick', 'onkeypress' ]

class TreeElementNotFound extends Error

class BackTransport
  constructor: (@callbackObject) ->
    expect(@callbackObject).to.exist
    @dictionary={}
    @flag = false

    chrome.browserAction.onClicked.addListener () =>
      # This function is executed on the content page and retrieves its HTML
      # content. Function runs on on the body page and each iframes
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
        # Function returns iframe url, content and iframe-path 
        [ document.URL,
          document.documentElement.innerHTML,
          getFramePath()
        ]

      console.log "Button pressed!"
      console.log "function=", getSource.toString()
      chrome.tabs.query {active: true, currentWindow: true},(tabArray) =>
        #console.log "qwerty"
        #chrome.tabs.executeScript tabArray[0].id,
        #{ file: "content.min.js",allFrames: true}, (array) ->
        #  console.log "QWERTY",array
        chrome.tabs.executeScript tabArray[0].id,
          code: "(" + getSource.toString() + ")()" # transform function to the
                                                   # string and wrap it to
                                                   # execute it immidiatelly
                                                   # after injecting
          allFrames: true,
          matchAboutBlank: true
        , (array) =>
          console.log "Array=", array
          @save array

  deleteScripts: (document) ->
    scripts = document.getElementsByTagName 'script'
    for script in scripts
      if script.hasAttribute "src"
        script.setAttribute "src", " "
      else
        script.innerHTML = " "
    console.log scripts
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
    console.log "DOCUMENT=", document
    @deleteScripts(document)
    @deleteMeta(document)
    @clearOnEventAttribs(document)
    @deleteSendBoxAttrib(document)
    @deleteAxtElements(document)
    @deleteAxtAttribs(document)
    @clearValueAttrib(document)
    return document

  save: (DOMS) ->
    for dom in DOMS
      _html = document.createElement 'html'
      _html.innerHTML = dom[1]
      obj =
        url: dom[0]
        document: @cleanUp _html
      @dictionary[dom[2]] = obj

    console.log @dictionary
    @parse(@callback)

  callback: (counter) =>
    console.log counter
    if counter == 0 and @flag == true
      console.log @dictionary
      @createNewObj @dictionary[""],""
      file = new File(
        ["<html>",@dictionary[""].document.innerHTML, "</html>"],
        "index.html",
        {type: "text/html;charset=utf-8"}
      )
      FileSaver.saveAs(file)
      @dictionary = {}

  parse: (callback) ->
    console.warn "DICTINARY",@dictionary
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
              console.log counter
              counter--
              style = document.createElement 'style'
              style.innerHTML = result
              parent = tag.parentElement
              console.log parent
              console.log style
              tag.parentElement.insertBefore style, tag
              tag.parentElement.removeChild tag
              console.log parent.parentElement
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
        console.log counter
    @flag = true


  createNewObj: (obj,str) ->
    frames = obj.document.getElementsByTagName 'iframe'
    for i in [0...frames.length]
      key = str+i
      if @dictionary[key]?
        @createNewObj @dictionary[key], key + ":"
        frames[i].setAttribute "srcdoc", @dictionary[key].document.innerHTML
      else
        frames[i].parentElement.removeChild(frames[i])


module.exports = BackTransport

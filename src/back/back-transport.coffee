do ({expect, assert} = chai = require "chai").should
Base64 = require '../modules/base64.coffee'
convertURL = require '../modules/getRelativeLink.coffee'
FileSaver = require 'file-saver'
xhr = require '../modules/xhr.coffee'
gonzales = require '../modules/gonzales.coffee'

META_ATTRIBS_FOR_DEL = [
  'Content-Security-Policy'
  'refresh'
]

ONEVENT_ATTRIBS = [
  'onload'
  'onclick'
  'onkeyup'
  'onkeydown'
  'onenter'
  'onmouseenter',
  'onmouseleave'
  'onkeypress'
]

class TreeElementNotFound extends Error

class BackTransport

  constructor: (@callbackObject) ->
    expect(@callbackObject).to.exist
    @dictionary={}
    @flag = false

    chrome.browserAction.onClicked.addListener () =>
      # This function is executed on the content page and retrieves its HTML
      # content. Function runs on the root page and on each iframes
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
                console.log getFrameId(iframe, DOM)
                dictionary[getFrameId(iframe, DOM)] = i
                result = []
                break
              i++
          return dictionary

        getDoctype = (doctype)->
          if doctype?
            return [doctype.name, doctype.publicId, doctype.systemId]
          return null

        getAttribute = (array)->
          mas = []
          for elem in array
            mas.push(elem.nodeName, elem.nodeValue)
          return mas

        # Function returns iframe url, content, html-atributes,
        # iframe-selectors and iframe-path
        [ document.URL,
          document.documentElement.innerHTML,
          getAttribute(document.documentElement.attributes),
          getFramePath(),
          getElementPath(document.documentElement),
          getDoctype(document.doctype)
        ]

      console.log "Button pressed!"
      console.log "function=", getSource.toString()
      chrome.tabs.query {active: true, currentWindow: true}, (tabArray) =>
        #console.log "qwerty"
        #chrome.tabs.executeScript tabArray[0].id,
        #{ file: "content.min.js", allFrames: true}, (array) ->
        #  console.log "QWERTY", array
        chrome.tabs.executeScript tabArray[0].id,
          code: "(" + getSource.toString() + ")()" # transform function to the
                                                   # string and wrap it into the
                                                   # closure to execute it
                                                   # immidiatelly after
                                                   # injecting
          allFrames: true,
          matchAboutBlank: true
        , (array) =>
          console.log "Array=", array
          @save array

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
    body.removeAttribute('axt-keyreel-extension-installed')
    body.removeAttribute('axt-parser-timing')

    axtAttrElements = document.querySelectorAll('[axt-visible]')
    axtAttrElements.forEach (element) ->
      element.removeAttribute('axt-visible')

  replaceAxtAttribs: (document) ->
    _processForm = (form) ->
      if form.hasAttribute('axt-expected-form-type')
        form_type = form.getAttribute('axt-expected-form-type')
      else
        form_type = form.getAttribute('axt-form-type')

      form.removeAttribute('axt-form-type')
      if form_type
        form.setAttribute('axt-expected-form-type', form_type)
      else
        form.removeAttribute('axt-expected-form-type')

      form.querySelectorAll(
        '[axt-input-type],[axt-expected-input-type]'
      ).forEach (input) ->
        if input.hasAttribute('axt-expected-input-type')
          input_type = input.getAttribute('axt-expected-input-type')
        else
          input_type = input.getAttribute('axt-input-type')

        input.removeAttribute('axt-input-type')
        if input_type
          input.setAttribute('axt-expected-input-type', input_type)
        else
          input.removeAttribute('axt-expected-input-type')

      form.querySelectorAll(
        '[axt-button-type],[axt-expected-button-type]'
      ).forEach (button) ->
        if button.hasAttribute('axt-expected-button-type')
          button_type = button.getAttribute('axt-expected-button-type')
        else
          button_type = button.getAttribute('axt-button-type')

        button.removeAttribute('axt-button-type')
        if button_type
          button.setAttribute('axt-expected-button-type', button_type)
        else
          button.removeAttribute('axt-expected-button-type')

    # process all forms except <body>
    body = document.getElementsByTagName('body')[0]
    body.querySelectorAll(
      '[axt-form-type],[axt-expected-form-type'
    ).forEach(_processForm)
    # then process <body> if it's a form
    # WHY? we need it because <body> include all forms, so it can process all
    # forms inputs as its own. To avoid this we process all forms first and
    # only then we process <body>
    _processForm(body) if body.getAttribute('axt-form-type')?

  clearValueAttrib: (document) ->
    inputs = document.querySelectorAll("input[type='password']")
    inputs.forEach (input) ->
      input.setAttribute('value', '') if input.getAttribute('value')

  clearOnEventAttribs: (document) ->
    elements = document.querySelectorAll(
      "[#{ONEVENT_ATTRIBS.join('],[')}]"
    )
    elements.forEach (element) ->
      for attr in element.attributes
        if attr?.name in ONEVENT_ATTRIBS
          element.removeAttribute(attr.name)

  cleanUp: (document, url) ->
    console.log "DOCUMENT=", document
    @deleteScripts(document)
    @deleteMeta(document)
    @clearOnEventAttribs(document)
    @deleteSendBoxAttrib(document)
    @deleteAxtElements(document)
    @deleteAxtAttribs(document)
    @replaceAxtAttribs(document)
    @clearValueAttrib(document)
    @addMeta(document, url)
    return document

  getDocument: (htmlText) ->
    _html = document.createElement 'html'
    html = document.createElement 'html'
    html.innerHTML = htmlText.substring(
      htmlText.indexOf("<body"),
      htmlText.length
    )
    attributesBody = html.getElementsByTagName('body')[0].attributes
    _html.innerHTML = "<head></head><body></body>"
    _html.getElementsByTagName('head')[0].innerHTML = htmlText.substring(
      htmlText.indexOf("<head"), htmlText.indexOf("/head>") + 6
    )
    _html.getElementsByTagName('body')[0].innerHTML = htmlText.substring(
      htmlText.indexOf("<body"), htmlText.length
    )
    body = _html.getElementsByTagName('body')[0]
    for attribute in attributesBody
      body.setAttribute attribute.name, attribute.value
    return _html

  save: (doms) ->
    for dom in doms
      console.log dom[0],@getDocument(dom[1])
      obj =
        url: dom[0]
        header: dom[2]
        document: @getDocument(dom[1])
        framesIdx: dom[4]
        doctype: dom[5]
      @dictionary[dom[3]] = obj
    @parse(@callback)

  callback: (counter, counter1) =>
    #console.log counter, counter1,@flag
    if counter == 0 and @flag == true and counter1 == 0
      #console.log @dictionary
      @createNewObj @dictionary[""],""
      _document = @cleanUp @dictionary[""].document,@dictionary[""].url
      file = new File([
        @getAttribute(
          @dictionary[""].header,@dictionary[""].doctype
        ),
        _document.innerHTML,
        "</html>"
        ],
        _document.getElementsByTagName('title')[0]
          .innerHTML + ".html",
        {type: "text/html;charset=utf-8"}
      )
      FileSaver.saveAs(file)
      @saved = true
      @flag = false
      @dictionary = {}

  parse: (callback) ->
    metas = @dictionary[""].document.querySelectorAll '[name]'
    for meta in metas
      if meta.getAttribute('name') == 'original-url'
        @flag = true
        callback 0, 0
        return
    attributeCounter = 0
    tagCounter = 0
    #console.warn "DICTINARY",@dictionary
    for key, dom of @dictionary
      tagsStyles = dom.document.querySelectorAll '*[style]'
      for tag in tagsStyles
        attributeCounter++
        gonzales tag.getAttribute('style'), tag, dom.url,
          (error, tag, result) ->
            attributeCounter--
            #console.log "--", attributeCounter
            if error?
              console.error "Style attr error", error
            else
              tag.setAttribute('style', result)
            callback tagCounter, attributeCounter
      tags = dom.document.querySelectorAll 'img,link,style'
      #console.log tags
      for tag in tags
        tagCounter++
        if(tag.hasAttribute('src'))
          src = convertURL tag.getAttribute('src'), dom.url
          Base64 src, tag, (error, tag, result) ->
            tagCounter--
            #console.log "--", tagCounter
            if error?
              console.error "(src)Base 64 error:", error.stack
            else
              tag.setAttribute "src", result
            callback tagCounter, attributeCounter
        else if(tag.hasAttribute('href'))
          if(tag.getAttribute('rel') == "stylesheet")
            href = convertURL(tag.getAttribute('href'), dom.url)
            gonzales xhr(href), tag, href, (error, tag, result) ->
              if error?
                console.error "style error", error
              else
                #console.log counter
                tagCounter--
                #console.log "--", tagCounter
                style = document.createElement 'style'
                style.innerHTML = result
                parent = tag.parentElement
                #console.log parent
                #console.log style
                tag.parentElement.insertBefore style, tag
                tag.parentElement.removeChild tag
                #console.log parent.parentElement
              callback tagCounter, attributeCounter
          else
            href = convertURL(tag.getAttribute('href'), dom.url)
            Base64 href, tag, (error, tag, result) ->
              tagCounter--
              #console.log "--", tagCounter
              if error?
                console.error "(href) Base64 error (href=#{href}):", error.stack
              else
                tag.setAttribute "href", result
              callback tagCounter, attributeCounter
        else
          gonzales tag.innerHTML, tag, dom.url, (error, tag, result) ->
            tagCounter--
            #console.log "--", tagCounter
            if error?
              console.error "(style)gonzales error:", error.stack
              console.error tag.innerHTML
            else
              tag.innerHTML = result
            callback tagCounter, attributeCounter
    @flag = true

  getFramePath: (obj, DOM) ->
    result = []
    _getPositionOfFrame = (obj)->
      #console.log DOM
      if obj.parentElement == DOM
        return
      else
        parent = obj.parentElement
        nodeList = Array.prototype.slice.call(parent.children)
        index = nodeList.indexOf(obj)
        result.unshift(index)
        _getPositionOfFrame(parent)
    _getPositionOfFrame(obj)
    #console.log result
    return JSON.stringify(result)

  addMeta: (DOM, url)->
    meta = document.createElement 'meta'
    meta.setAttribute 'name','original-url'
    meta.setAttribute 'content', url
    DOM.getElementsByTagName('head')[0].appendChild meta

  createNewObj: (obj, str) ->
    frames = obj.document.getElementsByTagName 'iframe'
    for frame in frames
      selector = @getFramePath(frame, obj.document)
      #console.log selector
      index = -1
      for key of obj.framesIdx
        #console.log key
        if selector == key
          index= obj.framesIdx[key]
      if index == -1
        continue
      key = str + index
      if @dictionary[key]?
        @createNewObj @dictionary[key], key+":"
        _document = @cleanUp @dictionary[key].document,@dictionary[key].url
        #console.log _document
        source = @getAttribute(
          @dictionary[key].header,
          @dictionary[key].doctype
        ) + _document.innerHTML + "</html>"
        frame.setAttribute('srcdoc', source)

  getAttribute: (array, status) ->
    src = "<html "
    for i in [0...array.length] by 2
      if array[i+1]?
        src += array[i] + '="' + array[i+1] + '" '
      else
        break
    #console.log status
    if status?
      doctype = @getDoctype(status)
      #console.log doctype
      return doctype + src
    return src += ">"

  getDoctype: (array) ->
    src = "<!DOCTYPE "
    elem = ""
    for i in [0...array.length]
      if i == 1
        src += "PUBLIC " + '"' + array[i] + '" '
      if i == 2
        src += '"' + array[i] + '"'
      if i == 0
        src+= array[i] + " "
      #console.log src
    return src + ">"


module.exports = BackTransport

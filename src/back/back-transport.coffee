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
    @dictionary={}
    @flag = false
    chrome.browserAction.onClicked.addListener () =>
      console.log "Button pressed!"
      chrome.tabs.query {active: true, currentWindow: true},(tabArray) =>
        #console.log "qwerty"
        #chrome.tabs.executeScript tabArray[0].id, {file: "content.min.js",allFrames: true},(array) ->
          #console.log "QWERTY",array
        chrome.tabs.executeScript tabArray[0].id, {code:"function getFrameId () {
  var fid = [];
  function _get_frame_id (win) {
    var idx, parent = win.parent;
    if (win === parent) {
      return;
    }
    idx = '?';
    for (var i=0; i< parent.frames.length; i++) {
        if (win === parent.frames[i]) {
            idx = i;
            break
        }
    }
    fid.unshift(idx);
    _get_frame_id(parent);
  }
  _get_frame_id(window);
  return fid.join(':')
};
[document.URL,document.documentElement.innerHTML,getFrameId()]",allFrames: true, matchAboutBlank: true},(array) =>
          console.log array
          @save array

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

  save: (DOMS) ->
    for dom in DOMS
      _html = document.createElement 'html'
      _html.innerHTML = dom[1]
      obj = {
        url: dom[0]
        document: @deleteScripts _html
      }
      @dictionary[dom[2]] = obj
    console.log @dictionary
    @parse(@callback)

  callback: (counter) =>
    console.log counter
    if counter == 0 && @flag == true
      console.log @dictionary
      @createNewObj @dictionary[""],""
      file = new File(["<html>",@dictionary[""].document.innerHTML,"</html>"],"index.txt", {type: "text/plain;charset=utf-8"})
      FileSaver.saveAs(file)
      @dictionary = {}

  parse: (callback) ->
    console.warn "DICTINARY",@dictionary
    counter = 0
    for key,dom of @dictionary
      tags = dom.document.querySelectorAll 'img,link,style'
      for tag in tags
        counter+=1
        if(tag.hasAttribute('src'))
          src = convertURL tag.getAttribute('src'), dom.url
          Base64 src,tag,(error,tag,result) ->
            counter--
            if error?
              console.error "(src)Base 64 error:",error.stack
            else
              tag.setAttribute "src",result
            callback counter
        else if(tag.hasAttribute('href'))
          if(tag.getAttribute('rel') == "stylesheet")
            href = convertURL(tag.getAttribute('href'), dom.url)
            gonzales xhr(href),tag,href,(error,tag,result) ->
              console.log counter
              counter--
              style = document.createElement 'style'
              style.innerHTML = result
              k = tag.parentElement
              console.log k
              console.log style
              tag.parentElement.insertBefore style,tag
              tag.parentElement.removeChild tag
              console.log k.parentElement
              callback counter
          else
            href = convertURL(tag.getAttribute('href'), dom.url)
            Base64 href,tag,(error,tag,result) ->
              counter--
              if error?
                console.error "(href) Base 64 error:",error.stack
              else
                tag.setAttribute "href",result
              callback counter
        else
          gonzales tag.innerHTML,tag,dom.url,(error,tag,result) ->
            counter--
            if error?
              console.error "(style)gonzales error:",error.stack
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
        @createNewObj @dictionary[key],key+":"
        frames[i].setAttribute "srcdoc", @dictionary[key].document.innerHTML
      else
        frames[i].parentElement.removeChild(frames[i])

    



    









module.exports = BackTransport
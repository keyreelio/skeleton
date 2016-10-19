
takeMain = (main, counter, flag) ->
  if flag == true
    url = document.createElement('a')
    url.href = main
    return url.protocol + "//" + url.hostname
  i = main.length
  while main[i] != "/" then i--
  main = main.substr 0, i
  i = main.length
  while counter != 0
    counter-- if main[i] == "/"
    i--
  main = main.substr 0, i + 1
  return main


takeUrl = (url) ->
  i = 0
  counter = 0
  while url.indexOf("..", i) != -1 and url.indexOf("./", i) != -1
    if url.indexOf("..", i) == -1
      i = url.indexOf("./", i) + 2
    else
      counter++
      i = url.indexOf("..", i) + 3
  if counter == 0 and url[0] == "/"
    url = url.substr 1
    return [url, counter, true]
  if i != 0
    url = url.substr i
  return [url, counter, false]


getEnd = (main) ->
  i = main.length - 1
  result = ""
  while main[i] != "/"
    result = main[i] + result
    i--
  return result


module.exports = (url, main) ->
  url = url.replace(/\s/g, '')
  #console.warn "URL: ",url
  #console.warn "MAIN: ",main
  if (
    (url[0] == '"' and url[url.length - 1] == '"') or
    (url[0] == "'" and url[url.length - 1] == "'")
  )
    url= url.substr 1, url.length - 2

  if url[0] == "/" and url[1] == "/"
    return "https:" + url

  if url.match(/^[\w\-_\d]+:/)
    return url

  URI = takeUrl(url)
  url = URI[0]
  if URI[2] == true
    return takeMain(main, URI[1], URI[2]) + "/" + url
  else
    return takeMain(main, URI[1], URI[2]) + "/" + url

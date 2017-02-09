module.exports = (url, main) ->
  url = url.replace(/\s/g, '')
  console.warn "URL: ",url
  console.warn "MAIN: ",main
  if (
    (url[0] == '"' and url[url.length - 1] == '"') or
    (url[0] == "'" and url[url.length - 1] == "'")
  )
    url= url.substr 1, url.length - 2

  if url[0] == "/" and url[1] == "/"
    return "https:" + url

  if url.match(/^[\w\-_\d]+:/)
    return url
  mainURLS = main.split('/')
  mainURLS.pop()
  indexURLS = url.split('/')
  for indexURL in indexURLS
    if(indexURL == '..')
      mainURLS.pop()
    else
      mainURLS.push(indexURL)
  return mainURLS.join('/')

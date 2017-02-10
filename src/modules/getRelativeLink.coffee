module.exports = (url, main) ->
  flag = false
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
  if url[0] == '/' and url[1] != '/'
    flag = true
    mainURLS = main.split('/')
    console.log mainURLS
    mainURLS = mainURLS.slice 0,3
    main = mainURLS.join('/')
  if url.match(/^[\w\-_\d]+:/)
    return url
  mainURLS = main.split('/')
  console.log main
  console.log mainURLS
  if(mainURLS[mainURLS.length-1].indexOf('.') > -1 && flag == false)
    mainURLS.pop()
  indexURLS = url.split('/')
  for indexURL in indexURLS
    if(indexURL == '..')
      mainURLS.pop()
    else
      mainURLS.push(indexURL)
  return mainURLS.join('/')

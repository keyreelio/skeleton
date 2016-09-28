
takeMain = (main,counter) ->
  i = main.length
  while main[i]!="/" then i--
  main = main.substr 0,i
  i = main.length
  while counter !=0
    if main[i] == "/"
      counter--
      i--
    else
      i--
  main = main.substr 0,i+1
  return main


takeUrl = (url) ->
  i=0
  counter=0
  while url.indexOf("..",i)!=-1 && url.indexOf("./",i)!=-1
    if url.indexOf("..",i) == -1
      i= url.indexOf("./",i)+2
    else
      counter++
      i= url.indexOf("..",i)+3
  if(counter==0 && url[0]=="/")
    url = url.substr 1
    return [url,counter]
  if i!=0
    url = url.substr i
  return [url,counter]


getEnd = (main) ->
  i= main.length-1
  result = ""
  while(main[i] != "/")
    result= main[i]+result
    i--
  return result


module.exports = (url,main) ->
  if url[0]=="'" && url[url.length-1]=="'"
    url= url.substr 1,url.length-2
  if url[0]=="/" && url[1]=="/"
    return "https:"+url
  if(url.match(/^[\w\-_\d]+:/))
    return url
  URI = takeUrl(url)
  url = URI[0]
  main = takeMain main,URI[1]
  end = getEnd(main)
  if url.indexOf(end) == 0
    url= url.substr(end.length+1)
  main = main+"/"+url
  #console.log URI[0]
  #console.log end
  #console.log main
  return main
getRelativeLink = (str,str1) ->
  i = 0
  while str[i]!="/"
    if str[i]==str1[i]
      i++
      continue
    else
      return str
  str= getRelativeLink str.substring(i+1),str1.substring(i+1)
  return str

module.exports = getRelativeLink
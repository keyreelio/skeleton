  function relPathToAbs (sRelPath,main) {
  console.log (sRelPath);
  console.log(main);
  if(sRelPath.match(/^[\w\-_\d]+:/)) return sRelPath;
  else if(sRelPath[0]=="/" && sRelPath[1]=="/") {
    return "https:"+sRelPath;
  }
  var nUpLn, sDir = "", sPath = main.replace(/[^\/]*$/, sRelPath.replace(/(\/|^)(?:\.?\/+)+/g, "$1"));
  for (var nEnd, nStart = 0; nEnd = sPath.indexOf("/../", nStart), nEnd > -1; nStart = nEnd + nUpLn) {
    nUpLn = /^\/(?:\.\.\/)*/.exec(sPath.slice(nEnd))[0].length;
    sDir = (sDir + sPath.substring(nStart, nEnd)).replace(new RegExp("(?:\\\/+[^\\\/]*){0," + ((nUpLn - 1) / 3) + "}$"), "/");
  }
  return sDir + sPath.substr(nStart);
}

module.exports = relPathToAbs
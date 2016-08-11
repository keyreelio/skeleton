browserify =  {
  debug: true,
  extensions: ['.coffee']
  bundleConfigs: [
   {
   entries: ['./src/front/content.coffee']
   debug: true
   outputName: "content.js"
   },
   {
   entries: ['./src/back/background.coffee']
   debug: true
   outputName: "background.js"
   }
 ]
}

module.exports = browserify
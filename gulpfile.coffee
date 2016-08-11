coffee = require 'gulp-coffee'
gulp = require 'gulp'
mocha = require 'gulp-mocha'
istanbul = require 'gulp-coffee-istanbul'
assign = require 'lodash.assign'
gutil = require 'gulp-util'
sourcemaps = require 'gulp-sourcemaps'
minify = require 'gulp-minify'
coffeelint = require 'browserify-coffeelint'
coffeeify = require 'coffeeify'
source = require 'vinyl-source-stream'
buffer = require 'vinyl-buffer'
watchify = require 'watchify'
browserify = require 'browserify'
config = require './src/config/config.coffee'


gulp.task 'test',['pre-test'], ->
  gulp.src './test/coffee/test.coffee', {read: false}
    .pipe mocha ({compilers: 'coffee:coffee-script'})
    .pipe istanbul.writeReports()


gulp.task 'pre-test', ->
  return gulp.src ['./build/coffee/test2.coffee']
    .pipe istanbul {includeUntested: true} 
    .pipe istanbul.hookRequire()



rebuild = ->
  config.bundleConfigs.forEach(bundle)
  gulp.run 'default' 

b = null
bundle = (bundleConfig)->
  opts =
    entries: bundleConfig.entries 
    cache: {}
    packageCache: {}
    fullPaths: false
    debug: true
  b = watchify browserify(opts)
  b.transform coffeelint,{doEmitErrors: true,doEmitWarnings: false}
  b.transform coffeeify,{bare: false, header: true}
  return b.bundle()
    .on 'error', (err) -> 
        console.log err.message
    .pipe source(bundleConfig.outputName)
    .pipe buffer()
    .pipe sourcemaps.init {loadMaps: true}
    .pipe sourcemaps.write './'
    .pipe minify {
        ext:{
            src:'.js',
            min:'.min.js'
        }
    }
    .pipe gulp.dest './build/extension/'


gulp.task 'build-coffee', config.bundleConfigs.forEach(bundle)

b.on 'update', rebuild
b.on 'log', gutil.log


gulp.task 'default', ->
  gulp.run ['build-coffee', 'test']
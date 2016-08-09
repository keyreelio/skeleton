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


gulp.task 'test',['pre-test'], ->
  gulp.src './test/coffee/test.coffee', {read: false}
    .pipe mocha ({compilers: 'coffee:coffee-script'})
    .pipe istanbul.writeReports()


gulp.task 'pre-test', ->
  return gulp.src ['./build/coffee/test2.coffee']
    .pipe istanbul {includeUntested: true} 
    .pipe istanbul.hookRequire()


customOpts = 
  entries: ['./build/coffee/main1.coffee']
  debug: true


opts = assign {},watchify.args,customOpts
b = watchify browserify(opts)
b.transform coffeelint,{doEmitErrors: true,doEmitWarnings: false}
b.transform coffeeify,{bare: false, header: true}


rebuild = ->
  bundle()
  gulp.run 'default' 


bundle = ->
  return b.bundle()
    .on 'error', (err) -> 
        console.log err.message
    .pipe source 'bundle.js'
    .pipe buffer()
    .pipe sourcemaps.init {loadMaps: true}
    .pipe sourcemaps.write './'
    .pipe gulp.dest './public/'


gulp.task 'build-coffee', bundle
b.on 'update', rebuild
b.on 'log', gutil.log


gulp.task 'default', ->
  gulp.run ['build-coffee', 'test', 'compress']


gulp.task 'compress',['build-coffee'],->
  gulp.src './build/*.js'
    .pipe minify {
        ext:{
            src:'-debug.js',
            min:'.js'
        }
    }
    .pipe gulp.dest './build/minify/'

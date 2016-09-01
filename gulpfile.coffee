gulp = require 'gulp'
mocha = require 'gulp-mocha'
istanbul = require 'gulp-coffee-istanbul'
config = require './src/config/webpack.config.js'
webpack = require 'webpack-stream'
coveralls = require 'gulp-coveralls'


gulp.task 'test',['pre-test'], ->
  gulp.src './test/coffee/test.coffee', {read: false}
    .pipe mocha ({compilers: 'coffee:coffee-script'})
    .pipe istanbul.writeReports()

gulp.task 'pre-test', ->
  return gulp.src ['./build/coffee/test2.coffee']
    .pipe istanbul {includeUntested: true}
    .pipe istanbul.hookRequire()



rebuild = ->
  config.forEach(bundle)
  gulp.run 'default'

bundle = (config) ->
  console.log config.entry
  return gulp.src config.entry
    .pipe webpack config
    .pipe gulp.dest './build/extension/'

gulp.task 'watch', ->
 gulp.watch './src/**/*.*',['default']

gulp.task 'build-coffee', -> 
  config.forEach(bundle)

gulp.task 'coveralls', ->
  gulp.src './coverage/lcov.info'
    .pipe coveralls().on 'error', (err) -> console.log err.message


gulp.task 'default', ->
  gulp.run ['build-coffee', 'test','coveralls']


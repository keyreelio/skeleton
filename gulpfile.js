var coffee = require('gulp-coffee'),
	gulp = require('gulp'),
	mocha = require('gulp-mocha'),
	istanbul = require('gulp-istanbul'),
	assign = require('lodash.assign'),
	gutil = require('gulp-util'),
	sourcemaps = require('gulp-sourcemaps'),
	minify = require('gulp-minify'),
	coffeelint = require('browserify-coffeelint'),
	coffeeify = require('coffeeify'),
	source = require('vinyl-source-stream'),
	buffer = require('vinyl-buffer'),
	watchify = require('watchify'),
	browserify = require('browserify');


gulp.task('test',['pre-test'], function() {
	gulp.src('./test/test.js', {read: false}) 
        .pipe(mocha())
        .pipe(istanbul.writeReports())
    // Enforce a coverage of at least 90% 
   		.pipe(istanbul.enforceThresholds({ thresholds: { global: 90 } }));
});


gulp.task('pre-test', function() {
	return gulp.src(['./build/js/test2.js'])
    // Covering files 
    .pipe(istanbul())
    // Force `require` to return covered files 
    .pipe(istanbul.hookRequire());
});


var customOpts = {
  entries: ['./build/coffee/main1.coffee'],
  debug: true
};


var opts = assign({}, watchify.args,customOpts);
var b = watchify(browserify(opts));
b.transform(coffeelint, {doEmitErrors: true, doEmitWarnings: false});
b.transform(coffeeify, {bare: false, header: true});


gulp.task('build-coffee',bundle);
b.on('update',rebuild);
b.on('log', gutil.log);


function bundle()
  {
    return b.bundle()
    .on('error', function(err) { console.log(err.message)})
    .pipe(source('bundle.js'))
    .pipe(buffer())
    .pipe(sourcemaps.init({loadMaps: true}))
    .pipe(sourcemaps.write('./maps/'))
    .pipe(gulp.dest('./build/js/'))
  };

function rebuild()
{
  bundle();
  gulp.run('default');
}


gulp.task('default', function() {
  gulp.run(['build-coffee', 'test', 'compress']) 
});


gulp.task('compress',['build-coffee'], function() {
  gulp.src('./build/js/*.js')
    .pipe(minify({
        ext:{
            src:'-debug.js',
            min:'.js'
        }
    }))
    .pipe(gulp.dest('./build/js/minify/'))
});
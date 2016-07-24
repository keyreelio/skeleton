#!/usr/bin/env node

//NOTE: set environment variable DEBUG=true|mock to build debug|mock bundle
//      e.g. DEBUG=true background.js

var _          = require('lodash');
var prj_root   = require('find-root')(__filename);
var path       = require('path');
var fs         = require('fs');
var Browserify = require('browserify');
var coffeelint = require('browserify-coffeelint');
var coffeeify  = require('coffeeify');
var envify     = require('envify/custom');
var watchify   = require('watchify');
var mkdirp     = require('mkdirp');
var versionify = require('browserify-versionify');
//TODO: replace browserify-versionify with browserify-transformation-tools
//      (see our tools/axt-loggerify.js as an example)

var version = fs.readFileSync(path.join(prj_root, 'build/current.version'), 'utf8').trim(),
    pkg_version = require('../package.json').version;

// config command line interface
var yargs = require('yargs')
  .usage('Usage: $0 [options...] entry-files...')
  .string('o')
  .alias('o', 'output')
  .describe('o', 'filename of target bundle')
  .nargs('o', 1)
  //.normalize('o')
  .string('m')
  .alias('m', 'source-map')
  .describe('m', 'filename of target bundle source map')
  .nargs('m', 1)
  .normalize('m')
  .string('r')
  .alias('r', 'require')
  .describe('r', 'TODO: [require]:write description')
  .nargs('r', 1)
  .string('p')
  .alias('p', 'source-path')
  .describe('source-path', 'path in browser to source and source-map')
  .boolean('mkdirp')
  .describe('mkdirp', "mkdir -p output directores if they don't exist")
  .boolean('w')
  .alias('w', 'watch')
  .describe('w', 'run wachify instead of browserify')
  .boolean('v')
  .alias('v', 'verbose')
  .describe('v', "verbose error messages")
  .boolean('version')
  .describe('version', "get version")
  .help('h')
  .alias('h', 'help')
  .epilog('2016 © Auxoft');

var argv = yargs.argv;

///======== CHECK CLI ARGUMENTS =========
if (argv.version) {
  console.error(pkg_version);
  process.exit(1);
}

if (argv._.length < 1) {
  yargs.showHelp();
  console.error('ERROR: wrong number of entry-files. Please, specify one or more entry-files');
  process.exit(1);
}

var source_protocol = '', source_path = argv.sourcePath || '';
if (source_path) {
  var splited_path = source_path.match(/^(.+?:\/\/)?(.*)$/);
  if (splited_path) {
    source_protocol = splited_path[1] || '';
    source_path = splited_path[2];
  } else {
   console.error('ERROR: wrong source_path:', source_path);
   process.exit(1);
  }
}

var entry_files = argv._.map( function (f) {
  try {
    return path.resolve(f);
  } catch (e) {
    console.error('ERROR: unable to resolve entry_file:', f, '('+e.message+')');
    process.exit(1);
  }
});


var bundle_file;
if (argv.output) {
  if (_.isArray(argv.output)) {
    yargs.showHelp()
    console.error('ERROR: Only one output key is permitted');
  }

  try {
    bundle_file = path.resolve(argv.output);
  } catch (e) {
    console.error(
      'ERROR: unable to resolve output file:', argv.output, '('+e.message+')'
    );
    process.exit(1);
  }
}

var map_file;
if (argv.sourceMap) {
  if (_.isArray(argv.sourceMap)) {
    yargs.showHelp()
    console.error('ERROR: Only one output source-map key is permitted');
  }

  try {
    map_file = path.resolve(argv.sourceMap); //"background.min.js.map"
  } catch (e) {
    console.error(
      'ERROR: unable to resolve source-map file:',
      argv.sourceMap,
      '('+e.message+')'
    );
    process.exit(1);
  }
} else {
  map_file = bundle_file + '.map'
}

var requires;
if (argv.require) {
  var require = (typeof argv.require === 'string'
                 ? [argv.require]
                 : argv.require
                );

  //console.error('require=', require);
  requires = require.map( function (req_arg) {
    var req = {}, expose,
        matched_req = req_arg.match(/^([^:]+)(?::(.*))?$/);

    if (!req_arg || (req_arg && !matched_req)) {
      yargs.showHelp()
      console.error('ERROR: wrong -r|--require string', req_arg);
      process.exit(1);
    }

    req.file = matched_req[1];
    expose = matched_req[2];

    if (expose) {
      expose = expose.trim();
      if (expose)
        req.expose = expose;
    }
    return req;
  })
}

//process.exit(1);

// check DEBUG environment variable
var debug_cfg = {};
if (process.env.DEBUG)
  if (process.env.DEBUG === 'mock')
    debug_cfg.DEBUG = 'mock';
  else if (process.env.DEBUG !== 'false')
    debug_cfg.DEBUG = true;

// As of browserify 5, you must enable debug mode in the constructor
// to use minifyify
var bundler = new Browserify({
  entries: entry_files,
  cache: {},
  packageCache: {},
  debug: true,
  extensions: ['.coffee']
});

// replace placeholder __VERSION__ with value from build/current.version
bundler.transform(versionify, {
  placeholder: '__VERSION__',
  version:     version // pkg_version
});

// run coffeelint on original source
bundler.transform(coffeelint, {doEmitErrors: true, doEmitWarnings: false}); // doEmitWarnings: true})

// run coffeescript compiler
bundler.transform(coffeeify, {bare: false, header: true});

// replace module.env.DEBUG with values from debug_cfg.DEBUG across all sources
bundler.transform(envify(debug_cfg)); // {DEBUG: true, VAR2: var2} -> replace: 'process.env.DEBUG' & 'process.env.VAR2' WITH true & 'var2'

// uglifyify sources
bundler.plugin('minifyify', {
  map: source_protocol + path.join(source_path, path.basename(map_file))
  , uglify: {
      //global: true,
      mangle: {
        except: ['require']
      },
      compress: {
        dead_code: true
      },
      output: {
       beautify: false
      }
    }
});

process.on('uncaughtException', function (err) {
  // when coffeelint throw an error, all important information is already
  // shown.
  if (!String(err).match(/coffeelint/)) {
    console.error("Caught exception: ", err);

    if (argv.verbose) {
      // verbose error (sometimes we need it):
      console.error(err.stack);
    }
  }

  if (!argv.watch) {
    process.exit(1);
  }
  bundler.on('update', bundle);
});

if (requires && requires.length) {
  bundler.require(requires);
}

function bundle() {
  bundler.bundle(function (err, src, map) {
    if (err) {
      console.error('ERROR: bundler.bundle', err.stack);
      throw err;
    }

    function save_bundle(err) {
      if (err) {
        console.error('ERROR: save_bundle', err.stack);
        throw err;
      }

      fs.writeFileSync(bundle_file, src);
      console.error('save bundle to', bundle_file);
    }

    function save_map(err) {
      if (err) {
        console.error('ERROR: save_map', err.stack);
        throw err;
      }

      fs.writeFileSync(map_file, map);
      console.error('save bundle map to', map_file);
    }

    if (bundle_file) {
      if (argv.mkdirp)
        mkdirp(path.dirname(bundle_file), save_bundle);
      else
        save_bundle();
    } else {
      // return created bundle in std output if there isn't -o bundlename  key
      process.stdout.write(src);
    }

    if (map_file) {
      if (argv.mkdirp)
         mkdirp(path.dirname(map_file), save_map);
      else
         save_map();
    // if there ins't -m mapname key then return nothing
    }
  });
}

if (argv.watch) {
  bundler.plugin('watchify');
  bundler.on('update', bundle);
}

bundle();


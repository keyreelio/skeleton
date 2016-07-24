#!/bin/bash

cd $(dirname $0)
BIN_DIR=$(pwd)/..

cd ../../src/browser_client  # set work directory

CONTENT=true $BIN_DIR/build-bundle.js \
  --require=./chrome/front-transport.coffee:./front-transport.coffee \
  --require=./front/send-log.coffee:./send-log.coffee \
  --require=./common/log.coffee:../../common/log.coffee \
  --require=./common/rlog.coffee:../../common/rlog.coffee \
  --require=./common/utils.coffee:../../common/utils.coffee \
  --require=./front/parser-helpers.coffee:../../front/parser-helpers.coffee \
  --require=chai \
  --mkdirp \
  --output=../../prj/chrome/KeyReel/js/content.min.js \
  chrome/content.coffee $*


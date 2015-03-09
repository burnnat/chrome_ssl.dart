#!/bin/bash

which content_shell
if [[ $? -ne 0 ]]; then
  $DART_SDK/../chromium/download_contentshell.sh
  unzip content_shell-linux-x64-release.zip

  cs_path=$(ls -d drt-*)
  PATH=$cs_path:$PATH
fi

set -e

DIR=$( cd $( dirname "${BASH_SOURCE[0]}" ) && pwd )
BROWSER_TEST_FILE=$DIR/test.html

DUMP=$(content_shell --args --dump-render-tree $BROWSER_TEST_FILE)
echo "$DUMP"

REGEX="All [0-9]+ tests pass"

if [[ $DUMP =~ $REGEX ]]
then
  echo Success!
  exit 0
else
  echo Fail!
  exit 1
fi

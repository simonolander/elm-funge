#!/usr/bin/env bash
set -ex
cd "$(dirname "$0")"

echo -en "\033]0;Elm\a"
rm -rf elm-stuff
ELM_DEBUGGER=false elm-app start
echo -en "\033]0;\a"

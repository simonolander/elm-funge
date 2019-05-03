#!/usr/bin/env bash
set -ex
cd "$(dirname "$0")"

echo -en "\033]0;Elm\a"
ELM_DEBUGGER=false elm-app start
echo -en "\033]0;\a"

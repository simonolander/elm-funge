#!/usr/bin/env bash

set -ex

cd "$(dirname "$0")"

cd ..

elm-app build
elm-app test

cicd/upload-build-to-s3.sh

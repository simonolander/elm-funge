#!/usr/bin/env bash

set -ex

cd "$(dirname "$0")"

cd ..

elm-app build

cicd/upload-build-to-s3.sh

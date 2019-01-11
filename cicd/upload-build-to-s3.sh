#!/usr/bin/env bash

set -ex

cd "$(dirname "$0")"

aws s3 cp ../build/ s3://efng.simonolander.com/ --recursive --profile=efng --storage-class=REDUCED_REDUNDANCY --acl=public-read

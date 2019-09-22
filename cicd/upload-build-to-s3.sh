#!/usr/bin/env bash

set -ex

cd "$(dirname "$0")"

aws s3 cp ../build/ s3://efng.simonolander.com/ --recursive --profile=efng --storage-class=REDUCED_REDUNDANCY --acl=public-read
aws cloudfront create-invalidation --distribution-id E21TBYPS2G71FC --paths "/*" --profile=efng

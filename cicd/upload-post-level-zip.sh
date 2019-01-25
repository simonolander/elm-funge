#!/usr/bin/env bash

set -ex

cd "$(dirname "$0")"

cd ../lambdas/post-level

zip -r ../post-level.zip node_modules index.js

cd ..

aws lambda update-function-code --region us-east-1 --function-name arn:aws:lambda:us-east-1:361301349588:function:efng-post-level --zip-file fileb://post-level.zip --profile efng
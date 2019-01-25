#!/usr/bin/env bash

set -ex

cd "$(dirname "$0")"

cd ../lambdas/get-levels

zip -r ../get-levels.zip node_modules index.js

cd ..

aws lambda update-function-code --region us-east-1 --function-name arn:aws:lambda:us-east-1:361301349588:function:efng-get-levels --zip-file fileb://get-levels.zip --profile efng
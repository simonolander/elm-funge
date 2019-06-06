#!/usr/bin/env bash
set -ex
cd "$(dirname "$0")"
cd functions/firestore-function
npm install
tsc

cp -r node_modules build/
cp package.json build/
cp package-lock.json build/

gcloud functions deploy drafts --runtime nodejs8 --trigger-http --source build
gcloud functions deploy solutions --runtime nodejs8 --trigger-http --source build
gcloud functions deploy highScores --runtime nodejs8 --trigger-http --source build
gcloud functions deploy levels --runtime nodejs8 --trigger-http --source build
gcloud functions deploy userInfo --runtime nodejs8 --trigger-http --source build

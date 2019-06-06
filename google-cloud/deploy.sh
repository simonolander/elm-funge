#!/usr/bin/env bash
set -ex
cd "$(dirname "$0")"
cd functions/firestore-function
npm install
tsc
gcloud functions deploy drafts --runtime nodejs8 --trigger-http
gcloud functions deploy solutions --runtime nodejs8 --trigger-http
gcloud functions deploy highScores --runtime nodejs8 --trigger-http
gcloud functions deploy levels --runtime nodejs8 --trigger-http
gcloud functions deploy userInfo --runtime nodejs8 --trigger-http

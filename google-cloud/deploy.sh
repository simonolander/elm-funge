#!/usr/bin/env bash
set -ex
cd "$(dirname "$0")"

gcloud functions deploy highScores --runtime nodejs8 --trigger-http --source functions/firestore-function
gcloud functions deploy levels --runtime nodejs8 --trigger-http --source functions/firestore-function
gcloud functions deploy userInfo --runtime nodejs8 --trigger-http --source functions/firestore-function

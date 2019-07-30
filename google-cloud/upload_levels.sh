#!/usr/bin/env bash
set -ex
cd "$(dirname "$0")"

jq -c .[] initial_levels.json |
while IFS= read -r level; do
    curl -X PUT 'https://us-central1-luminous-cubist-234816.cloudfunctions.net/levels' -H 'Content-Type: application/json' -d "${level}"
done

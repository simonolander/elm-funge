#!/usr/bin/env bash

set -e
cd "$(dirname "$0")"
echo -en "\033]0;${0}\a"

LOCAL_STORAGE_FILE="localStorage.json"

function generateFiles {
  DIRECTORY="$1"
  KEY="$1"
  EXTRA_FIELDS="$2"
  mkdir -p "$DIRECTORY"
  cat "$LOCAL_STORAGE_FILE" | jq -c "to_entries | .[] | select(.key | test(\"^$KEY\\\\.[^.]+$\")) | .value" | while read -r VALUE
  do
    ID=$(echo -n "$VALUE" | jq -r ".id")
    FILE_NAME="$DIRECTORY/$ID.json"
    echo "Generating $FILE_NAME"
    echo "$VALUE" | jq "$EXTRA_FIELDS" > "$FILE_NAME"
  done
  echo "Generating $DIRECTORY/index.ts"
  IDS=$(ls "$DIRECTORY"/*.json | xargs basename -- | sed 's/\.[^.]*$//')
  touch "$DIRECTORY/index.ts"
  echo -n "" > "$DIRECTORY/index.ts"
  echo "$IDS" | while read -r ID
  do
    echo "import _$ID from \"./$ID.json\";" >> "$DIRECTORY/index.ts"
  done
  echo "" >> "$DIRECTORY/index.ts"
  echo "export default {" >> "$DIRECTORY/index.ts"
  echo "$IDS" | while read -r ID
  do
    echo "    \"$ID\": _$ID," >> "$DIRECTORY/index.ts"
  done
  echo "};" >> "$DIRECTORY/index.ts"
}

generateFiles "levels" '.createdTime=1566887680 | .authorId="test-user-id"'
generateFiles "solutions" '.createdTime=1566887680 | .authorId="test-user-id"'
generateFiles "drafts" '.createdTime=1566887680 | .authorId="test-user-id" | .modifiedTime=1566887680 | .version=1'

echo -en "\033]0;\a"

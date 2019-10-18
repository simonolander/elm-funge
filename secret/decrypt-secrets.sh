#!/usr/bin/env sh

set -e

if [ -z "${HOME}" ]; then
  echo "Fatal: HOME is not set"
  exit 1
fi

if [ -z "${AWS_CREDENTIALS_GPG_KEY}" ]; then
  echo "Fatal: AWS_CREDENTIALS_GPG_KEY is not set"
  exit 2
fi

OUTPUT_FOLDER="${HOME}/.secret"

rm -rf "${OUTPUT_FOLDER}"
mkdir -p "${OUTPUT_FOLDER}"
echo "AUTO-GENERATED, DO NOT MODIFY" > "${OUTPUT_FOLDER}/readme.md"

gpg --quiet --batch --yes --decrypt --homedir "${OUTPUT_FOLDER}" --passphrase="${AWS_CREDENTIALS_GPG_KEY}" --output "${OUTPUT_FOLDER}/aws.credentials" aws.credentials.gpg

#!/bin/bash

set -e

if [ -z "$1" ]; then
  echo "Error: No environment specified. Use 'local' or 'prd'."
  exit 1
fi

ENV=$1
SOURCE_FILE=".env-$ENV"
TARGET_FILE=".env"

if [ ! -f "$SOURCE_FILE" ]; then
  echo "Error: Environment file '$SOURCE_FILE' not found."
  exit 1
fi

cp "$SOURCE_FILE" "$TARGET_FILE"

echo "Environment configured for '$ENV'. The file '$TARGET_FILE' has been updated."
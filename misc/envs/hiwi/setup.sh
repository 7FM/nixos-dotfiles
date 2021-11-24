#!/bin/sh
set -ueo pipefail

if [ $# -ne 1 ]; then
  echo "Usage: ./setup.sh <path>"
  exit 1
fi

SCRIPT_PATH=$(realpath $(dirname $0))
TARGET_PATH="$1"
mkdir -p "$TARGET_PATH"
mkdir -p "$TARGET_PATH/env"

for f in $(find "$SCRIPT_PATH" -type f -name "*.nix"); do
  target_f=$(basename "$f")
  target_f="$TARGET_PATH/env/$target_f"
  echo "Copying $f to $target_f"
  cp "$f" "$target_f"
done

# Direnv file
cp "$SCRIPT_PATH/.envrc" "$TARGET_PATH"

echo "Successfully setup hiwi env!"

#!/bin/sh
set -ueo pipefail

if [ $# -ne 1 ]; then
  echo "Usage: ./setup.sh <path>"
  exit 1
fi

SCRIPT_PATH=$(realpath $(dirname $0))
TARGET_PATH="$1"
mkdir -p "$TARGET_PATH"

for f in $(find "$SCRIPT_PATH" -type f -name "*.nix"); do
  target_f=$(basename "$f")
  target_f="$TARGET_PATH/$target_f"
  echo "Linking $f to $target_f"
  ln -s "$f" "$target_f"
done

for f in $(find "$SCRIPT_PATH" -type f -name "*.patch"); do
  target_f=$(basename "$f")
  target_f="$TARGET_PATH/$target_f"
  echo "Linking $f to $target_f"
  ln -s "$f" "$target_f"
done

# Direnv file
cp "$SCRIPT_PATH/.envrc" "$TARGET_PATH"

# Final setup stage
cd "$TARGET_PATH"
direnv allow
git clone https://github.com/zachjs/sv2v
cd sv2v && git apply ../sv2v.patch && cd ..
direnv exec . sh -c 'cd sv2v && make'

echo "Successfully setup FPGA_Tools!"
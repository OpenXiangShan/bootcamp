#!/usr/bin/env bash

set -euo pipefail

# NOTE: This script is intended to be run on our demo server for tutorial.
# NOTE: If you are deploying your own environment, you do not need to use this script.

CODE="/app/code-server/bin/code-server"
SOURCE="/config/workspace"

if [ ! -f "${CODE}" ]; then
    echo "Error: code-server not found at ${CODE}" >&2
    echo "Note: This script is intended to be run on our demo server for tutorial." >&2
    echo "Note: If you are deploying your own environment, you do not need to use this script." >&2
    exit 1
fi

echo "=== Welcome to XiangShan tutorial ==="

# generate an 8-character random string (lowercase letters + digits)
random="$(tr -dc 'a-z0-9' </dev/urandom 2>/dev/null | head -c 8 || true)"
if [ -z "$random" ]; then
	# fallback when /dev/urandom isn't available or tr failed
	random="$(date +%s)-$$"
fi

DEST="/data/$random"

echo "Your Random id: $random"

echo "Copying workspace..."
EXCLUDE=(
    "assets"
    "tutorial"
    "work"
)
mkdir -p "$DEST"

declare -A EXCLUDE_MAP=()
for ex in "${EXCLUDE[@]}"; do
    EXCLUDE_MAP["$ex"]=1
done

for entry in "$SOURCE"/*; do
    [ -e "$entry" ] || continue

    name="$(basename "$entry")"

    if [[ -n "${EXCLUDE_MAP[$name]:-}" ]]; then
        continue
    fi

    cp -a --reflink=auto "$entry" "$DEST/"
done

cp -a --reflink=auto "$SOURCE/.git" "$DEST/"

ln -s "$SOURCE/assets" "$DEST/assets"

echo
echo "Workspace copied to $DEST, trying to open it in code-server..."
echo "If you see an error, please open it manually on Menu > File > Open Folder..."

$CODE "$DEST"

#!/bin/sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
if [ -z "${DEVELOPER_DIR:-}" ] && [ -d /Applications/Xcode.app/Contents/Developer ]; then
    export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
fi
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

for model in "$root"/chic/Models/*.mlmodel "$root"/chic/models_Delonghi/*.mlmodel; do
    xcrun coremlcompiler compile "$model" "$work" >/dev/null
done
xcrun swiftc -O -D DEVELOP -module-cache-path "$work/cache" \
    "$root"/chic/Services/SoundAnalysis/Chic*.swift \
    "$root"/Tests/ChicModelV3_5Tests.swift -o "$work/check"
"$work/check" "$root/Tests/Fixtures/ChicModelV3_5" "$work"

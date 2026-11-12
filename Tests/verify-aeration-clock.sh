#!/bin/sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
if [ -z "${DEVELOPER_DIR:-}" ] && [ -d /Applications/Xcode.app/Contents/Developer ]; then
    export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
fi
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

xcrun swiftc -module-cache-path "$work/cache" \
    "$root/chic/Services/AerationClock.swift" \
    "$root/Tests/AerationClockTests.swift" -o "$work/check"
"$work/check"

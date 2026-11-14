#!/bin/sh
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
app=${1:?Usage: sh Tests/verify-connection-errors.sh /path/to/chic.app}
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
xcrun swiftc -module-cache-path "$work/cache" \
    "$root/Shared/ConnectionError.swift" \
    "$root/Tests/ConnectionErrorTests.swift" -o "$work/check"
"$work/check" "$app"

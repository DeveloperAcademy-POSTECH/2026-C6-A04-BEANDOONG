#!/bin/sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
if [ -z "${DEVELOPER_DIR:-}" ] && [ -d /Applications/Xcode.app/Contents/Developer ]; then
    export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
fi
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

xcrun swiftc -module-cache-path "$work/cache" \
    "$root/Shared/PracticeState.swift" \
    "$root/chee-k/DesignSystem/AppColors.swift" \
    "$root/chee-k/Screens/PracticeResult/PracticeResult.swift" \
    "$root/chee-k/Models/PracticeRecordEntity.swift" \
    "$root/chee-k/Services/PracticeTimeline.swift" \
    "$root/chee-k/Services/PracticeHistoryStore.swift" \
    "$root/Tests/PracticeResultTests.swift" -o "$work/check"
"$work/check"

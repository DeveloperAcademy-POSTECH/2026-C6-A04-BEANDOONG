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
    "$root/chic/DesignSystem/AppColors.swift" \
    "$root/chic/Screens/PracticeResult/PracticeResult.swift" \
    "$root/chic/Models/PracticeRecordEntity.swift" \
    "$root/chic/Services/PracticeTimeline.swift" \
    "$root/chic/Services/AerationClock.swift" \
    "$root/chic/Screens/PracticeResult/PracticeGuide.swift" \
    "$root/chic/Services/PracticeHistoryStore.swift" \
    "$root/Tests/PracticeResultTests.swift" -o "$work/check"
"$work/check"

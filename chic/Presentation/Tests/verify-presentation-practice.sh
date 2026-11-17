#!/bin/sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/../../.." && pwd)
if [ -z "${DEVELOPER_DIR:-}" ] && [ -d /Applications/Xcode.app/Contents/Developer ]; then
    export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
fi
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

xcrun swiftc -D PRESENTATION_TESTS -module-cache-path "$work/cache" \
    "$root/Shared/PracticeState.swift" \
    "$root/Shared/ConnectionError.swift" \
    "$root/chic/Services/SoundAnalysis/ChicModelSelection.swift" \
    "$root/chic/Services/AerationClock.swift" \
    "$root/chic/Services/MilkLevel.swift" \
    "$root/chic/Services/SmoothFollower.swift" \
    "$root/chic/Screens/Practice/PitcherMotion.swift" \
    "$root/chic/Services/PracticeTimeline.swift" \
    "$root/chic/Screens/PracticeResult/PracticeResult.swift" \
    "$root/chic/Presentation/PresentationPractice.swift" \
    "$root/chic/Presentation/PresentationWatchSync.swift" \
    "$root/chic/Presentation/Tests/PresentationWatchSyncTests.swift" \
    "$root/chic/Presentation/Tests/PresentationPracticeTests.swift" -o "$work/check"
"$work/check"

#!/bin/sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
if [ -z "${DEVELOPER_DIR:-}" ] && [ -d /Applications/Xcode.app/Contents/Developer ]; then
    export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
fi
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

for model in "$root"/chic/Models/*.mlmodel; do
    xcrun coremlcompiler compile "$model" "$work" >/dev/null
done
xcrun swiftc -O -module-cache-path "$work/cache" \
    "$root"/chic/Services/SoundAnalysis/Chic*.swift \
    "$root"/Shared/PracticeState.swift \
    "$root"/chic/Services/PracticeFeedbackHold.swift \
    "$root"/Tests/ChicModelV4Tests.swift -o "$work/check"
"$work/check" "$root/Tests/Fixtures/ChicModelV4" "$work"

# 화면 유지 시간과 롤링 예외도 같은 검증 명령에서 확인합니다.
xcrun swiftc -module-cache-path "$work/cache" \
    "$root"/Shared/PracticeState.swift \
    "$root"/chic/Services/PracticeFeedbackHold.swift \
    "$root"/Tests/PracticeFeedbackHoldTests.swift -o "$work/hold-check"
"$work/hold-check"

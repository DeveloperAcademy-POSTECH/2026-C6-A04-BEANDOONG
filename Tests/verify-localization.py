#!/usr/bin/env python3
"""Validate catalogs; optionally check compiler extraction and built app bundles.

Usage: python3 Tests/verify-localization.py [DerivedData directory]
"""

import json
import plistlib
import re
import sys
from collections import Counter
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
PLACEHOLDER = re.compile(r"%(?:\d+\$)?(?:lld|ld|d|@|f)")


def placeholders(value):
    return Counter(re.sub(r"%\d+\$", "%", match) for match in PLACEHOLDER.findall(value))


catalogs = {}
for relative in ("Shared/Localizable.xcstrings", "chic/InfoPlist.xcstrings"):
    catalog = json.loads((ROOT / relative).read_text())
    assert catalog["sourceLanguage"] == "ko", relative
    catalogs[Path(relative).stem] = catalog["strings"]
    for key, entry in catalog["strings"].items():
        values = {}
        for language in ("ko", "en"):
            unit = entry["localizations"][language]["stringUnit"]
            assert unit["state"] == "translated", (relative, key, language)
            assert unit["value"].strip(), (relative, key, language)
            values[language] = unit["value"]
        assert not re.search("[가-힣]", values["en"]), (relative, key)
        assert placeholders(values["ko"]) == placeholders(values["en"]), key

for language in ("ko", "en"):
    asset = catalogs["Localizable"]["home.practice.image"]["localizations"][language]["stringUnit"]["value"]
    assert (ROOT / "chic/Assets.xcassets" / f"{asset}.imageset/Contents.json").is_file()

# Connection errors carry untranslated keys; the receiving device looks them up.
for relative in ("Shared/WatchConnection.swift", "chic/Services/PracticeSession.swift"):
    source = (ROOT / relative).read_text()
    keys = re.findall(r'ConnectionError\.localized\("([^"\n]+)"\)', source)
    keys += re.findall(r'openAppMessageKey = "([^"\n]+)"', source)
    assert keys, relative
    for key in keys:
        assert key in catalogs["Localizable"], (relative, key)

if len(sys.argv) > 1:
    derived_data = Path(sys.argv[1])
    extracted_files = list((derived_data / "Build/Intermediates.noindex").rglob("*.stringsdata"))
    assert extracted_files, "Build the app first to validate compiler-extracted keys."
    for path in extracted_files:
        extracted = json.loads(path.read_text())
        for entry in extracted.get("tables", {}).get("Localizable", []):
            key = entry["key"]
            if re.search("[가-힣]", key):
                assert key in catalogs["Localizable"], (extracted["source"], key)

    products = derived_data / "Build/Products"
    apps = [products / "Debug-iphonesimulator/chic.app", products / "Debug-watchsimulator/chic-watch.app"]
    for app in apps:
        for table in ("Localizable", "InfoPlist") if app.name == "chic.app" else ("Localizable",):
            for language in ("ko", "en"):
                strings = plistlib.loads((app / f"{language}.lproj/{table}.strings").read_bytes())
                for key, entry in catalogs[table].items():
                    expected = entry["localizations"][language]["stringUnit"]["value"]
                    assert strings.get(key) == expected, (app.name, language, key)
    print(f"PASS: {len(extracted_files)} extraction files and both app bundles")

print(f"PASS: {sum(len(strings) for strings in catalogs.values())} Korean/English entries, placeholders, and localized assets")

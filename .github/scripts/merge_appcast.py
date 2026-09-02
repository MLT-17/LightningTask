#!/usr/bin/env python3
"""
Fügt den <item>-Block aus einer frisch generierten appcast.xml (mit nur einem
Eintrag) in eine bestehende appcast.xml ein, direkt nach <title>, sodass die
Versions-Historie erhalten bleibt statt überschrieben zu werden.

Nutzung:
    python3 merge_appcast.py <neu_generierte_appcast.xml> <bestehende_appcast.xml>

Die zweite Datei wird in-place aktualisiert.
"""

import re
import sys


def main() -> int:
    if len(sys.argv) != 3:
        print("Nutzung: merge_appcast.py <neue_appcast.xml> <bestehende_appcast.xml>", file=sys.stderr)
        return 1

    new_path, existing_path = sys.argv[1], sys.argv[2]

    with open(new_path, "r", encoding="utf-8") as f:
        new_content = f.read()

    match = re.search(r"<item>.*?</item>", new_content, re.DOTALL)
    if not match:
        print(f"Kein <item>-Block in {new_path} gefunden.", file=sys.stderr)
        return 1
    new_item = match.group(0)

    with open(existing_path, "r", encoding="utf-8") as f:
        existing = f.read()

    # Falls dieselbe Version schon drin ist (z. B. Workflow wurde erneut
    # laufen gelassen), nicht doppelt einfügen.
    version_match = re.search(r"<sparkle:version>([^<]+)</sparkle:version>", new_item)
    if version_match and version_match.group(1) in existing:
        print(f"Version {version_match.group(1)} ist bereits in der appcast.xml enthalten, kein Insert nötig.")
        return 0

    def insert_after_title(m: re.Match) -> str:
        return m.group(0) + "\n        " + new_item + "\n"

    updated, count = re.subn(r"<title>[^<]*</title>", insert_after_title, existing, count=1)
    if count == 0:
        print(f"Kein <title>-Tag in {existing_path} gefunden, Anker für Insert fehlt.", file=sys.stderr)
        return 1

    with open(existing_path, "w", encoding="utf-8") as f:
        f.write(updated)

    print(f"Neuer Eintrag erfolgreich in {existing_path} eingefügt.")
    return 0


if __name__ == "__main__":
    sys.exit(main())

#!/usr/bin/env python3
# Discipline — app di calisthenics libera e gratuita.
# Copyright (C) 2026 Discipline contributors
# SPDX-License-Identifier: GPL-3.0-or-later
"""Scarica e alleggerisce i caratteri degli stili in assets/fonts/.

Tutti i caratteri sono liberi (SIL Open Font License) e vengono da Google
Fonts. Si tengono solo i caratteri latini (italiano, numeri, simboli) e, per
quelli giapponesi, solo i kanji usati dall'app: così l'app resta leggera.

Uso: pip install fonttools && python3 tool/make_fonts.py
"""
import io
import re
import sys
import urllib.request
from pathlib import Path

from fontTools import subset
from fontTools.ttLib import TTFont

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "assets" / "fonts"
sys.path.insert(0, str(ROOT / "tool"))

# Lo stesso elenco di lib/core/theme/styles/kanji_text.dart.
KANJI = (ROOT / "lib/core/theme/styles/kanji_text.dart").read_text(encoding="utf-8")
KANJI_CHARS = "".join(sorted({c for c in KANJI if ord(c) > 0x2E80}))

LATIN = (
    "U+0020-007E,U+00A0-00FF,U+0131,U+0152-0153,U+02C6,U+02DA,U+02DC,"
    "U+2013-2014,U+2018-201E,U+2022,U+2026,U+2032-2033,U+20AC,U+2122,"
    "U+2190-2193,U+2212,U+2264-2265,U+00D7"
)

# (famiglia nell'app, nome su Google Fonts, pesi, cartella della licenza,
# giapponese)
FAMILIES = [
    ("Fredoka", "Fredoka", [500, 600, 700], "fredoka", False),
    ("Archivo", "Archivo", [400, 600, 800], "archivo", False),
    ("ArchivoBlack", "Archivo Black", [400], "archivoblack", False),
    ("PlexMono", "IBM Plex Mono", [500, 700], "ibmplexmono", False),
    ("PressStart", "Press Start 2P", [400], "pressstart2p", False),
    ("DotGothic", "DotGothic16", [400], "dotgothic16", False),
    ("Baloo", "Baloo 2", [500, 700, 800], "baloo2", False),
    ("Orbitron", "Orbitron", [600, 800], "orbitron", False),
    ("Rajdhani", "Rajdhani", [500, 600, 700], "rajdhani", False),
    ("Anton", "Anton", [400], "anton", False),
    ("Barlow", "Barlow", [500, 600, 700], "barlow", False),
    ("OpenSans", "Open Sans", [400, 600, 700], "opensans", False),
    ("Shippori", "Shippori Mincho", [600, 800], "shipporimincho", True),
    ("ZenKaku", "Zen Kaku Gothic New", [400, 500, 700], "zenkakugothicnew", True),
    ("YujiBoku", "Yuji Boku", [400], "yujiboku", True),
]

UA = "Mozilla/5.0 (X11; Linux x86_64; rv:10.0)"  # così Google dà file .ttf


def get(url: str) -> bytes:
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    with urllib.request.urlopen(req, timeout=60) as r:
        return r.read()


def ttf_urls(name: str, weights: list[int]) -> dict[int, str]:
    family = name.replace(" ", "+")
    query = f"{family}:wght@{';'.join(map(str, weights))}"
    css = get(f"https://fonts.googleapis.com/css2?family={query}").decode()
    found = {}
    for block in css.split("@font-face")[1:]:
        weight = int(re.search(r"font-weight:\s*(\d+)", block).group(1))
        found.setdefault(weight, re.search(r"url\((.+?\.ttf)\)", block).group(1))
    return found


def main() -> None:
    licenses = OUT / "licenses"
    licenses.mkdir(parents=True, exist_ok=True)
    for app_name, gf_name, weights, folder, japanese in FAMILIES:
        target = OUT / app_name
        target.mkdir(parents=True, exist_ok=True)
        for weight, url in ttf_urls(gf_name, weights).items():
            font = TTFont(io.BytesIO(get(url)))
            options = subset.Options()
            options.layout_features = ["*"]
            options.name_IDs = ["*"]
            options.notdef_outline = True
            sub = subset.Subsetter(options)
            unicodes = subset.parse_unicodes(LATIN)
            text = KANJI_CHARS if japanese else ""
            sub.populate(unicodes=unicodes, text=text)
            sub.subset(font)
            out = target / f"{app_name}-{weight}.ttf"
            font.save(out)
            print(f"{out.relative_to(ROOT)}  {out.stat().st_size // 1024} KB")
        lic = get(f"https://raw.githubusercontent.com/google/fonts/main/ofl/{folder}/OFL.txt")
        (licenses / f"{app_name}.txt").write_bytes(lic)


if __name__ == "__main__":
    main()

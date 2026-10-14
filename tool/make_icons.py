#!/usr/bin/env python3
# Discipline — app di calisthenics libera e gratuita.
# Copyright (C) 2026 Discipline contributors
# SPDX-License-Identifier: GPL-3.0-or-later
"""Disegna icona e splash di Discipline (un battito stilizzato) in assets/icon/.

Uso: python3 tool/make_icons.py
Poi: dart run flutter_launcher_icons && dart run flutter_native_splash:create
"""
from pathlib import Path

from PIL import Image, ImageDraw

OUT = Path(__file__).resolve().parent.parent / "assets" / "icon"
SIZE = 1024
SCALE = 4  # supercampionamento per bordi lisci

CORAL = (0x8F, 0x4C, 0x38, 255)
WHITE = (0xFF, 0xFF, 0xFF, 255)
PEACH = (0xFF, 0xB5, 0xA0, 255)

# Battito: piatto, picco in su, picco in giù, piatto (coordinate 0–1).
PULSE = [(0.22, 0.52), (0.37, 0.52), (0.46, 0.27), (0.57, 0.75),
         (0.65, 0.52), (0.78, 0.52)]


def glyph(color, scale=1.0, stroke=0.075):
    """Il battito su fondo trasparente, ridotto di `scale` attorno al centro."""
    s = SIZE * SCALE
    img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    pts = [((0.5 + (x - 0.5) * scale) * s, (0.5 + (y - 0.5) * scale) * s)
           for x, y in PULSE]
    w = int(stroke * scale * s)
    d.line(pts, fill=color, width=w, joint="curve")
    r = w / 2
    for x, y in pts:
        d.ellipse((x - r, y - r, x + r, y + r), fill=color)
    return img


def down(img):
    return img.resize((SIZE, SIZE), Image.LANCZOS)


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    # Icona piena (iOS e Android vecchi): fondo corallo, battito bianco.
    full = Image.new("RGBA", (SIZE * SCALE,) * 2, CORAL)
    full.alpha_composite(glyph(WHITE))
    down(full).convert("RGB").save(OUT / "icon.png")
    # Icona adattiva Android: il battito deve stare nel 66% centrale.
    down(glyph(WHITE, scale=0.8)).save(OUT / "icon_foreground.png")
    # Splash: battito corallo (chiaro) e pesca (scuro).
    down(glyph(CORAL, scale=0.7)).save(OUT / "splash.png")
    down(glyph(PEACH, scale=0.7)).save(OUT / "splash_dark.png")
    print("Creati:", ", ".join(sorted(p.name for p in OUT.iterdir())))


if __name__ == "__main__":
    main()

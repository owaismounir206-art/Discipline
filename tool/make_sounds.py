#!/usr/bin/env python3
# Discipline — app di calisthenics libera e gratuita.
# Copyright (C) 2026 Discipline contributors
# SPDX-License-Identifier: GPL-3.0-or-later
"""Crea i suoni dell'app in assets/sounds/, sintetizzati da zero.

Niente campioni presi altrove: sono toni morbidi (marimba, campanella)
generati qui, quindi con la stessa licenza del progetto.

Uso: python3 tool/make_sounds.py
"""
import wave
from pathlib import Path

import numpy as np

OUT = Path(__file__).resolve().parent.parent / "assets" / "sounds"
RATE = 44100

# Note (Hz).
F4, A4 = 349.23, 440.0
C5, E5, G5 = 523.25, 659.25, 783.99
C6, E6, G6 = 1046.5, 1318.5, 1567.98
C7, E7 = 2093.0, 2637.0


def _t(seconds):
    return np.arange(int(RATE * seconds)) / RATE


def tone(freq, length, decay, partials=((1, 1.0),), attack=0.004, glide=None):
    """Nota con attacco morbido e coda esponenziale.

    partials: (multiplo, ampiezza); gli armonici alti si spengono prima.
    glide: (da, tau) per una piccola discesa di intonazione (effetto "pop").
    """
    t = _t(length)
    out = np.zeros_like(t)
    for mult, amp in partials:
        f = np.full_like(t, freq * mult)
        if glide:
            start, tau = glide
            f = f * (1 + (start - 1) * np.exp(-t / tau))
        phase = 2 * np.pi * np.cumsum(f) / RATE
        out += amp * np.sin(phase) * np.exp(-t / (decay / mult**0.5))
    env = np.minimum(1, t / attack)
    env = 0.5 - 0.5 * np.cos(np.pi * env)  # attacco a coseno: niente click
    return out * env


def marimba(freq, length=0.4, decay=0.09):
    return tone(freq, length, decay, ((1, 1.0), (3.93, 0.18), (9.2, 0.03)))


def bell(freq, length=1.2, decay=0.35):
    return tone(freq, length, decay, ((1, 1.0), (2.0, 0.22), (3.0, 0.07), (4.2, 0.03)))


def mix(length, *parts):
    """Somma suoni con il loro ritardo: mix(1.0, (0, a), (0.1, b))."""
    out = np.zeros(int(RATE * length))
    for delay, sound in parts:
        start = int(RATE * delay)
        end = min(len(out), start + len(sound))
        out[start:end] += sound[: end - start]
    return out


def lowpass(x, cutoff):
    a = np.exp(-2 * np.pi * cutoff / RATE)
    y = np.zeros_like(x)
    prev = 0.0
    for i, v in enumerate(x):
        prev = (1 - a) * v + a * prev
        y[i] = prev
    return y


def room(x, wet=0.18):
    """Un po' di stanza: qualche eco breve e smorzata, per un suono morbido."""
    out = x.copy()
    for ms, gain in ((23, 0.6), (37, 0.45), (53, 0.35), (79, 0.25), (113, 0.15)):
        d = int(RATE * ms / 1000)
        out[d:] += wet * gain * lowpass(x, 3000)[:-d]
    return out


def save(name, x, peak):
    x = x / np.max(np.abs(x)) * peak
    fade = int(RATE * 0.012)
    x[-fade:] *= np.linspace(1, 0, fade)
    data = (x * 32767).astype("<i2").tobytes()
    with wave.open(str(OUT / name), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(data)


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    # Tocco: un "pop" corto e basso, come una goccia.
    save("tocco.wav", tone(620, 0.07, 0.014, ((1, 1), (2, 0.15)), attack=0.0015, glide=(1.6, 0.008)), 0.16)
    # Scelta (barra in basso, selettori): una nota di marimba leggera.
    save("scelta.wav", marimba(C6, 0.16, 0.035), 0.13)
    # Interruttore acceso / spento: due note che salgono o scendono.
    save("attiva.wav", mix(0.22, (0, marimba(G5, 0.15, 0.04)), (0.055, marimba(C6, 0.16, 0.045))), 0.14)
    save("disattiva.wav", mix(0.22, (0, marimba(C6, 0.15, 0.04)), (0.055, marimba(G5, 0.16, 0.045))), 0.13)
    # Fatto (serie completata, cibo aggiunto): quinta di campanella.
    save("fatto.wav", room(mix(0.7, (0, bell(E5, 0.6, 0.16)), (0.07, bell(C6 * 0.944, 0.6, 0.18)))), 0.22)
    # Allenamento completato: arpeggio maggiore che si posa.
    save("completato.wav", room(mix(1.7, *[(i * 0.11, bell(f, 1.4, 0.42)) for i, f in enumerate((C5, E5, G5, C6))]), 0.25), 0.26)
    # Festa (grado nuovo, medaglia): arpeggio più alto con un luccichio.
    shimmer = mix(1.9, *[(0.3 + i * 0.06, tone(f, 1.2, 0.3) * 0.25) for i, f in enumerate((C7, E7, G6 * 2, C7 * 1.5))])
    save("festa.wav", room(mix(1.9, *[(i * 0.075, bell(f, 1.5, 0.45)) for i, f in enumerate((G5, C6, E6, G6))]) + shimmer, 0.25), 0.26)
    # Errore: due note basse e attutite, senza allarmare.
    save("errore.wav", lowpass(mix(0.35, (0, marimba(A4, 0.25, 0.07)), (0.09, marimba(F4, 0.26, 0.08))), 1800), 0.18)
    # Timer: bip degli ultimi secondi e fine recupero (si devono sentire).
    save("bip.wav", tone(E6, 0.12, 0.03, ((1, 1), (2, 0.1))), 0.22)
    save("fine_recupero.wav", room(mix(1.5, *[(i * 0.16, bell(f, 1.2, 0.4)) for i, f in enumerate((E5, G5, C6))]), 0.2), 0.32)


if __name__ == "__main__":
    main()

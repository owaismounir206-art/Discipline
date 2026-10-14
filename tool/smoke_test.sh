#!/usr/bin/env bash
# Discipline — app di calisthenics libera e gratuita.
# Copyright (C) 2026 Discipline contributors
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Installa l'APK, apre l'app e verifica che dopo 25 secondi sia ancora viva.
set -u
APK="$1"
PKG=io.github.owaismounir206art.discipline
adb logcat -c
adb install -r "$APK" || exit 1
adb shell monkey -p "$PKG" -c android.intent.category.LAUNCHER 1
sleep 25
adb logcat -d > logcat.txt
echo "===== Errori ====="
grep -E "FATAL|AndroidRuntime|E/flutter|libc.*Fatal|DEBUG +:|UnsatisfiedLink|ClassNotFound|NoSuchMethod" logcat.txt | head -80
if adb shell pidof "$PKG" >/dev/null; then
  echo "OK: l'app è ancora aperta dopo 25 secondi."
else
  echo "ERRORE: l'app si è chiusa."
  exit 1
fi

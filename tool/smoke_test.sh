#!/usr/bin/env bash
# Discipline — app di calisthenics libera e gratuita.
# Copyright (C) 2026 Discipline contributors
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Installa l'APK, apre l'app, tocca qualche punto e verifica che dopo
# circa 30 secondi sia ancora viva.
set -u
APK="$1"
PKG=io.github.owaismounir206art.discipline
adb logcat -c
adb install -r "$APK" || exit 1
adb shell monkey -p "$PKG" -c android.intent.category.LAUNCHER 1
sleep 20
# Qualche tocco e uno scorrimento: i suoni dei tocchi non devono rompere nulla.
for xy in "540 1200" "540 1600" "300 900"; do
  adb shell input tap $xy
  sleep 1
done
adb shell input swipe 540 1600 540 600 300
sleep 5
adb logcat -d > logcat.txt
echo "===== Errori ====="
grep -E "FATAL|AndroidRuntime|E/flutter|audioplayers|libc.*Fatal|DEBUG +:|UnsatisfiedLink|ClassNotFound|NoSuchMethod" logcat.txt | head -80
if adb shell pidof "$PKG" >/dev/null; then
  echo "OK: l'app è ancora aperta dopo i tocchi."
else
  echo "ERRORE: l'app si è chiusa."
  exit 1
fi

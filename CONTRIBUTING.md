# Contribuire a Discipline

Grazie per voler aiutare! Discipline è libera e gratuita e lo resterà: ogni
contributo è distribuito con la stessa licenza del progetto (GPL-3.0 o
successiva).

## Come aiutare

- **Segnalare un problema**: apri una issue con il modello "Segnala un
  problema".
- **Proporre un'idea**: apri una issue con il modello "Proponi un'idea".
- **Scrivere codice**: scegli una issue, scrivi un commento per dire che ci
  lavori, poi apri una pull request.

## Preparare l'ambiente

1. Installa [Flutter](https://docs.flutter.dev/get-started/install) stabile.
2. `flutter pub get`
3. `flutter run` per avviare l'app, `flutter test` per i test.

## Regole del codice

- Una cartella per funzione: `lib/features/<nome>/`. Ciò che è condiviso va
  in `lib/core/`.
- Stato con Riverpod, navigazione con go_router, interfaccia Material 3
  (`package:material_ui`).
- Usa i colori del tema (`Theme.of(context).colorScheme`), mai colori scritti
  a mano nelle schermate.
- Testi dell'interfaccia in italiano; ogni icona cliccabile ha un `tooltip`
  o un'etichetta per lo screen reader; aree di tocco di almeno 48 dp.
- La logica (streak, livelli, nutrizione, conteggio ripetizioni) ha sempre
  unit test.
- Ogni file inizia con l'intestazione della licenza:

  ```dart
  // Discipline — app di calisthenics libera e gratuita.
  // Copyright (C) 2026 Discipline contributors
  // SPDX-License-Identifier: GPL-3.0-or-later
  ```

- I servizi non liberi (es. Firebase, ML Kit) stanno dietro un'interfaccia,
  così si può fare una versione 100% libera (es. per F-Droid).

## Prima di aprire una pull request

```sh
dart format lib test tool
flutter analyze
flutter test
```

La GitHub Action esegue gli stessi controlli a ogni push.

## Segreti

Il repository è pubblico: **mai** chiavi, password o dati personali nel
codice. I file di configurazione con segreti sono elencati in `.gitignore`;
per ognuno c'è (o ci sarà) un file `.example` che spiega cosa inserire.

## Screenshot del README

```sh
flutter test --update-goldens tool/screenshots_test.dart
```

---

## English summary

Contributions are welcome under the GPL-3.0-or-later license. Run
`dart format lib test tool`, `flutter analyze` and `flutter test` before
opening a pull request. Keep features in `lib/features/<name>/`, use theme
colors, label every icon for screen readers and never commit secrets.

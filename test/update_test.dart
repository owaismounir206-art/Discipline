// Discipline — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Discipline contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'dart:io';

import 'package:flutter/foundation.dart' show TargetPlatform;
import 'package:flutter_test/flutter_test.dart';
import 'package:discipline/core/data/database.dart';
import 'package:discipline/core/update/update_card.dart';
import 'package:discipline/core/update/update_checker.dart';

import 'helpers.dart';

final _next = Release(
  version: '9.1.0',
  notes: '## Novità\n\n- **Nuovo** percorso\n- Timer EMOM\n\nAltro testo',
  page: Uri.parse('https://github.com/x/y/releases/tag/v9.1.0'),
  apk: Uri.parse('https://github.com/x/y/releases/download/v9.1.0/a.apk'),
);

void main() {
  test('la versione nel codice è quella di pubspec.yaml', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final version = RegExp(
      r'^version: ([0-9.]+)\+',
      multiLine: true,
    ).firstMatch(pubspec)!.group(1);
    expect(appVersion, version);
  });

  test('confronto delle versioni', () {
    expect(compareVersions('1.0.0', '1.0.0'), 0);
    expect(compareVersions('1.2.0', '1.10.0'), lessThan(0));
    expect(compareVersions('2.0', '1.9.9'), greaterThan(0));
    expect(compareVersions('1.0.1-beta', '1.0.0'), greaterThan(0));
  });

  test('legge la risposta di GitHub e le novità', () {
    final r = Release.fromGitHub({
      'tag_name': 'v1.2.0',
      'html_url': 'https://github.com/a/b/releases/tag/v1.2.0',
      'body': '- uno\n- `due`',
      'assets': [
        {'name': 'note.txt', 'browser_download_url': 'https://x/note.txt'},
        {'name': 'discipline.apk', 'browser_download_url': 'https://x/d.apk'},
      ],
    })!;
    expect(r.version, '1.2.0');
    expect(r.apk.toString(), 'https://x/d.apk');
    expect(r.highlights, ['uno', 'due']);
    expect(_next.highlights, ['Nuovo percorso', 'Timer EMOM']);
    // Su iPhone si apre la pagina della release, non l'APK.
    expect(_next.downloadFor(TargetPlatform.android), _next.apk);
    expect(_next.downloadFor(TargetPlatform.iOS), _next.page);
  });

  group('controllo', () {
    late AppDatabase db;
    late FakeReleases source;
    var now = DateTime(2026, 10, 15, 9);
    UpdateRepository repo() => UpdateRepository(db, source, () => now);

    setUp(() {
      db = memoryDatabase();
      source = FakeReleases(_next);
      now = DateTime(2026, 10, 15, 9);
    });
    tearDown(() => db.close());

    test(
      'una volta al giorno, e "Più tardi" nasconde quella versione',
      () async {
        expect((await repo().check())?.version, '9.1.0');
        expect(await repo().check(), isNotNull);
        expect(source.calls, 1);
        now = now.add(const Duration(hours: 25));
        await repo().check();
        expect(source.calls, 2);

        await repo().dismiss('9.1.0');
        expect(await repo().check(), isNull);
        // Il controllo manuale la mostra comunque.
        expect(await repo().check(force: true), isNotNull);
      },
    );

    test('spento non chiede niente; versioni vecchie si ignorano', () async {
      await repo().setEnabled(false);
      expect(await repo().check(), isNull);
      expect(source.calls, 0);
      await repo().setEnabled(true);
      source.release = Release(
        version: appVersion,
        notes: '',
        page: Uri.parse('https://x'),
      );
      expect(await repo().check(), isNull);
    });
  });

  testWidgets('la scheda in Oggi apre il download o si nasconde', (
    tester,
  ) async {
    final db = memoryDatabase();
    await tester.runAsync(() => seedProfile(db));
    final opened = <Uri>[];
    await pumpDiscipline(
      tester,
      db,
      releases: FakeReleases(_next),
      extra: [
        openLinkProvider.overrideWithValue((uri) async {
          opened.add(uri);
          return true;
        }),
      ],
    );
    expect(find.text('Discipline 9.1.0 è pronta'), findsOneWidget);
    expect(find.text('• Timer EMOM'), findsOneWidget);
    await tester.tap(find.text('Scarica'));
    expect(opened.single, _next.apk);

    await tester.tap(find.text('Più tardi'));
    await settle(tester);
    expect(find.text('Discipline 9.1.0 è pronta'), findsNothing);
    await disposeDiscipline(tester, db);
  });
}

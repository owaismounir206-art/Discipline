// Discipline — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Discipline contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:discipline/core/router/routes.dart';
import 'package:discipline/core/widgets/motion_widgets.dart';
import 'package:discipline/features/food/data/ai_food.dart';
import 'package:discipline/features/food/domain/foods.dart';
import 'package:discipline/features/food/domain/nutrition.dart';
import 'package:material_ui/material_ui.dart';

import 'helpers.dart';

const _reply =
    '{"items":[{"name":"Uova strapazzate","grams":110,"kcal":150,'
    '"protein":11,"carbs":1,"fat":11,"sugar":0.5,"meal":"breakfast"},'
    '{"name":"Pane integrale","grams":35,"kcal":240,"protein":9,'
    '"carbs":46,"fat":2,"sugar":3,"meal":"breakfast"},'
    '{"name":"Errore","grams":10,"kcal":5000,"protein":1,"carbs":1,"fat":1}]}';

http.Response _json(Object body, [int code = 200]) => http.Response.bytes(
  utf8.encode(jsonEncode(body)),
  code,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

/// Server finto di Groq e Gemini.
MockClient fakeAi({int status = 200, List<http.Request>? log}) =>
    MockClient((request) async {
      log?.add(request);
      if (status != 200) return http.Response('{}', status);
      final url = request.url.toString();
      if (url.endsWith('/openai/v1/models')) {
        return _json({
          'data': [
            {'id': 'whisper-large-v3'},
            {'id': 'openai/gpt-oss-120b'},
            {'id': 'llama-3.3-70b-versatile'},
          ],
        });
      }
      if (url.contains('/v1beta/models?')) {
        return _json({
          'models': [
            {
              'name': 'models/gemini-9-flash',
              'supportedGenerationMethods': ['generateContent'],
            },
            {
              'name': 'models/text-embedding',
              'supportedGenerationMethods': ['embedContent'],
            },
          ],
        });
      }
      if (url.endsWith('/chat/completions')) {
        return _json({
          'choices': [
            {
              'message': {'content': _reply},
            },
          ],
        });
      }
      if (url.contains(':generateContent')) {
        return _json({
          'candidates': [
            {
              'content': {
                'parts': [
                  {'text': '```json\n$_reply\n```'},
                ],
              },
            },
          ],
        });
      }
      return http.Response('?', 404);
    });

void main() {
  test('risposta dell\'AI: valori impossibili scartati', () {
    final foods = parseAiFoods(_reply);
    expect(foods.map((f) => f.food.name), [
      'Uova strapazzate',
      'Pane integrale',
    ]);
    expect(foods.first.grams, 110);
    expect(foods.first.meal, Meal.breakfast);
    expect(foods.first.food.source, FoodSource.ai);
    expect(parseAiFoods('{"items":[]}'), isEmpty);
    expect(() => parseAiFoods('non è json'), throwsA(isA<AiException>()));
  });

  test('scelta del modello quando quello proposto non c\'è più', () {
    expect(
      AiFoodService.pickModel(AiProvider.groq, ['a', 'llama-3.3-70b-new']),
      'llama-3.3-70b-new',
    );
    expect(
      AiFoodService.pickModel(AiProvider.gemini, ['gemini-9-flash']),
      'gemini-9-flash',
    );
  });

  for (final provider in AiProvider.values) {
    test('${provider.label}: prova chiave e analisi', () async {
      final db = memoryDatabase();
      addTearDown(db.close);
      final log = <http.Request>[];
      final secrets = MemorySecrets();
      final ai = AiFoodService(db, secrets, client: fakeAi(log: log));

      final models = await ai.models(provider, 'chiave-segreta');
      expect(models, isNotEmpty);
      expect(models.any((m) => m.contains('whisper')), isFalse);
      await ai.saveKey(provider, 'chiave-segreta');
      await ai.saveSettings(
        AiSettings(provider: provider, model: models.first),
      );
      expect(await ai.isReady(), isTrue);

      final foods = await ai.analyze('due uova e una fetta di pane');
      expect(foods, hasLength(2));
      // La chiave viaggia nell'intestazione, mai nell'indirizzo.
      final last = log.last;
      expect(last.url.toString(), isNot(contains('chiave-segreta')));
      expect(last.headers.values.join(' '), contains('chiave-segreta'));
      expect(last.body, contains('due uova'));
      // La chiave non sta nel database (quindi neanche nei backup).
      expect(jsonEncode(await db.exportAll()), isNot(contains('chiave')));
    });
  }

  test('chiave sbagliata o limite raggiunto: messaggi chiari', () async {
    final db = memoryDatabase();
    addTearDown(db.close);
    for (final (code, text) in [(401, 'chiave'), (429, 'Limite')]) {
      final ai = AiFoodService(
        db,
        MemorySecrets(),
        client: fakeAi(status: code),
      );
      await expectLater(
        ai.models(AiProvider.groq, 'x'),
        throwsA(
          isA<AiException>().having(
            (e) => e.message,
            'message',
            contains(text),
          ),
        ),
      );
    }
  });

  testWidgets('scrivi cosa hai mangiato, controlla e salva', (tester) async {
    final db = memoryDatabase();
    await tester.runAsync(() => seedProfile(db));
    final secrets = MemorySecrets();
    final service = AiFoodService(db, secrets, client: fakeAi());
    await tester.runAsync(() async {
      await service.saveKey(AiProvider.groq, 'k');
      await service.saveSettings(const AiSettings(provider: AiProvider.groq));
    });
    await pumpDiscipline(
      tester,
      db,
      extra: [aiFoodServiceProvider.overrideWithValue(service)],
    );
    final context = tester.element(find.byType(DisciplineNavigationBar));
    unawaited(GoRouter.of(context).push(Routes.aiFood, extra: Meal.lunch));
    await settle(tester);

    await tester.enterText(find.byType(TextField), 'due uova e pane');
    await tester.tap(find.text('Analizza'));
    await settle(tester);
    expect(find.text('Uova strapazzate'), findsOneWidget);
    // Il pasto scritto nel testo vince su quello proposto.
    await tester.scrollUntilVisible(
      find.textContaining('alla colazione'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await settle(tester);
    expect(find.textContaining('alla colazione'), findsOneWidget);

    // Tolgo il pane.
    await tester.tap(find.text('Pane integrale'));
    await settle(tester);
    final save = find.textContaining('Aggiungi 1 alimento');
    await tester.ensureVisible(save);
    await settle(tester);
    await tester.tap(save);
    await settle(tester);

    final rows = await tester.runAsync(() => db.select(db.foodEntries).get());
    expect(rows!.single.name, 'Uova strapazzate');
    expect(rows.single.meal, 'breakfast');
    expect(rows.single.source, 'ai');
    await disposeDiscipline(tester, db);
  });

  testWidgets('impostazioni: incolla la chiave, provala, scegli il modello', (
    tester,
  ) async {
    final db = memoryDatabase();
    await tester.runAsync(() => seedProfile(db));
    final secrets = MemorySecrets();
    final service = AiFoodService(db, secrets, client: fakeAi());
    await pumpDiscipline(
      tester,
      db,
      extra: [aiFoodServiceProvider.overrideWithValue(service)],
    );
    final context = tester.element(find.byType(DisciplineNavigationBar));
    unawaited(GoRouter.of(context).push(Routes.aiSettings));
    await settle(tester);

    await tester.enterText(find.byType(TextField), 'gsk_prova');
    await tester.tap(find.text('Prova la chiave'));
    await settle(tester);
    expect(find.textContaining('Chiave valida'), findsOneWidget);
    expect(find.text('llama-3.3-70b-versatile'), findsOneWidget);
    expect(secrets.values.values, ['gsk_prova']);

    await tester.ensureVisible(find.text('Cancella la chiave'));
    await settle(tester);
    await tester.tap(find.text('Cancella la chiave'));
    await settle(tester);
    expect(secrets.values, isEmpty);
    await disposeDiscipline(tester, db);
  });
}

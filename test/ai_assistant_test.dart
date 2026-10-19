// Discipline — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Discipline contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:discipline/core/router/routes.dart';
import 'package:discipline/core/widgets/motion_widgets.dart';
import 'package:discipline/features/ai/ai_assistant.dart';
import 'package:discipline/features/food/data/ai_food.dart';
import 'package:discipline/features/food/domain/nutrition.dart';
import 'package:discipline/features/food/presentation/homemade_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:material_ui/material_ui.dart';

import 'helpers.dart';

const _recipe =
    '{"name":"Pollo al limone con riso","minutes":25,"ingredients":['
    '{"name":"Petto di pollo","grams":150,"kcal":100,"protein":23,'
    '"carbs":0,"fat":1,"sugar":0},'
    '{"name":"Riso basmati","grams":80,"kcal":350,"protein":7,"carbs":78,'
    '"fat":1,"sugar":0},'
    '{"name":"Sbagliato","grams":10,"kcal":9000,"protein":0,"carbs":0,'
    '"fat":0}],'
    '"steps":["Cuoci il riso.","Rosola il pollo con il limone."],'
    '"why":"Ti mancano proteine."}';

http.Response _json(Object body) => http.Response.bytes(
  utf8.encode(jsonEncode(body)),
  200,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

/// Server finto: risponde [reply] a ogni domanda.
MockClient _fake(
  String reply, {
  List<http.Request>? log,
  List<String> groqModels = const ['llama-3.3-70b-versatile'],
}) => MockClient((request) async {
  log?.add(request);
  final url = request.url.toString();
  if (url.endsWith('/openai/v1/models')) {
    return _json({
      'data': [
        for (final m in groqModels) {'id': m},
      ],
    });
  }
  if (url.endsWith('/chat/completions')) {
    return _json({
      'choices': [
        {
          'message': {'content': reply},
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
              {'text': reply},
            ],
          },
        },
      ],
    });
  }
  return http.Response('?', 404);
});

Future<AiFoodService> _service(
  AiProvider p,
  MockClient client, {
  bool keep = false,
}) async {
  final db = memoryDatabase();
  if (!keep) addTearDown(db.close);
  final ai = AiFoodService(db, MemorySecrets(), client: client);
  await ai.saveKey(p, 'k');
  await ai.saveSettings(AiSettings(provider: p));
  return ai;
}

final _photo = Uint8List.fromList([1, 2, 3, 4]);

void main() {
  test('ricetta dell\'AI: ingredienti impossibili scartati', () {
    final r = parseAiRecipe(_recipe);
    expect(r.name, 'Pollo al limone con riso');
    expect(r.minutes, 25);
    expect(r.ingredients.map((i) => i.food.name), [
      'Petto di pollo',
      'Riso basmati',
    ]);
    expect(r.steps, hasLength(2));
    expect(r.total.protein.round(), 40);
    expect(r.toHomemade().ingredients, hasLength(2));
    expect(() => parseAiRecipe('niente'), throwsA(isA<AiException>()));
    expect(
      () => parseAiRecipe('{"name":"x","ingredients":[]}'),
      throwsA(isA<AiException>()),
    );
  });

  test('il riassunto per l\'AI ha i numeri utili ma non il nome', () {
    final text = describeAthlete(
      level: 'Intermedio',
      days: 3,
      place: 'Al parco',
      variants: const ['Spinta: Push-up'],
      body: const BodyProfile(
        sex: Sex.male,
        age: 30,
        weightKg: 75,
        heightCm: 180,
        goal: Goal.bulk,
        allergies: {Allergen.lactose},
      ),
      eaten: const Nutrients(kcal: 800, protein: 40),
      streak: 5,
    );
    expect(text, contains('Intermedio'));
    expect(text, contains('75 kg'));
    expect(text, contains('latte e lattosio'));
    expect(text, contains('800 kcal'));
    expect(text, contains('Push-up'));
  });

  test('Gemini: la foto va con la domanda', () async {
    final log = <http.Request>[];
    final ai = await _service(
      AiProvider.gemini,
      _fake('{"items":[{"name":"Pasta","grams":200,"kcal":150}]}', log: log),
    );
    final foods = await ai.analyze('', image: _photo);
    expect(foods.single.food.name, 'Pasta');
    expect(log.last.body, contains('inline_data'));
    expect(log.last.body, contains(base64Encode(_photo)));
  });

  test('Groq: per la foto sceglie un modello che vede', () async {
    final log = <http.Request>[];
    final ai = await _service(
      AiProvider.groq,
      _fake(
        '{"items":[]}',
        log: log,
        groqModels: const [
          'llama-3.3-70b-versatile',
          'meta-llama/llama-4-scout-17b-16e-instruct',
        ],
      ),
    );
    await ai.analyze('', image: _photo);
    final body = jsonDecode(log.last.body) as Map;
    expect(body['model'], contains('llama-4-scout'));
    expect(log.last.body, contains('data:image/jpeg;base64'));

    // Senza modelli "vision" lo dice chiaramente.
    final blind = await _service(AiProvider.groq, _fake('{"items":[]}'));
    await expectLater(
      blind.analyze('', image: _photo),
      throwsA(
        isA<AiException>().having(
          (e) => e.message,
          'message',
          contains('foto'),
        ),
      ),
    );
  });

  test('il coach riceve i tuoi dati e la conversazione', () async {
    final log = <http.Request>[];
    final ai = await _service(
      AiProvider.groq,
      _fake('Fai trazioni negative.', log: log),
    );
    final reply = await askCoach(ai, 'Livello: Intermedio', const [
      ChatMessage.user('Come miglioro le trazioni?'),
    ]);
    expect(reply, 'Fai trazioni negative.');
    final body = log.last.body;
    expect(body, contains('Livello: Intermedio'));
    expect(body, contains('Come miglioro le trazioni?'));
    expect(body, isNot(contains('response_format')));
  });

  testWidgets('coach: domanda con un tocco e risposta', (tester) async {
    final db = memoryDatabase();
    await tester.runAsync(() => seedProfile(db));
    final service = (await tester.runAsync(
      () => _service(
        AiProvider.groq,
        _fake('Prova le trazioni negative, 3 serie da 5.'),
        keep: true,
      ),
    ))!;
    await pumpDiscipline(
      tester,
      db,
      extra: [aiFoodServiceProvider.overrideWithValue(service)],
    );
    final context = tester.element(find.byType(DisciplineNavigationBar));
    unawaited(GoRouter.of(context).push(Routes.coach));
    await settle(tester);

    await tester.tap(find.text('Come miglioro le trazioni?'));
    await settle(tester);
    expect(find.text('Come miglioro le trazioni?'), findsOneWidget);
    expect(find.textContaining('trazioni negative'), findsOneWidget);
    await disposeDiscipline(tester, db);
  });

  testWidgets('cosa cucino: ricetta e apertura nell\'editor', (tester) async {
    final db = memoryDatabase();
    await tester.runAsync(() => seedProfile(db));
    final service = (await tester.runAsync(
      () => _service(AiProvider.gemini, _fake(_recipe), keep: true),
    ))!;
    await pumpDiscipline(
      tester,
      db,
      extra: [aiFoodServiceProvider.overrideWithValue(service)],
    );
    final context = tester.element(find.byType(DisciplineNavigationBar));
    unawaited(GoRouter.of(context).push(Routes.kitchen));
    await settle(tester);

    await tester.enterText(find.byType(TextField), 'pollo e riso');
    await tester.tap(find.text('Proponi una ricetta'));
    await settle(tester);
    expect(find.text('Pollo al limone con riso'), findsOneWidget);
    expect(find.text('Riso basmati'), findsOneWidget);

    final save = find.text('Salva tra le ricette di casa');
    await tester.ensureVisible(save);
    await settle(tester);
    await tester.tap(save);
    await settle(tester);
    expect(find.byType(HomemadeScreen), findsOneWidget);
    await disposeDiscipline(tester, db);
  });

  testWidgets('la mia scheda: l\'AI la legge e un giorno parte', (
    tester,
  ) async {
    final db = memoryDatabase();
    await tester.runAsync(() => seedProfile(db));
    const reply =
        '{"name":"La mia PPL","days":[{"name":"Giorno A","weekday":null,'
        '"exercises":[{"id":"push_classic","sets":3,"target":12,"rest":60,'
        '"original":"Piegamenti"},{"id":"inventato","sets":3,"target":5,'
        '"rest":60}]}],"notes":["Panca sostituita con push-up."]}';
    final service = (await tester.runAsync(
      () => _service(AiProvider.groq, _fake(reply), keep: true),
    ))!;
    await pumpDiscipline(
      tester,
      db,
      extra: [aiFoodServiceProvider.overrideWithValue(service)],
    );
    final context = tester.element(find.byType(DisciplineNavigationBar));
    unawaited(GoRouter.of(context).push(Routes.programs));
    await settle(tester);

    await tester.enterText(find.byType(TextField), 'Piegamenti 3x12');
    await tester.tap(find.text('Trasforma con l\'AI'));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await settle(tester);
    expect(find.text('La mia PPL'), findsOneWidget);
    expect(find.text('Push-up classici'), findsOneWidget);
    expect(find.textContaining('Panca sostituita'), findsOneWidget);
    expect(find.textContaining('nella scheda: Piegamenti'), findsOneWidget);

    await tester.ensureVisible(find.textContaining('Inizia'));
    await tester.tap(find.textContaining('Inizia'));
    for (var i = 0; i < 4; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Giorno A'), findsWidgets);
    expect(find.text('12'), findsWidgets);
    await disposeDiscipline(tester, db);
  });

  testWidgets('skill e allenamenti specifici si aprono', (tester) async {
    // Le figurine animate non lascerebbero mai finire settle.
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final db = memoryDatabase();
    await tester.runAsync(() => seedProfile(db));
    await pumpDiscipline(tester, db);
    final context = tester.element(find.byType(DisciplineNavigationBar));
    unawaited(GoRouter.of(context).push(Routes.skills));
    await settle(tester);
    expect(find.text('Le regole d\'oro'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Planche'), 300);
    await tester.ensureVisible(find.text('Planche'));
    await settle(tester);
    await tester.tap(find.text('Planche'));
    await settle(tester);
    expect(find.text('Le tappe'), findsOneWidget);
    await tester.scrollUntilVisible(find.textContaining('Allenati su'), 300);
    expect(find.textContaining('Allenati su'), findsOneWidget);

    unawaited(GoRouter.of(context).push(Routes.focus('biceps')));
    await settle(tester);
    expect(find.text('Bicipiti'), findsWidgets);
    expect(find.textContaining('Inizia ·'), findsOneWidget);
    await disposeDiscipline(tester, db);
  });
}

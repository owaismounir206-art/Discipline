// Discipline — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Discipline contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';

import '../exercises/domain/catalog.dart';
import '../food/data/ai_food.dart';
import '../food/data/food_repository.dart';
import '../food/data/food_state.dart';
import '../food/domain/homemade.dart';
import '../food/domain/nutrition.dart';
import '../profile/data/profile_repository.dart';
import '../workout/data/today_plan.dart';

/// Quello che l'AI sa di te: solo i numeri utili, mai il nome.
final aiContextProvider = Provider<String>((ref) {
  final profile = ref.watch(athleteProfileProvider).value;
  final body = ref.watch(bodyProfileProvider).value;
  final targets = ref.watch(targetsProvider);
  final eaten = ref.watch(todayTotalsProvider);
  final positions = ref.watch(positionsProvider);
  final streak = ref.watch(streakProvider).current;
  return describeAthlete(
    level: profile?.difficulty.label,
    days: profile?.trainingDays.length,
    place: profile?.place.label,
    variants: [
      for (final MapEntry(key: chain, value: i) in positions.entries)
        if (chain.isProgression)
          '${chain.label}: ${Catalog.chain(chain)[i].name}',
    ],
    body: body,
    targets: targets,
    eaten: eaten,
    streak: streak,
  );
});

/// Il riassunto in italiano che va all'AI insieme alla domanda.
String describeAthlete({
  String? level,
  int? days,
  String? place,
  List<String> variants = const [],
  BodyProfile? body,
  NutritionTargets? targets,
  Nutrients eaten = Nutrients.zero,
  int streak = 0,
}) {
  final lines = [
    if (level != null)
      'Livello: $level, $days allenamenti a settimana, si allena: $place.',
    if (variants.isNotEmpty) 'Varianti attuali: ${variants.join('; ')}.',
    if (body != null)
      'Corpo: ${body.age} anni, ${body.weightKg.round()} kg, '
          '${body.heightCm.round()} cm, obiettivo ${body.goal.short}, '
          'dieta ${body.diet.label.toLowerCase()}'
          '${body.allergies.isEmpty ? '' : ', allergie/intolleranze: ${body.allergies.map((a) => a.label.toLowerCase()).join(', ')}'}.',
    if (targets != null)
      'Obiettivo di oggi: ${targets.kcal.round()} kcal, proteine '
          '${targets.protein.round()} g, carboidrati ${targets.carbs.round()} '
          'g, grassi ${targets.fat.round()} g.',
    'Mangiato oggi: ${eaten.kcal.round()} kcal, proteine '
        '${eaten.protein.round()} g, carboidrati ${eaten.carbs.round()} g, '
        'grassi ${eaten.fat.round()} g.',
    'Serie di giorni rispettati: $streak.',
  ];
  return lines.join('\n');
}

const _coachPrompt = '''
Sei il coach di Discipline, un'app di calisthenics (allenamento a corpo
libero) e alimentazione. Rispondi in italiano, in modo chiaro, pratico e
incoraggiante, in poche frasi o con un breve elenco puntato. Usa i dati
dell'utente qui sotto quando servono. Non fare diagnosi mediche: per dolori
forti, infortuni o problemi di salute consiglia di sentire un medico o un
fisioterapista. Se la domanda non riguarda allenamento, recupero, sonno o
alimentazione, riporta gentilmente il discorso su questi temi.

Dati dell'utente:
''';

/// Il coach: risponde tenendo conto dei tuoi dati.
Future<String> askCoach(
  AiFoodService ai,
  String context,
  List<ChatMessage> history,
) async {
  final reply = await ai.complete(
    system: '$_coachPrompt$context',
    history: history,
    temperature: 0.6,
  );
  final text = reply.trim();
  if (text.isEmpty) throw const AiException('L\'AI non ha risposto: riprova.');
  return text;
}

const _kitchenPrompt = '''
Sei un cuoco italiano esperto di nutrizione sportiva. Proponi UNA ricetta
semplice per il prossimo pasto dell'utente, adatta ai valori che gli mancano
per oggi, alla sua dieta e alle sue allergie (se ne ha, non usare mai quegli
ingredienti). Se l'utente dice cosa ha in casa, usa soprattutto quello.
Per ogni ingrediente indica i grammi (crudi) per UNA porzione e i valori
nutrizionali PER 100 g, da tabelle come CREA o USDA.
Rispondi SOLO con JSON valido in questo formato:
{"name":"Pollo al limone con riso","minutes":25,"ingredients":[{"name":"Petto
di pollo","grams":150,"kcal":100,"protein":23,"carbs":0,"fat":1,"sugar":0}],
"steps":["Cuoci il riso...","..."],"why":"Una frase sul perché va bene oggi"}

Dati dell'utente:
''';

/// Una ricetta proposta dall'AI.
@immutable
class AiRecipe {
  const AiRecipe({
    required this.name,
    required this.minutes,
    required this.ingredients,
    required this.steps,
    this.why,
  });

  final String name;
  final int? minutes;
  final List<Ingredient> ingredients;
  final List<String> steps;
  final String? why;

  Nutrients get total =>
      ingredients.fold(Nutrients.zero, (sum, i) => sum + i.nutrients);

  /// Da aprire nell'editor delle ricette di casa (una porzione).
  HomemadeRecipe toHomemade() =>
      HomemadeRecipe(name: name, ingredients: ingredients);
}

/// "Cosa cucino?": una ricetta per i valori che mancano oggi.
Future<AiRecipe> suggestRecipe(
  AiFoodService ai,
  String context,
  String request,
) async {
  final reply = await ai.complete(
    system: '$_kitchenPrompt$context',
    json: true,
    temperature: 0.7,
    history: [
      ChatMessage.user(
        request.trim().isEmpty
            ? 'Cosa posso cucinare per il prossimo pasto?'
            : request.trim(),
      ),
    ],
  );
  return parseAiRecipe(reply);
}

/// Legge la ricetta. Gli ingredienti con valori impossibili si scartano.
AiRecipe parseAiRecipe(String reply) {
  final start = reply.indexOf('{');
  final end = reply.lastIndexOf('}');
  Object? json;
  if (start >= 0 && end > start) {
    try {
      json = jsonDecode(reply.substring(start, end + 1));
    } on FormatException {
      json = null;
    }
  }
  if (json is! Map) {
    throw const AiException('Risposta dell\'AI non leggibile: riprova.');
  }
  final foods = parseAiFoods(jsonEncode({'items': json['ingredients']}));
  final name = '${json['name'] ?? ''}'.trim();
  if (name.isEmpty || foods.isEmpty) {
    throw const AiException('L\'AI non ha proposto una ricetta: riprova.');
  }
  final minutes = json['minutes'];
  final why = json['why'];
  return AiRecipe(
    name: name.length > 60 ? name.substring(0, 60) : name,
    minutes: minutes is num && minutes > 0 ? minutes.round() : null,
    ingredients: [for (final f in foods) Ingredient(f.food, f.grams)],
    steps: [
      for (final s in (json['steps'] as List?) ?? const [])
        if ('$s'.trim().isNotEmpty) '$s'.trim(),
    ],
    why: why is String && why.trim().isNotEmpty ? why.trim() : null,
  );
}

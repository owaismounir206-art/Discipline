// Discipline — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Discipline contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';

import '../../../core/data/database.dart';
import '../../../core/data/providers.dart';
import '../domain/foods.dart';
import '../domain/nutrition.dart';

/// Servizi di intelligenza artificiale che si possono usare con la propria
/// chiave (gratuita, creata dall'utente). Discipline non ha chiavi sue.
enum AiProvider {
  groq(
    'Groq',
    'console.groq.com/keys',
    'https://console.groq.com/keys',
    'llama-3.3-70b-versatile',
  ),
  gemini(
    'Google AI Studio',
    'aistudio.google.com/apikey',
    'https://aistudio.google.com/apikey',
    'gemini-2.5-flash',
  );

  const AiProvider(this.label, this.keyHint, this.keyUrl, this.defaultModel);

  final String label;
  final String keyHint;
  final String keyUrl;

  /// Modello proposto: i nomi cambiano spesso, per questo "Prova la chiave"
  /// scarica l'elenco aggiornato e se serve ne sceglie un altro.
  final String defaultModel;
}

/// Impostazioni (la chiave no: sta nel portachiavi del telefono).
@immutable
class AiSettings {
  const AiSettings({this.provider, this.model});

  final AiProvider? provider;
  final String? model;

  String? get modelOrDefault => model ?? provider?.defaultModel;

  Map<String, Object?> toJson() => {'provider': provider?.name, 'model': model};

  static AiSettings fromJson(Object? json) {
    if (json is! Map) return const AiSettings();
    return AiSettings(
      provider: AiProvider.values.asNameMap()[json['provider']],
      model: json['model'] as String?,
    );
  }
}

class AiException implements Exception {
  const AiException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Un alimento riconosciuto dall'AI, da confermare prima di salvarlo.
@immutable
class AiFood {
  const AiFood({required this.food, required this.grams, this.meal});

  final FoodItem food;
  final double grams;
  final Meal? meal;

  AiFood withGrams(double g) => AiFood(food: food, grams: g, meal: meal);
}

/// Dove sta la chiave. Nei test è in memoria.
abstract interface class SecretStore {
  Future<String?> read(String key);
  Future<void> write(String key, String? value);
}

class DeviceSecretStore implements SecretStore {
  static const _storage = FlutterSecureStorage();

  @override
  Future<String?> read(String key) async {
    try {
      return await _storage.read(key: key);
    } on Object {
      return null;
    }
  }

  @override
  Future<void> write(String key, String? value) => value == null
      ? _storage.delete(key: key)
      : _storage.write(key: key, value: value);
}

const _prompt = '''
Sei un nutrizionista italiano. L'utente descrive cosa ha mangiato.
Per ogni alimento indica il nome in italiano, la quantità in grammi (se non è
indicata usa una porzione tipica italiana: es. un uovo 55 g, una fetta di pane
35 g, un piatto di pasta 80 g di pasta cruda o 200 g cotta, un cucchiaio
d'olio 10 g) e i valori nutrizionali PER 100 g, da tabelle come CREA o USDA.
Separa i piatti composti nei loro ingredienti principali solo se è chiaro;
altrimenti usa valori medi del piatto.
Se l'utente dice il pasto (colazione, pranzo, cena, spuntino) indicalo.
Rispondi SOLO con JSON valido, senza testo prima o dopo, in questo formato:
{"items":[{"name":"Uova","grams":110,"kcal":143,"protein":12.6,"carbs":0.7,
"fat":9.5,"sugar":0.4,"meal":"breakfast"}]}
"meal" può essere "breakfast", "lunch", "dinner", "snack" oppure null.
Se il testo non parla di cibo rispondi {"items":[]}.''';

/// Chiama Groq o Gemini con la chiave dell'utente.
class AiFoodService {
  AiFoodService(this._db, this._secrets, {http.Client? client})
    : _client = client ?? http.Client();

  final AppDatabase _db;
  final SecretStore _secrets;
  final http.Client _client;

  static const settingsKey = 'ai';
  static const _offline = AiException(
    'Sei offline? Serve internet per usare l\'AI.',
  );
  static String _secretName(AiProvider p) => 'ai_key_${p.name}';

  Stream<AiSettings> watchSettings() =>
      _db.watchJson(settingsKey).map(AiSettings.fromJson);

  Future<AiSettings> settings() async =>
      AiSettings.fromJson(await _db.readJson(settingsKey));

  Future<void> saveSettings(AiSettings s) =>
      _db.writeJson(settingsKey, s.toJson());

  Future<String?> key(AiProvider p) => _secrets.read(_secretName(p));

  Future<void> saveKey(AiProvider p, String? key) async {
    try {
      await _secrets.write(
        _secretName(p),
        key == null || key.trim().isEmpty ? null : key.trim(),
      );
    } on Object {
      throw const AiException(
        'Non riesco a salvare la chiave su questo telefono: riprova.',
      );
    }
  }

  Future<bool> isReady() async {
    final s = await settings();
    final p = s.provider;
    return p != null && (await key(p)) != null;
  }

  AiException _keyError(int code) => AiException(
    'La chiave non è valida o non ha accesso a questo modello ($code). '
    'Controllala nelle impostazioni.',
  );

  /// Con un 400 lo stato non basta: è il corpo a dire se la chiave non va.
  bool _isKeyError(http.Response res) {
    final body = res.body.toUpperCase();
    return body.contains('API_KEY_INVALID') ||
        body.contains('API KEY NOT VALID');
  }

  /// Qualunque errore nel leggere la risposta vuol dire che il servizio ha
  /// risposto in un modo che non conosciamo.
  static T _guard<T>(T Function() read) {
    try {
      return read();
    } on AiException {
      rethrow;
    } catch (_) {
      throw const AiException('Risposta inattesa: riprova.');
    }
  }

  Future<http.Response> _send(Future<http.Response> request) async {
    try {
      final res = await request.timeout(const Duration(seconds: 40));
      switch (res.statusCode) {
        case 200:
          return res;
        case 400:
          throw _isKeyError(res)
              ? _keyError(400)
              : const AiException(
                  'La richiesta non è stata accettata: riprova tra poco.',
                );
        case 401 || 403:
          throw _keyError(res.statusCode);
        case 404:
          throw const AiException(
            'Modello non trovato: in Impostazioni tocca "Prova la chiave" per '
            'scegliere un modello disponibile.',
          );
        case 429:
          throw const AiException(
            'Limite gratuito raggiunto per ora: riprova tra qualche minuto.',
          );
        default:
          throw AiException('Il servizio non risponde (${res.statusCode}).');
      }
    } on TimeoutException {
      throw const AiException('Il servizio ci mette troppo: riprova.');
    } on http.ClientException {
      throw _offline;
    } on IOException {
      throw _offline;
    }
  }

  Map<String, String> _groqHeaders(String key) => {
    'Authorization': 'Bearer $key',
    'Content-Type': 'application/json',
  };

  Map<String, String> _geminiHeaders(String key) => {
    'x-goog-api-key': key,
    'Content-Type': 'application/json',
  };

  /// Modelli disponibili con quella chiave (serve anche a provarla).
  Future<List<String>> models(AiProvider p, String key) async {
    switch (p) {
      case AiProvider.groq:
        final res = await _send(
          _client.get(
            Uri.parse('https://api.groq.com/openai/v1/models'),
            headers: _groqHeaders(key),
          ),
        );
        return _guard<List<String>>(() {
          final data = (jsonDecode(res.body) as Map)['data'] as List? ?? [];
          return [
            for (final m in data)
              if ((m as Map)['id'] is String &&
                  !(m['id'] as String).contains(RegExp('whisper|tts|guard')))
                m['id'] as String,
          ]..sort();
        });
      case AiProvider.gemini:
        final res = await _send(
          _client.get(
            Uri.parse(
              'https://generativelanguage.googleapis.com/v1beta/models'
              '?pageSize=200',
            ),
            headers: _geminiHeaders(key),
          ),
        );
        return _guard<List<String>>(() {
          final data = (jsonDecode(res.body) as Map)['models'] as List? ?? [];
          return [
            for (final m in data)
              if (((m as Map)['supportedGenerationMethods'] as List? ?? [])
                      .contains('generateContent') &&
                  '${m['name']}'.contains('gemini'))
                '${m['name']}'.replaceFirst('models/', ''),
          ]..sort();
        });
    }
  }

  /// Sceglie il modello più adatto da un elenco.
  static String pickModel(AiProvider p, List<String> available) {
    if (available.contains(p.defaultModel)) return p.defaultModel;
    final preferences = switch (p) {
      AiProvider.groq => ['llama-3.3-70b', 'gpt-oss-120b', 'llama-4', 'llama'],
      AiProvider.gemini => ['flash', 'pro'],
    };
    for (final want in preferences) {
      final found = available
          .where((m) => m.contains(want) && !m.contains('preview'))
          .toList();
      if (found.isNotEmpty) return found.last;
    }
    return available.isEmpty ? p.defaultModel : available.first;
  }

  /// Il modello che sa guardare le foto. Con Gemini va bene quello scelto;
  /// con Groq serve un modello "vision" (es. Llama 4), cercato nell'elenco.
  Future<String> _visionModel(AiProvider p, String key, String model) async {
    if (p == AiProvider.gemini) return model;
    if (isGroqVision(model)) return model;
    final found = (await models(p, key)).where(isGroqVision).toList();
    if (found.isEmpty) {
      throw const AiException(
        'Con questa chiave Groq non c\'è un modello che legge le foto: '
        'descrivi il piatto a parole oppure usa Google AI Studio.',
      );
    }
    return found.firstWhere(
      (m) => m.contains('scout'),
      orElse: () => found.first,
    );
  }

  static bool isGroqVision(String m) =>
      m.contains('llama-4') || m.contains('vision');

  /// Una domanda all'AI scelta dall'utente. [history] alterna utente e
  /// assistente e finisce con l'utente; la foto va con l'ultimo messaggio.
  Future<String> complete({
    required String system,
    required List<ChatMessage> history,
    Uint8List? image,
    bool json = false,
    double temperature = 0.2,
  }) async {
    final s = await settings();
    final p = s.provider;
    if (p == null) throw const AiException('Scegli un servizio AI.');
    final k = await key(p);
    if (k == null) throw const AiException('Manca la chiave API.');
    var model = s.modelOrDefault!;
    if (image != null) model = await _visionModel(p, k, model);
    final photo = image == null ? null : base64Encode(image);
    final last = history.length - 1;
    switch (p) {
      case AiProvider.groq:
        final res = await _send(
          _client.post(
            Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
            headers: _groqHeaders(k),
            body: jsonEncode({
              'model': model,
              'temperature': temperature,
              if (json) 'response_format': {'type': 'json_object'},
              'messages': [
                {'role': 'system', 'content': system},
                for (final (i, m) in history.indexed)
                  {
                    'role': m.fromUser ? 'user' : 'assistant',
                    'content': i == last && photo != null
                        ? [
                            {'type': 'text', 'text': m.text},
                            {
                              'type': 'image_url',
                              'image_url': {
                                'url': 'data:image/jpeg;base64,$photo',
                              },
                            },
                          ]
                        : m.text,
                  },
              ],
            }),
          ),
        );
        return _guard<String>(() {
          final choices =
              (jsonDecode(utf8.decode(res.bodyBytes)) as Map)['choices'];
          return '${(((choices as List).first as Map)['message'] as Map)['content']}';
        });
      case AiProvider.gemini:
        final res = await _send(
          _client.post(
            Uri.parse(
              'https://generativelanguage.googleapis.com/v1beta/models/'
              '$model:generateContent',
            ),
            headers: _geminiHeaders(k),
            body: jsonEncode({
              'systemInstruction': {
                'parts': [
                  {'text': system},
                ],
              },
              'contents': [
                for (final (i, m) in history.indexed)
                  {
                    'role': m.fromUser ? 'user' : 'model',
                    'parts': [
                      {'text': m.text},
                      if (i == last && photo != null)
                        {
                          'inline_data': {
                            'mime_type': 'image/jpeg',
                            'data': photo,
                          },
                        },
                    ],
                  },
              ],
              'generationConfig': {
                'temperature': temperature,
                if (json) 'responseMimeType': 'application/json',
              },
            }),
          ),
        );
        return _guard<String>(() {
          final candidates =
              (jsonDecode(utf8.decode(res.bodyBytes)) as Map)['candidates'];
          if (candidates is! List || candidates.isEmpty) {
            throw const AiException('L\'AI non ha risposto: riprova.');
          }
          final content = (candidates.first as Map)['content'];
          final parts = content is Map ? content['parts'] as List? : null;
          return (parts ?? const [])
              .map((e) => (e as Map)['text'] ?? '')
              .join();
        });
    }
  }

  /// Dal testo ("due uova e una fetta di pane") o da una foto agli alimenti.
  Future<List<AiFood>> analyze(String text, {Uint8List? image}) async {
    final reply = await complete(
      system: _prompt,
      json: true,
      image: image,
      history: [
        ChatMessage.user(
          image == null
              ? text
              : 'Questa è la foto di quello che ho mangiato. Riconosci gli '
                    'alimenti e stima le quantità dalla porzione nel piatto.'
                    '${text.isEmpty ? '' : ' Nota: $text'}',
        ),
      ],
    );
    return parseAiFoods(reply);
  }
}

/// Un messaggio della conversazione con l'AI.
@immutable
class ChatMessage {
  const ChatMessage.user(this.text) : fromUser = true;
  const ChatMessage.ai(this.text) : fromUser = false;

  final String text;
  final bool fromUser;
}

double? _num(Object? v) => switch (v) {
  final num n => n.toDouble(),
  final String s => double.tryParse(s.replaceAll(',', '.')),
  _ => null,
};

/// Legge la risposta dell'AI. Valori impossibili (es. 2000 kcal per 100 g)
/// fanno scartare l'alimento: meglio chiedere che inventare.
List<AiFood> parseAiFoods(String reply) {
  final start = reply.indexOf('{');
  final end = reply.lastIndexOf('}');
  if (start < 0 || end <= start) {
    throw const AiException('Risposta dell\'AI non leggibile: riprova.');
  }
  final Object? json;
  try {
    json = jsonDecode(reply.substring(start, end + 1));
  } on FormatException {
    throw const AiException('Risposta dell\'AI non leggibile: riprova.');
  }
  final items = json is Map ? json['items'] : null;
  if (items is! List) return const [];
  return [
    for (final i in items)
      if (i is Map) ?_item(i),
  ];
}

AiFood? _item(Map<Object?, Object?> i) {
  final name = '${i['name'] ?? ''}'.trim();
  final grams = _num(i['grams']);
  final kcal = _num(i['kcal']);
  if (name.isEmpty || grams == null || kcal == null) return null;
  if (grams <= 0 || grams > 3000 || kcal < 0 || kcal > 900) return null;
  double macro(String k) => (_num(i[k]) ?? 0).clamp(0, 100).toDouble();
  final protein = macro('protein');
  final carbs = macro('carbs');
  final fat = macro('fat');
  if (protein + carbs + fat > 101) return null;
  return AiFood(
    food: FoodItem(
      name: name.length > 60 ? name.substring(0, 60) : name,
      source: FoodSource.ai,
      defaultGrams: grams,
      per100: Nutrients(
        kcal: kcal,
        protein: protein,
        carbs: carbs,
        fat: fat,
        sugar: macro('sugar').clamp(0, carbs).toDouble(),
      ),
    ),
    grams: grams.roundToDouble(),
    meal: Meal.values.asNameMap()[i['meal']],
  );
}

final secretStoreProvider = Provider<SecretStore>((ref) => DeviceSecretStore());

final aiFoodServiceProvider = Provider<AiFoodService>(
  (ref) => AiFoodService(
    ref.watch(databaseProvider),
    ref.watch(secretStoreProvider),
  ),
);

final aiSettingsProvider = StreamProvider<AiSettings>(
  (ref) => ref.watch(aiFoodServiceProvider).watchSettings(),
);

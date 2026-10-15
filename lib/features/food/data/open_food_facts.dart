// Discipline — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Discipline contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../core/update/update_checker.dart' show appVersion, repoUrl;
import '../domain/foods.dart';
import '../domain/nutrition.dart';

/// Ricerca di alimenti confezionati.
abstract interface class FoodCatalog {
  Future<List<FoodItem>> search(String query);

  /// null se il codice a barre non è nel database.
  Future<FoodItem?> byBarcode(String barcode);
}

class FoodCatalogException implements Exception {
  const FoodCatalogException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Open Food Facts: database libero e gratuito (licenza ODbL).
/// https://world.openfoodfacts.org
class OpenFoodFacts implements FoodCatalog {
  OpenFoodFacts({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _fields =
      'code,product_name,product_name_it,brands,nutriments,allergens_tags';
  static const _headers = {
    // Open Food Facts chiede di identificare l'app.
    'User-Agent': 'Discipline/$appVersion ($repoUrl)',
  };

  /// Ricerche già fatte: Open Food Facts permette poche ricerche al minuto.
  final _cache = <String, List<FoodItem>>{};

  Future<Map<String, Object?>> _get(Uri uri) async {
    try {
      final response = await _client
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 404) return const {};
      if (response.statusCode == 429) {
        throw const FoodCatalogException(
          'Troppe ricerche in poco tempo: aspetta un minuto e riprova.',
        );
      }
      if (response.statusCode != 200) {
        throw FoodCatalogException(
          'Open Food Facts non risponde (${response.statusCode}): riprova '
          'tra poco.',
        );
      }
      final json = jsonDecode(utf8.decode(response.bodyBytes));
      if (json is! Map<String, Object?>) {
        throw const FormatException();
      }
      return json;
    } on TimeoutException {
      throw const FoodCatalogException('Connessione lenta: riprova.');
    } on FormatException {
      throw const FoodCatalogException('Risposta non valida: riprova.');
    } on http.ClientException {
      throw const FoodCatalogException(
        'Sei offline? Puoi usare i piatti italiani e i preferiti.',
      );
    }
  }

  @override
  Future<List<FoodItem>> search(String query) async {
    final q = query.trim().toLowerCase();
    if (q.length < 2) return const [];
    final cached = _cache[q];
    if (cached != null) return cached;
    // Il vecchio /cgi/search.pl ora risponde quasi sempre 503: si usa il
    // nuovo motore di ricerca (search-a-licious), con priorità all'italiano.
    final json = await _get(
      Uri.https('search.openfoodfacts.org', '/search', {
        'q': q,
        'langs': 'it',
        'page_size': '30',
        'fields': _fields,
      }),
    );
    final hits = json['hits'] ?? json['products'];
    final results = [
      for (final p in hits is List ? hits : const [])
        if (p is Map<String, Object?>) ?parseProduct(p),
    ];
    _cache[q] = results;
    return results;
  }

  @override
  Future<FoodItem?> byBarcode(String barcode) async {
    final code = barcode.replaceAll(RegExp(r'\D'), '');
    if (code.isEmpty) return null;
    final json = await _get(
      Uri.https('world.openfoodfacts.org', '/api/v2/product/$code', {
        'fields': _fields,
      }),
    );
    final product = json['product'];
    if (json['status'] == 0 || product is! Map<String, Object?>) return null;
    return parseProduct({...product, 'code': product['code'] ?? code});
  }
}

double? _number(Object? v) => switch (v) {
  final num n => n.toDouble(),
  final String s => double.tryParse(s.replaceAll(',', '.')),
  _ => null,
};

const _allergenTags = {
  'en:gluten': Allergen.gluten,
  'en:milk': Allergen.lactose,
  'en:eggs': Allergen.eggs,
  'en:fish': Allergen.fish,
  'en:crustaceans': Allergen.shellfish,
  'en:nuts': Allergen.nuts,
  'en:peanuts': Allergen.peanuts,
  'en:soybeans': Allergen.soy,
};

/// Testo da un campo che può essere stringa, lista o mappa per lingua.
String _text(Object? v) => switch (v) {
  final String s => s.trim(),
  final List<Object?> l =>
    l.map(_text).firstWhere((s) => s.isNotEmpty, orElse: () => ''),
  final Map<Object?, Object?> m => _text(
    m['it'] ?? m['main'] ?? m.values.firstOrNull,
  ),
  _ => '',
};

/// Converte un prodotto Open Food Facts; null se mancano nome o calorie
/// o se il prodotto ha un formato inatteso.
FoodItem? parseProduct(Map<String, Object?> p) {
  try {
    return _parse(p);
  } on Object {
    return null;
  }
}

FoodItem? _parse(Map<String, Object?> p) {
  final name = [
    p['product_name_it'],
    p['product_name'],
  ].map(_text).firstWhere((s) => s.isNotEmpty, orElse: () => '');
  if (name.isEmpty) return null;
  final nutriments = p['nutriments'];
  final n = nutriments is Map ? nutriments.cast<String, Object?>() : const {};
  final kcal =
      _number(n['energy-kcal_100g']) ??
      (_number(n['energy_100g']) == null
          ? null
          : _number(n['energy_100g'])! / 4.184);
  if (kcal == null || kcal < 0 || kcal > 1000) return null;
  final brands = _text(p['brands']).split(',').first.trim();
  final allergens = p['allergens_tags'];
  final tags = (allergens is List ? allergens : const []).whereType<String>();
  final code = p['code'];
  return FoodItem(
    name: name,
    brand: brands.isEmpty ? null : brands,
    barcode: code == null ? null : '$code',
    source: FoodSource.openFoodFacts,
    per100: Nutrients(
      kcal: kcal,
      protein: _number(n['proteins_100g']) ?? 0,
      carbs: _number(n['carbohydrates_100g']) ?? 0,
      fat: _number(n['fat_100g']) ?? 0,
      sugar: _number(n['sugars_100g']) ?? 0,
    ),
    allergens: {
      for (final t in tags)
        if (_allergenTags[t] != null) _allergenTags[t]!,
    },
  );
}

final foodCatalogProvider = Provider<FoodCatalog>((ref) => OpenFoodFacts());

// Discipline — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Discipline contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

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
    'User-Agent':
        'Discipline/0.1 (https://github.com/owaismounir206-art/Discipline)',
  };

  Future<Map<String, Object?>> _get(Uri uri) async {
    try {
      final response = await _client
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 12));
      if (response.statusCode == 404) return const {};
      if (response.statusCode != 200) {
        throw FoodCatalogException(
          'Open Food Facts non risponde (${response.statusCode}).',
        );
      }
      return jsonDecode(utf8.decode(response.bodyBytes))
          as Map<String, Object?>;
    } on TimeoutException {
      throw const FoodCatalogException('Connessione lenta: riprova.');
    } on FormatException {
      throw const FoodCatalogException('Risposta non valida.');
    } on http.ClientException {
      throw const FoodCatalogException(
        'Sei offline? Puoi usare i piatti italiani e i preferiti.',
      );
    }
  }

  @override
  Future<List<FoodItem>> search(String query) async {
    if (query.trim().length < 2) return const [];
    final json = await _get(
      Uri.https('it.openfoodfacts.org', '/cgi/search.pl', {
        'search_terms': query.trim(),
        'search_simple': '1',
        'action': 'process',
        'json': '1',
        'page_size': '25',
        'fields': _fields,
      }),
    );
    final products = json['products'] as List<Object?>? ?? const [];
    return [
      for (final p in products)
        if (p is Map<String, Object?>) ?parseProduct(p),
    ];
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

/// Converte un prodotto Open Food Facts; null se mancano nome o calorie.
FoodItem? parseProduct(Map<String, Object?> p) {
  final name = [p['product_name_it'], p['product_name']]
      .whereType<String>()
      .map((s) => s.trim())
      .firstWhere((s) => s.isNotEmpty, orElse: () => '');
  if (name.isEmpty) return null;
  final n = p['nutriments'] as Map<String, Object?>? ?? const {};
  final kcal =
      _number(n['energy-kcal_100g']) ??
      (_number(n['energy_100g']) == null
          ? null
          : _number(n['energy_100g'])! / 4.184);
  if (kcal == null) return null;
  final brands = (p['brands'] as String? ?? '').split(',').first.trim();
  final tags = (p['allergens_tags'] as List<Object?>? ?? const [])
      .whereType<String>();
  return FoodItem(
    name: name,
    brand: brands.isEmpty ? null : brands,
    barcode: p['code'] as String?,
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

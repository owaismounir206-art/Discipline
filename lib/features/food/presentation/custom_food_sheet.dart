// Discipline — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Discipline contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../domain/foods.dart';
import '../domain/nutrition.dart';

/// Crea un alimento dai valori dell'etichetta (per 100 g). Resta nei
/// preferiti per le prossime volte.
Future<FoodItem?> showCustomFoodSheet(
  BuildContext context, {
  String name = '',
  String? barcode,
}) => showModalBottomSheet<FoodItem>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => CustomFoodSheet(initialName: name, barcode: barcode),
);

class CustomFoodSheet extends StatefulWidget {
  const CustomFoodSheet({super.key, this.initialName = '', this.barcode});

  final String initialName;

  /// Codice a barre del prodotto (dallo scanner): la prossima scansione lo
  /// ritrova subito, anche senza internet.
  final String? barcode;

  @override
  State<CustomFoodSheet> createState() => _CustomFoodSheetState();
}

class _CustomFoodSheetState extends State<CustomFoodSheet> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.initialName);
  final _values = {
    for (final key in ['kcal', 'protein', 'carbs', 'fat', 'sugar'])
      key: TextEditingController(),
  };

  static const _labels = {
    'kcal': ('Calorie', 'kcal'),
    'protein': ('Proteine', 'g'),
    'carbs': ('Carboidrati', 'g'),
    'fat': ('Grassi', 'g'),
    'sugar': ('di cui zuccheri', 'g'),
  };

  @override
  void dispose() {
    _name.dispose();
    for (final c in _values.values) {
      c.dispose();
    }
    super.dispose();
  }

  double _read(String key) =>
      double.tryParse(_values[key]!.text.trim().replaceAll(',', '.')) ?? 0;

  String? _check(String key, String? text) {
    final t = (text ?? '').trim().replaceAll(',', '.');
    if (t.isEmpty) return key == 'sugar' ? null : 'Obbligatorio';
    final v = double.tryParse(t);
    if (v == null || v < 0) return 'Numero non valido';
    if (key == 'kcal' ? v > 900 : v > 100) return 'Troppo alto per 100 g';
    return null;
  }

  void _save() {
    if (!_form.currentState!.validate()) return;
    final carbs = _read('carbs');
    final sugar = _read('sugar');
    if (_read('protein') + carbs + _read('fat') > 101) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Proteine, carboidrati e grassi insieme non possono superare '
            '100 g su 100 g.',
          ),
        ),
      );
      return;
    }
    if (sugar > carbs) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gli zuccheri non possono superare i carboidrati.'),
        ),
      );
      return;
    }
    Navigator.pop(
      context,
      FoodItem(
        name: _name.text.trim(),
        source: FoodSource.custom,
        barcode: widget.barcode,
        per100: Nutrients(
          kcal: _read('kcal'),
          protein: _read('protein'),
          carbs: carbs,
          fat: _read('fat'),
          sugar: sugar,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 12,
            children: [
              Text('Nuovo alimento', style: theme.textTheme.titleLarge),
              Text(
                'Copia i valori "per 100 g" dall\'etichetta.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Nome',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v ?? '').trim().isEmpty ? 'Scrivi un nome' : null,
              ),
              for (final MapEntry(key: key, value: (label, unit))
                  in _labels.entries)
                TextFormField(
                  controller: _values[key],
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  decoration: InputDecoration(
                    labelText: label,
                    suffixText: unit,
                    border: const OutlineInputBorder(),
                  ),
                  validator: (v) => _check(key, v),
                ),
              FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
                onPressed: _save,
                child: const Text('Crea e scegli i grammi'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

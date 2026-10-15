// Discipline — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Discipline contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../data/food_repository.dart';
import '../data/open_food_facts.dart';
import '../domain/foods.dart';
import 'custom_food_sheet.dart';

/// Risultato dello scanner.
class ScannedFood {
  const ScannedFood(this.item);

  final FoodItem item;
}

/// Scanner del codice a barre: cerca il prodotto su Open Food Facts.
class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> {
  final _controller = MobileScannerController(
    formats: const [
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
      BarcodeFormat.upcA,
      BarcodeFormat.upcE,
    ],
  );
  bool _busy = false;
  String? _message;

  /// Codice letto ma non trovato: si può creare il prodotto.
  String? _missing;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_busy) return;
    final code = capture.barcodes
        .map((b) => b.rawValue)
        .whereType<String>()
        .firstOrNull;
    if (code == null || code == _missing) return;
    // Prima i prodotti già salvati sul telefono (funziona anche offline).
    final saved =
        (await ref.read(foodRepositoryProvider).watchFavorites().first)
            .where((f) => f.barcode == code)
            .firstOrNull;
    if (!mounted) return;
    if (saved != null) {
      Navigator.of(context).pop(ScannedFood(saved));
      return;
    }
    setState(() {
      _busy = true;
      _missing = null;
      _message = 'Cerco il codice $code…';
    });
    try {
      final item = await ref.read(foodCatalogProvider).byBarcode(code);
      if (!mounted) return;
      if (item == null) {
        setState(() {
          _busy = false;
          _missing = code;
          _message =
              'Prodotto non trovato. Crealo copiando i valori '
              'dell\'etichetta: la prossima volta lo riconosco subito.';
        });
        return;
      }
      Navigator.of(context).pop(ScannedFood(item));
    } on FoodCatalogException catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _message = e.message;
        });
      }
    }
  }

  Future<void> _create() async {
    final code = _missing;
    if (code == null) return;
    final food = await showCustomFoodSheet(context, barcode: code);
    if (food == null || !mounted) return;
    await ref.read(foodRepositoryProvider).addFavorite(food, 100);
    if (mounted) Navigator.of(context).pop(ScannedFood(food));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Scansiona'),
        actions: [
          IconButton(
            tooltip: 'Torcia',
            icon: const Icon(Icons.flashlight_on_outlined),
            onPressed: _controller.toggleTorch,
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error) => const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Non riesco ad aprire la fotocamera. Controlla i permessi '
                  'di Discipline nelle impostazioni del telefono.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
          Center(
            child: Container(
              width: 280,
              height: 160,
              decoration: BoxDecoration(
                border: Border.all(color: scheme.primaryContainer, width: 3),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 32,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 12,
                children: [
                  Row(
                    spacing: 12,
                    children: [
                      if (_busy)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      Expanded(
                        child: Text(
                          _message ??
                              'Inquadra il codice a barre della confezione. '
                                  'I dati arrivano da Open Food Facts.',
                        ),
                      ),
                    ],
                  ),
                  if (_missing != null)
                    FilledButton.icon(
                      icon: const Icon(Icons.edit_note),
                      label: const Text('Crea il prodotto'),
                      onPressed: _create,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

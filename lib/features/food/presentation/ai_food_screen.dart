// Discipline — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Discipline contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/data/providers.dart';
import '../../../core/router/routes.dart';
import '../../../core/widgets/common.dart';
import '../data/ai_food.dart';
import '../data/food_repository.dart';
import '../data/food_state.dart';
import '../domain/nutrition.dart';
import '../../../core/feedback/ui_feedback.dart';

/// Scatta o sceglie una foto, già rimpicciolita (meno dati da inviare).
/// Nei test si sostituisce.
final photoPickerProvider = Provider<Future<Uint8List?> Function(ImageSource)>(
  (ref) => (source) async {
    final file = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 70,
    );
    return file?.readAsBytes();
  },
);

/// "Cosa hai mangiato?": l'AI propone gli alimenti (da un testo o da una
/// foto del piatto), tu controlli e salvi.
class AiFoodScreen extends ConsumerStatefulWidget {
  const AiFoodScreen({super.key, required this.meal});

  final Meal meal;

  @override
  ConsumerState<AiFoodScreen> createState() => _AiFoodScreenState();
}

class _AiFoodScreenState extends ConsumerState<AiFoodScreen> {
  final _text = TextEditingController();
  late Meal _meal = widget.meal;
  List<AiFood>? _items;
  Uint8List? _photo;
  Set<int> _selected = {};
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final Uint8List? photo;
    try {
      photo = await ref.read(photoPickerProvider)(source);
    } on PlatformException {
      if (mounted) {
        setState(
          () => _error =
              'Non riesco ad aprire la fotocamera o la '
              'galleria: controlla i permessi dell\'app.',
        );
      }
      return;
    }
    if (photo == null || !mounted) return;
    setState(() => _photo = photo);
    await _analyze();
  }

  Future<void> _analyze() async {
    final text = _text.text.trim();
    final photo = _photo;
    if (text.isEmpty && photo == null) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final items = await ref
          .read(aiFoodServiceProvider)
          .analyze(text, image: photo);
      if (!mounted) return;
      final meals = {for (final i in items) ?i.meal};
      setState(() {
        _busy = false;
        _items = items;
        _selected = {for (var i = 0; i < items.length; i++) i};
        // Se hai scritto il pasto ("a pranzo..."), si usa quello.
        if (meals.length == 1) _meal = meals.single;
        if (items.isEmpty) {
          _error = photo != null
              ? 'Non ho riconosciuto cibo nella foto. Prova con una foto '
                    'più vicina e luminosa, o descrivi il piatto a parole.'
              : 'Non ho trovato alimenti nel testo. Prova a scrivere '
                    'cosa e quanto, es. "pasta al pomodoro, un piatto".';
        }
      });
    } on AiException catch (e) {
      UiFeedback.instance.play(UiSound.error);
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.message;
      });
    }
  }

  Future<void> _editGrams(int i) async {
    final item = _items![i];
    final controller = TextEditingController(text: '${item.grams.round()}');
    final grams = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item.food.name),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            labelText: 'Grammi',
            suffixText: 'g',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(context, double.tryParse(controller.text)),
            child: const Text('Ok'),
          ),
        ],
      ),
    );
    if (grams == null || grams <= 0 || !mounted) return;
    setState(() => _items = [..._items!]..[i] = item.withGrams(grams));
  }

  Future<void> _save() async {
    final items = _items;
    if (items == null) return;
    setState(() => _busy = true);
    final repo = ref.read(foodRepositoryProvider);
    final day = ref.read(foodDayProvider);
    final now = ref.read(clockProvider)();
    for (final i in _selected.toList()..sort()) {
      await repo.addEntry(
        date: day,
        meal: _meal,
        food: items[i].food,
        grams: items[i].grams,
        now: now,
      );
    }
    UiFeedback.instance.play(UiSound.success);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final items = _items;
    final total = items == null
        ? 0
        : [
            for (final i in _selected)
              items[i].food.per100.forGrams(items[i].grams).kcal,
          ].fold<double>(0, (a, b) => a + b);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cosa hai mangiato?'),
        actions: [
          IconButton(
            tooltip: 'Impostazioni AI',
            icon: const Icon(Icons.key_outlined),
            onPressed: () => context.push(Routes.aiSettings),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            if (_photo != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.memory(
                        _photo!,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        semanticLabel: 'Foto del piatto',
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: IconButton.filledTonal(
                        tooltip: 'Togli la foto',
                        icon: const Icon(Icons.close),
                        onPressed: _busy
                            ? null
                            : () => setState(() => _photo = null),
                      ),
                    ),
                  ],
                ),
              ),
            TextField(
              controller: _text,
              autofocus: items == null && _photo == null,
              minLines: _photo == null ? 3 : 1,
              maxLines: 6,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: _photo == null
                    ? 'Es. "a colazione due uova strapazzate, una fetta di '
                          'pane integrale e un caffè con un cucchiaino di '
                          'zucchero"'
                    : 'Note facoltative, es. "c\'era anche un filo d\'olio"',
                helperText: _photo == null
                    ? 'Puoi anche dettare con il microfono della tastiera.'
                    : null,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              icon: _busy && items == null
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome),
              label: Text(items == null ? 'Analizza' : 'Analizza di nuovo'),
              onPressed: _busy ? null : _analyze,
            ),
            const SizedBox(height: 8),
            Row(
              spacing: 8,
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: const Text('Scatta foto'),
                    onPressed: _busy
                        ? null
                        : () => _pickPhoto(ImageSource.camera),
                  ),
                ),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Dalla galleria'),
                    onPressed: _busy
                        ? null
                        : () => _pickPhoto(ImageSource.gallery),
                  ),
                ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: scheme.error)),
            ],
            if (items != null && items.isNotEmpty) ...[
              const SectionTitle('Controlla e conferma'),
              Text(
                'Valori stimati dall\'AI: tocca un alimento per cambiare i '
                'grammi, togli la spunta a quelli sbagliati.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              for (final (i, item) in items.indexed)
                CheckboxListTile(
                  value: _selected.contains(i),
                  onChanged: (v) => setState(() {
                    _selected = {..._selected};
                    v == true ? _selected.add(i) : _selected.remove(i);
                  }),
                  title: Text(item.food.name),
                  subtitle: Text(
                    '${item.grams.round()} g · '
                    '${item.food.per100.forGrams(item.grams).kcal.round()} '
                    'kcal · P ${item.food.per100.forGrams(item.grams).protein.round()} g',
                  ),
                  secondary: IconButton(
                    tooltip: 'Cambia i grammi di ${item.food.name}',
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => _editGrams(i),
                  ),
                ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (final m in Meal.values)
                    ChoiceChip(
                      label: Text(m.label),
                      selected: m == _meal,
                      onSelected: (_) => setState(() => _meal = m),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _busy || _selected.isEmpty ? null : _save,
                child: Text(
                  'Aggiungi ${_selected.length} '
                  '${_selected.length == 1 ? 'alimento' : 'alimenti'} '
                  '${_meal.toMeal} · ${total.round()} kcal',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Sotto i pasti in Cibo: AI (testo o foto), ricetta di casa e
/// "Cosa cucino?". Senza chiave l'AI porta alle impostazioni, che spiegano
/// come averla.
class MoreWaysRow extends ConsumerWidget {
  const MoreWaysRow({super.key, required this.meal});

  final Meal meal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ready = ref.watch(aiSettingsProvider).value?.provider != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        Row(
          spacing: 10,
          children: [
            Expanded(
              child: FilledButton.tonalIcon(
                icon: const Icon(Icons.auto_awesome, size: 18),
                label: const Text('Scrivi o foto'),
                onPressed: () => context.push(
                  ready ? Routes.aiFood : Routes.aiSettings,
                  extra: meal,
                ),
              ),
            ),
            Expanded(
              child: FilledButton.tonalIcon(
                icon: const Icon(Icons.soup_kitchen_outlined, size: 18),
                label: const Text('Ricetta di casa'),
                onPressed: () => context.push(Routes.homemade),
              ),
            ),
          ],
        ),
        OutlinedButton.icon(
          icon: const Icon(Icons.restaurant_menu, size: 18),
          label: const Text('Cosa cucino? Chiedi una ricetta all\'AI'),
          onPressed: () =>
              context.push(ready ? Routes.kitchen : Routes.aiSettings),
        ),
      ],
    );
  }
}

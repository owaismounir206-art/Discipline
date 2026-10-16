// Discipline — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Discipline contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:material_ui/material_ui.dart';

/// Gli stili grafici dell'app. [material] è quello di sempre (Material You,
/// con chiaro/scuro e palette); gli altri hanno colori propri e fissi.
enum StyleId {
  material,
  glass,
  fluent,
  cartoon,
  swiss,
  brutal,
  gameboy,
  clay,
  cyber,
  sport,
  zen,
  kanji,
}

/// Come entrano le card nelle schermate.
enum EnterKind {
  /// Salgono e appaiono (Material You, Fluent).
  fadeUp,

  /// Crescono appena e appaiono (vetro).
  grow,

  /// Cadono dall'alto con un rimbalzo (cartoon).
  drop,

  /// Una tendina le scopre da sinistra (svizzero).
  wipe,

  /// Arrivano di colpo a scatti (brutale).
  slam,

  /// A scatti come un videogioco (Game Boy).
  steps,

  /// Si gonfiano (clay).
  puff,

  /// Si accendono tremolando (cyber).
  boot,

  /// Scivolano di lato, alternate (sport).
  slide,

  /// Emergono lente come inchiostro (zen).
  ink,

  /// Si scoprono dall'alto come una pennellata (kanji).
  brush,
}

/// Come risponde una card o un pulsante premuto.
enum PressKind {
  /// Si rimpicciolisce un poco.
  scale,

  /// Affonda nella sua ombra (brutale, Game Boy).
  sink,

  /// Si schiaccia e rimbalza (cartoon).
  squash,

  /// Trema come gelatina (clay).
  jelly,

  /// Si imprime come un timbro (kanji).
  stamp,
}

/// Forma degli angoli.
enum CornerKind {
  round,

  /// Angoli tagliati (cyber).
  cut,

  /// Parallelogramma inclinato (sport, solo i pulsanti).
  slant,
}

/// Tutto ciò che distingue uno stile oltre ai colori: caratteri, forme,
/// ombre, animazioni. Si legge con [AppStyle.of].
@immutable
class AppStyle extends ThemeExtension<AppStyle> {
  const AppStyle({
    required this.id,
    required this.label,
    required this.tagline,
    this.brightness,
    this.displayFont,
    this.bodyFont,
    this.displayWeight = FontWeight.w700,
    this.titleSize = 30,
    this.titleLetterSpacing = -0.5,
    this.uppercaseTitles = false,
    this.uppercaseLabels = false,
    this.corner = CornerKind.round,
    this.radius = 24,
    this.buttonRadius = 999,
    this.buttonCorner = CornerKind.round,
    this.smallRadius = 12,
    this.borderWidth = 0,
    this.borderColor,
    this.hardShadow,
    this.hardShadowColor,
    this.softShadows = const [],
    this.glow,
    this.glassEdge = false,
    this.clayEdge = false,
    this.enter = EnterKind.fadeUp,
    this.enterDuration = const Duration(milliseconds: 500),
    this.enterCurve = const Cubic(0.05, 0.7, 0.1, 1),
    this.stagger = const Duration(milliseconds: 50),
    this.press = PressKind.scale,
    this.moveDuration = const Duration(milliseconds: 400),
    this.moveCurve = const Cubic(0.05, 0.7, 0.1, 1),
    this.ambient = false,
  });

  final StyleId id;
  final String label;

  /// Una frase per la scelta nelle impostazioni.
  final String tagline;

  /// Chiaro o scuro fisso; null = segue l'impostazione "Tema".
  final Brightness? brightness;

  /// Carattere dei titoli e di quello normale (null = quello del telefono).
  final String? displayFont;
  final String? bodyFont;
  final FontWeight displayWeight;

  /// Titolo delle schermate principali.
  final double titleSize;
  final double titleLetterSpacing;
  final bool uppercaseTitles;

  /// Etichette della barra in basso e titoli di sezione in maiuscolo.
  final bool uppercaseLabels;

  /// Forme: card, pulsanti, elementi piccoli (chip, campi, badge).
  final CornerKind corner;
  final double radius;
  final double buttonRadius;
  final CornerKind buttonCorner;
  final double smallRadius;

  /// Bordo delle card (0 = nessuno; colore null = outline del tema).
  final double borderWidth;
  final Color? borderColor;

  /// Ombra piena spostata (brutale, cartoon, Game Boy).
  final Offset? hardShadow;
  final Color? hardShadowColor;

  /// Ombre morbide sotto le card.
  final List<BoxShadow> softShadows;

  /// Bagliore al neon intorno alle card (cyber).
  final Color? glow;

  /// Riflesso del vetro sul bordo (vetro) e luci/ombre interne (clay).
  final bool glassEdge;
  final bool clayEdge;

  /// Animazioni: ingresso, pressione, spostamento degli indicatori.
  final EnterKind enter;
  final Duration enterDuration;
  final Curve enterCurve;
  final Duration stagger;
  final PressKind press;
  final Duration moveDuration;
  final Curve moveCurve;

  /// Lo sfondo si muove piano.
  final bool ambient;

  /// Lo stile del momento (Material You se il tema non ne ha uno).
  static AppStyle of(BuildContext context) =>
      Theme.of(context).extension<AppStyle>() ?? material;

  /// Material You: il riferimento per i valori di serie.
  static const material = AppStyle(
    id: StyleId.material,
    label: 'Discipline',
    tagline: 'Material You: morbido e colorato, chiaro o scuro.',
    displayFont: 'Figtree',
    bodyFont: 'Figtree',
    radius: 28,
  );

  bool get isKanji => id == StyleId.kanji;

  /// Le card disegnano qualcosa fuori dal bordo (ombre piene, bagliore).
  bool get paintsOutside => hardShadow != null || glow != null;

  /// Uppercase solo dove lo stile lo vuole.
  String title(String text) => uppercaseTitles ? text.toUpperCase() : text;
  String navLabel(String text) => uppercaseLabels ? text.toUpperCase() : text;

  @override
  AppStyle copyWith() => this;

  // Tra due stili non c'è una via di mezzo: si passa a metà animazione.
  @override
  AppStyle lerp(covariant AppStyle? other, double t) =>
      other == null || t < 0.5 ? this : other;
}

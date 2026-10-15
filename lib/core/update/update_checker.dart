// Discipline — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Discipline contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show TargetPlatform;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';

import '../data/database.dart';
import '../data/providers.dart';

/// Versione dell'app: deve essere uguale a quella di pubspec.yaml (c'è un
/// test che lo controlla).
const appVersion = '1.0.1';

const repoUrl = 'https://github.com/owaismounir206-art/Discipline';
const _latestApi =
    'https://api.github.com/repos/owaismounir206-art/Discipline/releases/latest';

/// Una versione pubblicata su GitHub.
@immutable
class Release {
  const Release({
    required this.version,
    required this.notes,
    required this.page,
    this.apk,
  });

  final String version;
  final String notes;
  final Uri page;

  /// Link diretto all'APK, se c'è.
  final Uri? apk;

  /// Dove scaricarla: l'APK su Android, la pagina della release altrove
  /// (su iPhone il file .ipa va installato con AltStore o SideStore).
  Uri downloadFor(TargetPlatform platform) =>
      platform == TargetPlatform.android ? apk ?? page : page;

  /// Le prime righe delle note, senza simboli Markdown.
  List<String> get highlights => [
    for (final line in const LineSplitter().convert(notes))
      if (line.trim().startsWith(RegExp(r'[-*] ')))
        line.trim().substring(2).replaceAll('**', '').replaceAll('`', ''),
  ].take(4).toList();

  Map<String, Object?> toJson() => {
    'version': version,
    'notes': notes,
    'page': '$page',
    'apk': apk?.toString(),
  };

  static Release fromJson(Map<String, Object?> j) => Release(
    version: j['version']! as String,
    notes: (j['notes'] as String?) ?? '',
    page: Uri.parse(j['page']! as String),
    apk: j['apk'] == null ? null : Uri.parse(j['apk']! as String),
  );

  /// Dalla risposta dell'API di GitHub.
  static Release? fromGitHub(Map<String, Object?> j) {
    final tag = j['tag_name'];
    final page = j['html_url'];
    if (tag is! String || page is! String) return null;
    Uri? apk;
    for (final a in (j['assets'] as List?) ?? const []) {
      final name = (a as Map)['name'];
      final url = a['browser_download_url'];
      if (name is String && name.endsWith('.apk') && url is String) {
        apk = Uri.parse(url);
        break;
      }
    }
    return Release(
      version: tag.replaceFirst(RegExp('^v'), ''),
      notes: (j['body'] as String?) ?? '',
      page: Uri.parse(page),
      apk: apk,
    );
  }
}

/// Confronta "1.2.3" con "1.10.0": negativo se [a] è più vecchia.
int compareVersions(String a, String b) {
  List<int> parts(String v) => [
    for (final p in v.split('+').first.split('-').first.split('.'))
      int.tryParse(p) ?? 0,
  ];
  final x = parts(a);
  final y = parts(b);
  for (var i = 0; i < 3; i++) {
    final d = (i < x.length ? x[i] : 0) - (i < y.length ? y[i] : 0);
    if (d != 0) return d;
  }
  return 0;
}

/// Da dove arriva l'ultima versione (nei test una finta).
abstract interface class ReleaseSource {
  Future<Release?> latest();
}

class GitHubReleases implements ReleaseSource {
  GitHubReleases({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  @override
  Future<Release?> latest() async {
    try {
      final res = await _client
          .get(
            Uri.parse(_latestApi),
            headers: {
              'Accept': 'application/vnd.github+json',
              'User-Agent': 'Discipline/$appVersion ($repoUrl)',
            },
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return null;
      return Release.fromGitHub(jsonDecode(res.body) as Map<String, Object?>);
    } on Object {
      // Niente rete o risposta strana: si riprova domani.
      return null;
    }
  }
}

/// Impostazioni e memoria del controllo aggiornamenti.
@immutable
class UpdateSettings {
  const UpdateSettings({
    this.enabled = true,
    this.lastCheck,
    this.dismissed,
    this.latest,
  });

  final bool enabled;
  final DateTime? lastCheck;

  /// Versione per cui l'utente ha scelto "Più tardi".
  final String? dismissed;
  final Release? latest;

  Map<String, Object?> toJson() => {
    'enabled': enabled,
    'lastCheck': lastCheck?.toIso8601String(),
    'dismissed': dismissed,
    'latest': latest?.toJson(),
  };

  static UpdateSettings fromJson(Object? json) {
    if (json is! Map) return const UpdateSettings();
    final j = json.cast<String, Object?>();
    return UpdateSettings(
      enabled: j['enabled'] as bool? ?? true,
      lastCheck: DateTime.tryParse(j['lastCheck'] as String? ?? ''),
      dismissed: j['dismissed'] as String?,
      latest: j['latest'] is Map
          ? Release.fromJson((j['latest']! as Map).cast<String, Object?>())
          : null,
    );
  }
}

class UpdateRepository {
  UpdateRepository(this._db, this._source, this._clock);

  final AppDatabase _db;
  final ReleaseSource _source;
  final DateTime Function() _clock;

  static const key = 'updates';

  Stream<UpdateSettings> watch() =>
      _db.watchJson(key).map(UpdateSettings.fromJson);

  Future<UpdateSettings> _read() async =>
      UpdateSettings.fromJson(await _db.readJson(key));

  Future<void> _write(UpdateSettings s) => _db.writeJson(key, s.toJson());

  Future<void> setEnabled(bool on) async {
    final s = await _read();
    await _write(
      UpdateSettings(
        enabled: on,
        lastCheck: s.lastCheck,
        dismissed: s.dismissed,
        latest: s.latest,
      ),
    );
  }

  Future<void> dismiss(String version) async {
    final s = await _read();
    await _write(
      UpdateSettings(
        enabled: s.enabled,
        lastCheck: s.lastCheck,
        dismissed: version,
        latest: s.latest,
      ),
    );
  }

  /// Chiede a GitHub l'ultima versione al massimo una volta al giorno
  /// (sempre con [force]). Restituisce la versione nuova, se c'è.
  Future<Release?> check({bool force = false}) async {
    final s = await _read();
    if (!s.enabled && !force) return null;
    final now = _clock();
    var latest = s.latest;
    final fresh =
        s.lastCheck != null && now.difference(s.lastCheck!).inHours < 24;
    if (force || !fresh) {
      final fetched = await _source.latest();
      latest = fetched ?? latest;
      await _write(
        UpdateSettings(
          enabled: s.enabled,
          lastCheck: now,
          dismissed: s.dismissed,
          latest: latest,
        ),
      );
    }
    if (latest == null || compareVersions(latest.version, appVersion) <= 0) {
      return null;
    }
    if (!force && latest.version == s.dismissed) return null;
    return latest;
  }
}

final releaseSourceProvider = Provider<ReleaseSource>(
  (ref) => GitHubReleases(),
);

final updateRepositoryProvider = Provider<UpdateRepository>(
  (ref) => UpdateRepository(
    ref.watch(databaseProvider),
    ref.watch(releaseSourceProvider),
    ref.watch(clockProvider),
  ),
);

final updateSettingsProvider = StreamProvider<UpdateSettings>(
  (ref) => ref.watch(updateRepositoryProvider).watch(),
);

/// La versione nuova da proporre in "Oggi" (null se non c'è).
final availableUpdateProvider = FutureProvider<Release?>((ref) {
  // Si ricalcola quando cambiano le impostazioni (es. "Più tardi").
  ref.watch(updateSettingsProvider.select((s) => s.value?.dismissed));
  ref.watch(updateSettingsProvider.select((s) => s.value?.enabled));
  return ref.watch(updateRepositoryProvider).check();
});

// Discipline — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Discipline contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../profile/domain/athlete_profile.dart';
import '../../workout/domain/workout_plan.dart';

/// Promemoria nei giorni di allenamento.
abstract interface class ReminderService {
  /// Chiede il permesso per le notifiche (Android 13+, iOS).
  Future<bool> requestPermission();

  /// Riprogramma i promemoria in base al profilo (o li toglie).
  Future<void> schedule(AthleteProfile profile);

  /// Toglie tutti i promemoria (dati cancellati o profilo assente).
  Future<void> cancelAll();
}

/// Prossimo momento (da [now]) con quel giorno della settimana e quell'ora.
DateTime nextWeekdayTime(DateTime now, int weekday, int hour, int minute) {
  var candidate = DateTime(now.year, now.month, now.day, hour, minute);
  final daysAhead = (weekday - now.weekday) % 7;
  candidate = DateTime(
    candidate.year,
    candidate.month,
    candidate.day + daysAhead,
    hour,
    minute,
  );
  if (!candidate.isAfter(now)) {
    candidate = DateTime(
      candidate.year,
      candidate.month,
      candidate.day + 7,
      hour,
      minute,
    );
  }
  return candidate;
}

/// Testo del promemoria per una scheda.
String reminderBody(WorkoutTemplate? template) => template == null
    ? 'La tua streak ti aspetta.'
    : 'Oggi tocca a ${template.label}. La tua streak ti aspetta.';

class LocalReminderService implements ReminderService {
  final _plugin = FlutterLocalNotificationsPlugin();
  Future<void>? _ready;

  bool get _supported => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  Future<void> _init() => _ready ??= () async {
    tz_data.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } on Object {
      tz.setLocalLocation(tz.UTC);
    }
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
  }();

  @override
  Future<bool> requestPermission() async {
    if (!_supported) return false;
    await _init();
    if (Platform.isAndroid) {
      return await _plugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >()
              ?.requestNotificationsPermission() ??
          false;
    }
    return await _plugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >()
            ?.requestPermissions(alert: true, sound: true) ??
        false;
  }

  @override
  Future<void> cancelAll() async {
    if (!_supported) return;
    await _init();
    await _plugin.cancelAll();
  }

  @override
  Future<void> schedule(AthleteProfile profile) async {
    if (!_supported) return;
    await _init();
    await _plugin.cancelAll();
    final reminder = profile.reminder;
    if (reminder == null) return;
    await requestPermission();

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'promemoria',
        'Promemoria di allenamento',
        channelDescription:
            'Un avviso nei giorni in cui hai scelto di allenarti',
        importance: Importance.defaultImportance,
      ),
      iOS: DarwinNotificationDetails(),
    );
    final templates = weeklySchedule(profile.trainingDays);
    final now = tz.TZDateTime.now(tz.local);
    for (final day in profile.trainingDays) {
      final next = nextWeekdayTime(
        DateTime(now.year, now.month, now.day, now.hour, now.minute),
        day,
        reminder.hour,
        reminder.minute,
      );
      await _plugin.zonedSchedule(
        id: day,
        title: 'È ora di allenarti',
        body: reminderBody(templates[day]),
        scheduledDate: tz.TZDateTime(
          tz.local,
          next.year,
          next.month,
          next.day,
          next.hour,
          next.minute,
        ),
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    }
  }
}

final remindersProvider = Provider<ReminderService>(
  (ref) => LocalReminderService(),
);

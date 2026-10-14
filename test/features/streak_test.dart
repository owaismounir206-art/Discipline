// Discipline — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Discipline contributors
// SPDX-License-Identifier: GPL-3.0-or-later

// La CI esegue questi test anche con TZ=Europe/Rome e TZ=America/Sao_Paulo
// per controllare cambio dell'ora e mezzanotte.

import 'package:flutter_test/flutter_test.dart';
import 'package:discipline/core/utils/local_date.dart';
import 'package:discipline/features/streak/domain/streak.dart';

// Lunedì 5 ottobre 2026.
const monday = LocalDate(2026, 10, 5);

/// Giorni L, M, G, S.
const lmgs = {1, 2, 4, 6};

StreakResult run(
  Map<LocalDate, double> completions,
  LocalDate today, {
  List<ScheduleChange>? schedule,
}) => computeStreak(
  schedule: schedule ?? [const ScheduleChange(from: monday, days: lmgs)],
  completions: completions,
  today: today,
);

Map<LocalDate, double> doneOn(Iterable<LocalDate> days, [double ratio = 1]) => {
  for (final d in days) d: ratio,
};

LocalDate day(int offset) => monday.addDays(offset);

void main() {
  group('LocalDate', () {
    test('somma i giorni sul calendario anche al cambio dell\'ora', () {
      // In Italia l'ora legale finisce il 25 ottobre 2026 e inizia il
      // 29 marzo 2026.
      expect(
        const LocalDate(2026, 10, 24).addDays(1),
        const LocalDate(2026, 10, 25),
      );
      expect(
        const LocalDate(2026, 10, 25).addDays(1),
        const LocalDate(2026, 10, 26),
      );
      expect(
        const LocalDate(2026, 3, 28).addDays(2),
        const LocalDate(2026, 3, 30),
      );
      expect(
        const LocalDate(2026, 3, 30).daysSince(const LocalDate(2026, 3, 28)),
        2,
      );
      // Brasile 2018: a mezzanotte del 4 novembre gli orologi saltavano
      // all'1:00; il giorno deve restare il 4.
      expect(
        const LocalDate(2018, 11, 3).addDays(1),
        const LocalDate(2018, 11, 4),
      );
    });

    test('anno bisestile, fine mese e fine anno', () {
      expect(
        const LocalDate(2028, 2, 28).addDays(1),
        const LocalDate(2028, 2, 29),
      );
      expect(
        const LocalDate(2026, 12, 31).addDays(1),
        const LocalDate(2027, 1, 1),
      );
      expect(
        const LocalDate(2027, 1, 1).daysSince(const LocalDate(2026, 12, 25)),
        7,
      );
    });

    test('un allenamento alle 23:59 conta per quel giorno', () {
      expect(
        LocalDate.fromDateTime(DateTime(2026, 10, 13, 23, 59, 59)),
        const LocalDate(2026, 10, 13),
      );
      expect(
        LocalDate.fromDateTime(DateTime(2026, 10, 14)),
        const LocalDate(2026, 10, 14),
      );
    });

    test('lunedì della settimana, parse e chiave', () {
      expect(const LocalDate(2026, 10, 11).startOfWeek, monday);
      expect(monday.startOfWeek, monday);
      expect(LocalDate.parse('2026-10-05'), monday);
      expect(monday.key, '2026-10-05');
    });
  });

  group('Streak', () {
    test('conta solo i giorni scelti', () {
      // L, M, G, S della prima settimana: 4 allenamenti.
      final r = run(doneOn([day(0), day(1), day(3), day(5)]), day(6));
      expect(r.current, 4);
      expect(r.statuses[day(2)], DayStatus.rest);
      expect(r.statuses[day(6)], DayStatus.rest);
    });

    test('allenarsi in un giorno di riposo è un bonus e non aumenta', () {
      final r = run(doneOn([day(0), day(2), day(1)]), day(2));
      expect(r.current, 2);
      expect(r.statuses[day(2)], DayStatus.bonus);
    });

    test('un giorno conta se si completa almeno l\'80%', () {
      expect(run({day(0): 0.8}, day(0)).current, 1);
      expect(run({day(0): 0.79}, day(0)).current, 0);
      expect(run({day(0): 0.79}, day(0)).statuses[day(0)], DayStatus.today);
    });

    test('oggi non ancora fatto non interrompe la streak', () {
      final r = run(doneOn([day(0)]), day(1));
      expect(r.current, 1);
      expect(r.statuses[day(1)], DayStatus.today);
    });

    test('il primo giorno saltato usa il giorno di recupero', () {
      // L fatto, M saltato (recupero), G fatto.
      final r = run(doneOn([day(0), day(3)]), day(3));
      expect(r.statuses[day(1)], DayStatus.recovered);
      expect(r.current, 2);
      expect(r.recoveryAvailable, isFalse);
    });

    test('un secondo salto entro 2 settimane azzera la streak', () {
      // L fatto, M saltato (recupero), G fatto, S saltato → zero.
      final r = run(doneOn([day(0), day(3)]), day(7));
      expect(r.statuses[day(5)], DayStatus.missed);
      expect(r.current, 0);
      expect(r.best, 2);
    });

    test('il recupero torna disponibile dopo 14 giorni', () {
      final done = <LocalDate>[];
      // Tre settimane complete tranne martedì della prima e martedì della
      // terza (15 giorni dopo).
      for (var i = 0; i < 21; i++) {
        final d = day(i);
        if (lmgs.contains(d.weekday) && i != 1 && i != 15) done.add(d);
      }
      final r = run(doneOn(done), day(20));
      expect(r.statuses[day(1)], DayStatus.recovered);
      expect(r.statuses[day(15)], DayStatus.recovered);
      expect(r.current, 10);
    });

    test('a streak zero il recupero non viene consumato', () {
      // Nessun allenamento: i giorni saltati sono "missed".
      final r = run({}, day(3));
      expect(r.statuses[day(0)], DayStatus.missed);
      expect(r.statuses[day(1)], DayStatus.missed);
      expect(r.recoveryAvailable, isTrue);
    });

    test('il record resta anche dopo l\'azzeramento', () {
      final done = [day(0), day(1), day(3), day(5), day(7), day(8)];
      final r = run(doneOn(done), day(18));
      expect(r.current, 0);
      expect(r.best, 6);
    });

    test('cambiare giorni vale da domani e la streak resta', () {
      var schedule = addScheduleChange([], lmgs, monday);
      expect(schedule.single.from, monday);
      // Mercoledì 7 cambio in "solo venerdì".
      schedule = addScheduleChange(schedule, {5}, day(2));
      expect(schedule.last.from, day(3));

      final r = run(
        doneOn([day(0), day(1), day(4)]),
        day(6),
        schedule: schedule,
      );
      // Mercoledì era ancora riposo, giovedì non è più programmato.
      expect(r.statuses[day(3)], DayStatus.rest);
      expect(r.statuses[day(4)], DayStatus.done);
      expect(r.current, 3);
    });

    test('più cambi nello stesso giorno tengono solo l\'ultimo', () {
      var schedule = addScheduleChange([], lmgs, monday);
      schedule = addScheduleChange(schedule, {5}, day(2));
      schedule = addScheduleChange(schedule, {3, 5}, day(2));
      expect(schedule, hasLength(2));
      expect(schedule.last.days, {3, 5});
      // Rimettere gli stessi giorni non aggiunge nulla.
      expect(addScheduleChange(schedule, {5, 3}, day(4)), same(schedule));
    });

    test('prima dell\'inizio non c\'è streak', () {
      expect(run({}, monday.addDays(-1)).current, 0);
      expect(
        computeStreak(schedule: [], completions: {}, today: monday).best,
        0,
      );
    });

    test('attraversa il cambio dell\'ora senza saltare giorni', () {
      // Dal 19 ottobre al 1 novembre 2026, ogni giorno programmato.
      const start = LocalDate(2026, 10, 19);
      final schedule = [
        const ScheduleChange(from: start, days: {1, 2, 3, 4, 5, 6, 7}),
      ];
      final days = [for (var i = 0; i < 14; i++) start.addDays(i)];
      final r = computeStreak(
        schedule: schedule,
        completions: doneOn(days),
        today: days.last,
      );
      expect(r.current, 14);
      expect(r.statuses.length, 14);
    });
  });

  group('Settimana', () {
    test('mostra fatto, oggi, programmato e riposo', () {
      final schedule = [const ScheduleChange(from: monday, days: lmgs)];
      final streak = run(doneOn([day(0)]), day(1));
      final strip = weekStrip(
        streak: streak,
        schedule: schedule,
        today: day(1),
      );
      expect(strip.map((e) => e.$2), [
        DayStatus.done,
        DayStatus.today,
        DayStatus.rest,
        DayStatus.scheduled,
        DayStatus.rest,
        DayStatus.scheduled,
        DayStatus.rest,
      ]);
      expect(strip.first.$1, monday);
    });

    test('i giorni futuri seguono i nuovi giorni scelti', () {
      var schedule = addScheduleChange([], lmgs, monday);
      schedule = addScheduleChange(schedule, {7}, day(1));
      final streak = run(doneOn([day(0)]), day(1), schedule: schedule);
      final strip = weekStrip(
        streak: streak,
        schedule: schedule,
        today: day(1),
      );
      expect(strip[3].$2, DayStatus.rest);
      expect(strip[6].$2, DayStatus.scheduled);
    });
  });

  group('Giorno jolly', () {
    // Lun 5 fatto, mar 6 saltato (salvato dal recupero automatico), gio 8
    // fatto, sab 10 saltato di nuovo: lì serve il giorno jolly.
    final completions = doneOn([monday, monday.addDays(3), monday.addDays(7)]);
    final today = monday.addDays(8); // martedì 13

    test('senza jolly il secondo salto azzera la serie', () {
      final r = run(completions, today);
      expect(r.statuses[monday.addDays(1)], DayStatus.recovered);
      expect(r.statuses[monday.addDays(5)], DayStatus.missed);
      expect(r.current, 1);
      expect(freezableDay(r, today), monday.addDays(5));
      expect(freezableDay(r, today, windowDays: 2), isNull);
    });

    test('il giorno protetto non azzera la serie', () {
      final r = computeStreak(
        schedule: [const ScheduleChange(from: monday, days: lmgs)],
        completions: completions,
        today: today,
        protectedDays: {monday.addDays(5)},
      );
      expect(r.statuses[monday.addDays(5)], DayStatus.protected);
      expect(r.current, 3);
    });
  });
}

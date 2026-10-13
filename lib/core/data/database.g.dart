// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $KeyValuesTable extends KeyValues
    with TableInfo<$KeyValuesTable, KeyValue> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $KeyValuesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'key_values';
  @override
  VerificationContext validateIntegrity(
    Insertable<KeyValue> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  KeyValue map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return KeyValue(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $KeyValuesTable createAlias(String alias) {
    return $KeyValuesTable(attachedDatabase, alias);
  }
}

class KeyValue extends DataClass implements Insertable<KeyValue> {
  final String key;
  final String value;
  const KeyValue({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  KeyValuesCompanion toCompanion(bool nullToAbsent) {
    return KeyValuesCompanion(key: Value(key), value: Value(value));
  }

  factory KeyValue.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return KeyValue(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  KeyValue copyWith({String? key, String? value}) =>
      KeyValue(key: key ?? this.key, value: value ?? this.value);
  KeyValue copyWithCompanion(KeyValuesCompanion data) {
    return KeyValue(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('KeyValue(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is KeyValue && other.key == this.key && other.value == this.value);
}

class KeyValuesCompanion extends UpdateCompanion<KeyValue> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const KeyValuesCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  KeyValuesCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<KeyValue> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  KeyValuesCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return KeyValuesCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('KeyValuesCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WorkoutSessionsTable extends WorkoutSessions
    with TableInfo<$WorkoutSessionsTable, WorkoutSession> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorkoutSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endedAtMeta = const VerificationMeta(
    'endedAt',
  );
  @override
  late final GeneratedColumn<DateTime> endedAt = GeneratedColumn<DateTime>(
    'ended_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _templateMeta = const VerificationMeta(
    'template',
  );
  @override
  late final GeneratedColumn<String> template = GeneratedColumn<String>(
    'template',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _plannedSetsMeta = const VerificationMeta(
    'plannedSets',
  );
  @override
  late final GeneratedColumn<int> plannedSets = GeneratedColumn<int>(
    'planned_sets',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completedSetsMeta = const VerificationMeta(
    'completedSets',
  );
  @override
  late final GeneratedColumn<int> completedSets = GeneratedColumn<int>(
    'completed_sets',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    date,
    startedAt,
    endedAt,
    template,
    plannedSets,
    completedSets,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'workout_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<WorkoutSession> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('ended_at')) {
      context.handle(
        _endedAtMeta,
        endedAt.isAcceptableOrUnknown(data['ended_at']!, _endedAtMeta),
      );
    }
    if (data.containsKey('template')) {
      context.handle(
        _templateMeta,
        template.isAcceptableOrUnknown(data['template']!, _templateMeta),
      );
    } else if (isInserting) {
      context.missing(_templateMeta);
    }
    if (data.containsKey('planned_sets')) {
      context.handle(
        _plannedSetsMeta,
        plannedSets.isAcceptableOrUnknown(
          data['planned_sets']!,
          _plannedSetsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_plannedSetsMeta);
    }
    if (data.containsKey('completed_sets')) {
      context.handle(
        _completedSetsMeta,
        completedSets.isAcceptableOrUnknown(
          data['completed_sets']!,
          _completedSetsMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WorkoutSession map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorkoutSession(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      endedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ended_at'],
      ),
      template: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}template'],
      )!,
      plannedSets: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}planned_sets'],
      )!,
      completedSets: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}completed_sets'],
      )!,
    );
  }

  @override
  $WorkoutSessionsTable createAlias(String alias) {
    return $WorkoutSessionsTable(attachedDatabase, alias);
  }
}

class WorkoutSession extends DataClass implements Insertable<WorkoutSession> {
  final int id;

  /// Giorno locale della sessione (`2026-10-13`): conta per la streak.
  final String date;
  final DateTime startedAt;
  final DateTime? endedAt;
  final String template;
  final int plannedSets;
  final int completedSets;
  const WorkoutSession({
    required this.id,
    required this.date,
    required this.startedAt,
    this.endedAt,
    required this.template,
    required this.plannedSets,
    required this.completedSets,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['date'] = Variable<String>(date);
    map['started_at'] = Variable<DateTime>(startedAt);
    if (!nullToAbsent || endedAt != null) {
      map['ended_at'] = Variable<DateTime>(endedAt);
    }
    map['template'] = Variable<String>(template);
    map['planned_sets'] = Variable<int>(plannedSets);
    map['completed_sets'] = Variable<int>(completedSets);
    return map;
  }

  WorkoutSessionsCompanion toCompanion(bool nullToAbsent) {
    return WorkoutSessionsCompanion(
      id: Value(id),
      date: Value(date),
      startedAt: Value(startedAt),
      endedAt: endedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(endedAt),
      template: Value(template),
      plannedSets: Value(plannedSets),
      completedSets: Value(completedSets),
    );
  }

  factory WorkoutSession.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorkoutSession(
      id: serializer.fromJson<int>(json['id']),
      date: serializer.fromJson<String>(json['date']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      endedAt: serializer.fromJson<DateTime?>(json['endedAt']),
      template: serializer.fromJson<String>(json['template']),
      plannedSets: serializer.fromJson<int>(json['plannedSets']),
      completedSets: serializer.fromJson<int>(json['completedSets']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'date': serializer.toJson<String>(date),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'endedAt': serializer.toJson<DateTime?>(endedAt),
      'template': serializer.toJson<String>(template),
      'plannedSets': serializer.toJson<int>(plannedSets),
      'completedSets': serializer.toJson<int>(completedSets),
    };
  }

  WorkoutSession copyWith({
    int? id,
    String? date,
    DateTime? startedAt,
    Value<DateTime?> endedAt = const Value.absent(),
    String? template,
    int? plannedSets,
    int? completedSets,
  }) => WorkoutSession(
    id: id ?? this.id,
    date: date ?? this.date,
    startedAt: startedAt ?? this.startedAt,
    endedAt: endedAt.present ? endedAt.value : this.endedAt,
    template: template ?? this.template,
    plannedSets: plannedSets ?? this.plannedSets,
    completedSets: completedSets ?? this.completedSets,
  );
  WorkoutSession copyWithCompanion(WorkoutSessionsCompanion data) {
    return WorkoutSession(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
      template: data.template.present ? data.template.value : this.template,
      plannedSets: data.plannedSets.present
          ? data.plannedSets.value
          : this.plannedSets,
      completedSets: data.completedSets.present
          ? data.completedSets.value
          : this.completedSets,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutSession(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('template: $template, ')
          ..write('plannedSets: $plannedSets, ')
          ..write('completedSets: $completedSets')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    date,
    startedAt,
    endedAt,
    template,
    plannedSets,
    completedSets,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkoutSession &&
          other.id == this.id &&
          other.date == this.date &&
          other.startedAt == this.startedAt &&
          other.endedAt == this.endedAt &&
          other.template == this.template &&
          other.plannedSets == this.plannedSets &&
          other.completedSets == this.completedSets);
}

class WorkoutSessionsCompanion extends UpdateCompanion<WorkoutSession> {
  final Value<int> id;
  final Value<String> date;
  final Value<DateTime> startedAt;
  final Value<DateTime?> endedAt;
  final Value<String> template;
  final Value<int> plannedSets;
  final Value<int> completedSets;
  const WorkoutSessionsCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.template = const Value.absent(),
    this.plannedSets = const Value.absent(),
    this.completedSets = const Value.absent(),
  });
  WorkoutSessionsCompanion.insert({
    this.id = const Value.absent(),
    required String date,
    required DateTime startedAt,
    this.endedAt = const Value.absent(),
    required String template,
    required int plannedSets,
    this.completedSets = const Value.absent(),
  }) : date = Value(date),
       startedAt = Value(startedAt),
       template = Value(template),
       plannedSets = Value(plannedSets);
  static Insertable<WorkoutSession> custom({
    Expression<int>? id,
    Expression<String>? date,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? endedAt,
    Expression<String>? template,
    Expression<int>? plannedSets,
    Expression<int>? completedSets,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (startedAt != null) 'started_at': startedAt,
      if (endedAt != null) 'ended_at': endedAt,
      if (template != null) 'template': template,
      if (plannedSets != null) 'planned_sets': plannedSets,
      if (completedSets != null) 'completed_sets': completedSets,
    });
  }

  WorkoutSessionsCompanion copyWith({
    Value<int>? id,
    Value<String>? date,
    Value<DateTime>? startedAt,
    Value<DateTime?>? endedAt,
    Value<String>? template,
    Value<int>? plannedSets,
    Value<int>? completedSets,
  }) {
    return WorkoutSessionsCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      template: template ?? this.template,
      plannedSets: plannedSets ?? this.plannedSets,
      completedSets: completedSets ?? this.completedSets,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<DateTime>(endedAt.value);
    }
    if (template.present) {
      map['template'] = Variable<String>(template.value);
    }
    if (plannedSets.present) {
      map['planned_sets'] = Variable<int>(plannedSets.value);
    }
    if (completedSets.present) {
      map['completed_sets'] = Variable<int>(completedSets.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutSessionsCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('template: $template, ')
          ..write('plannedSets: $plannedSets, ')
          ..write('completedSets: $completedSets')
          ..write(')'))
        .toString();
  }
}

class $SetLogsTable extends SetLogs with TableInfo<$SetLogsTable, SetLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SetLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<int> sessionId = GeneratedColumn<int>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES workout_sessions (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _exerciseIdMeta = const VerificationMeta(
    'exerciseId',
  );
  @override
  late final GeneratedColumn<String> exerciseId = GeneratedColumn<String>(
    'exercise_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _chainMeta = const VerificationMeta('chain');
  @override
  late final GeneratedColumn<String> chain = GeneratedColumn<String>(
    'chain',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<int> value = GeneratedColumn<int>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isVolumeMeta = const VerificationMeta(
    'isVolume',
  );
  @override
  late final GeneratedColumn<bool> isVolume = GeneratedColumn<bool>(
    'is_volume',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_volume" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sessionId,
    exerciseId,
    chain,
    value,
    isVolume,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'set_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<SetLog> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('exercise_id')) {
      context.handle(
        _exerciseIdMeta,
        exerciseId.isAcceptableOrUnknown(data['exercise_id']!, _exerciseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_exerciseIdMeta);
    }
    if (data.containsKey('chain')) {
      context.handle(
        _chainMeta,
        chain.isAcceptableOrUnknown(data['chain']!, _chainMeta),
      );
    } else if (isInserting) {
      context.missing(_chainMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('is_volume')) {
      context.handle(
        _isVolumeMeta,
        isVolume.isAcceptableOrUnknown(data['is_volume']!, _isVolumeMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SetLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SetLog(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}session_id'],
      )!,
      exerciseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}exercise_id'],
      )!,
      chain: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}chain'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}value'],
      )!,
      isVolume: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_volume'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $SetLogsTable createAlias(String alias) {
    return $SetLogsTable(attachedDatabase, alias);
  }
}

class SetLog extends DataClass implements Insertable<SetLog> {
  final int id;
  final int sessionId;
  final String exerciseId;
  final String chain;

  /// Ripetizioni o secondi.
  final int value;

  /// Vero se la serie è di volume (variante più facile, non conta per la
  /// progressione).
  final bool isVolume;
  final DateTime createdAt;
  const SetLog({
    required this.id,
    required this.sessionId,
    required this.exerciseId,
    required this.chain,
    required this.value,
    required this.isVolume,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['session_id'] = Variable<int>(sessionId);
    map['exercise_id'] = Variable<String>(exerciseId);
    map['chain'] = Variable<String>(chain);
    map['value'] = Variable<int>(value);
    map['is_volume'] = Variable<bool>(isVolume);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  SetLogsCompanion toCompanion(bool nullToAbsent) {
    return SetLogsCompanion(
      id: Value(id),
      sessionId: Value(sessionId),
      exerciseId: Value(exerciseId),
      chain: Value(chain),
      value: Value(value),
      isVolume: Value(isVolume),
      createdAt: Value(createdAt),
    );
  }

  factory SetLog.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SetLog(
      id: serializer.fromJson<int>(json['id']),
      sessionId: serializer.fromJson<int>(json['sessionId']),
      exerciseId: serializer.fromJson<String>(json['exerciseId']),
      chain: serializer.fromJson<String>(json['chain']),
      value: serializer.fromJson<int>(json['value']),
      isVolume: serializer.fromJson<bool>(json['isVolume']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sessionId': serializer.toJson<int>(sessionId),
      'exerciseId': serializer.toJson<String>(exerciseId),
      'chain': serializer.toJson<String>(chain),
      'value': serializer.toJson<int>(value),
      'isVolume': serializer.toJson<bool>(isVolume),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  SetLog copyWith({
    int? id,
    int? sessionId,
    String? exerciseId,
    String? chain,
    int? value,
    bool? isVolume,
    DateTime? createdAt,
  }) => SetLog(
    id: id ?? this.id,
    sessionId: sessionId ?? this.sessionId,
    exerciseId: exerciseId ?? this.exerciseId,
    chain: chain ?? this.chain,
    value: value ?? this.value,
    isVolume: isVolume ?? this.isVolume,
    createdAt: createdAt ?? this.createdAt,
  );
  SetLog copyWithCompanion(SetLogsCompanion data) {
    return SetLog(
      id: data.id.present ? data.id.value : this.id,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      exerciseId: data.exerciseId.present
          ? data.exerciseId.value
          : this.exerciseId,
      chain: data.chain.present ? data.chain.value : this.chain,
      value: data.value.present ? data.value.value : this.value,
      isVolume: data.isVolume.present ? data.isVolume.value : this.isVolume,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SetLog(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('chain: $chain, ')
          ..write('value: $value, ')
          ..write('isVolume: $isVolume, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, sessionId, exerciseId, chain, value, isVolume, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SetLog &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.exerciseId == this.exerciseId &&
          other.chain == this.chain &&
          other.value == this.value &&
          other.isVolume == this.isVolume &&
          other.createdAt == this.createdAt);
}

class SetLogsCompanion extends UpdateCompanion<SetLog> {
  final Value<int> id;
  final Value<int> sessionId;
  final Value<String> exerciseId;
  final Value<String> chain;
  final Value<int> value;
  final Value<bool> isVolume;
  final Value<DateTime> createdAt;
  const SetLogsCompanion({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.exerciseId = const Value.absent(),
    this.chain = const Value.absent(),
    this.value = const Value.absent(),
    this.isVolume = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  SetLogsCompanion.insert({
    this.id = const Value.absent(),
    required int sessionId,
    required String exerciseId,
    required String chain,
    required int value,
    this.isVolume = const Value.absent(),
    required DateTime createdAt,
  }) : sessionId = Value(sessionId),
       exerciseId = Value(exerciseId),
       chain = Value(chain),
       value = Value(value),
       createdAt = Value(createdAt);
  static Insertable<SetLog> custom({
    Expression<int>? id,
    Expression<int>? sessionId,
    Expression<String>? exerciseId,
    Expression<String>? chain,
    Expression<int>? value,
    Expression<bool>? isVolume,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (exerciseId != null) 'exercise_id': exerciseId,
      if (chain != null) 'chain': chain,
      if (value != null) 'value': value,
      if (isVolume != null) 'is_volume': isVolume,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  SetLogsCompanion copyWith({
    Value<int>? id,
    Value<int>? sessionId,
    Value<String>? exerciseId,
    Value<String>? chain,
    Value<int>? value,
    Value<bool>? isVolume,
    Value<DateTime>? createdAt,
  }) {
    return SetLogsCompanion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      exerciseId: exerciseId ?? this.exerciseId,
      chain: chain ?? this.chain,
      value: value ?? this.value,
      isVolume: isVolume ?? this.isVolume,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<int>(sessionId.value);
    }
    if (exerciseId.present) {
      map['exercise_id'] = Variable<String>(exerciseId.value);
    }
    if (chain.present) {
      map['chain'] = Variable<String>(chain.value);
    }
    if (value.present) {
      map['value'] = Variable<int>(value.value);
    }
    if (isVolume.present) {
      map['is_volume'] = Variable<bool>(isVolume.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SetLogsCompanion(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('chain: $chain, ')
          ..write('value: $value, ')
          ..write('isVolume: $isVolume, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $FoodEntriesTable extends FoodEntries
    with TableInfo<$FoodEntriesTable, FoodEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FoodEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mealMeta = const VerificationMeta('meal');
  @override
  late final GeneratedColumn<String> meal = GeneratedColumn<String>(
    'meal',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _gramsMeta = const VerificationMeta('grams');
  @override
  late final GeneratedColumn<double> grams = GeneratedColumn<double>(
    'grams',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kcal100Meta = const VerificationMeta(
    'kcal100',
  );
  @override
  late final GeneratedColumn<double> kcal100 = GeneratedColumn<double>(
    'kcal100',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _protein100Meta = const VerificationMeta(
    'protein100',
  );
  @override
  late final GeneratedColumn<double> protein100 = GeneratedColumn<double>(
    'protein100',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _carbs100Meta = const VerificationMeta(
    'carbs100',
  );
  @override
  late final GeneratedColumn<double> carbs100 = GeneratedColumn<double>(
    'carbs100',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fat100Meta = const VerificationMeta('fat100');
  @override
  late final GeneratedColumn<double> fat100 = GeneratedColumn<double>(
    'fat100',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sugar100Meta = const VerificationMeta(
    'sugar100',
  );
  @override
  late final GeneratedColumn<double> sugar100 = GeneratedColumn<double>(
    'sugar100',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _barcodeMeta = const VerificationMeta(
    'barcode',
  );
  @override
  late final GeneratedColumn<String> barcode = GeneratedColumn<String>(
    'barcode',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    date,
    meal,
    name,
    grams,
    kcal100,
    protein100,
    carbs100,
    fat100,
    sugar100,
    source,
    barcode,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'food_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<FoodEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('meal')) {
      context.handle(
        _mealMeta,
        meal.isAcceptableOrUnknown(data['meal']!, _mealMeta),
      );
    } else if (isInserting) {
      context.missing(_mealMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('grams')) {
      context.handle(
        _gramsMeta,
        grams.isAcceptableOrUnknown(data['grams']!, _gramsMeta),
      );
    } else if (isInserting) {
      context.missing(_gramsMeta);
    }
    if (data.containsKey('kcal100')) {
      context.handle(
        _kcal100Meta,
        kcal100.isAcceptableOrUnknown(data['kcal100']!, _kcal100Meta),
      );
    } else if (isInserting) {
      context.missing(_kcal100Meta);
    }
    if (data.containsKey('protein100')) {
      context.handle(
        _protein100Meta,
        protein100.isAcceptableOrUnknown(data['protein100']!, _protein100Meta),
      );
    } else if (isInserting) {
      context.missing(_protein100Meta);
    }
    if (data.containsKey('carbs100')) {
      context.handle(
        _carbs100Meta,
        carbs100.isAcceptableOrUnknown(data['carbs100']!, _carbs100Meta),
      );
    } else if (isInserting) {
      context.missing(_carbs100Meta);
    }
    if (data.containsKey('fat100')) {
      context.handle(
        _fat100Meta,
        fat100.isAcceptableOrUnknown(data['fat100']!, _fat100Meta),
      );
    } else if (isInserting) {
      context.missing(_fat100Meta);
    }
    if (data.containsKey('sugar100')) {
      context.handle(
        _sugar100Meta,
        sugar100.isAcceptableOrUnknown(data['sugar100']!, _sugar100Meta),
      );
    } else if (isInserting) {
      context.missing(_sugar100Meta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('barcode')) {
      context.handle(
        _barcodeMeta,
        barcode.isAcceptableOrUnknown(data['barcode']!, _barcodeMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FoodEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FoodEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      meal: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}meal'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      grams: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}grams'],
      )!,
      kcal100: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}kcal100'],
      )!,
      protein100: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}protein100'],
      )!,
      carbs100: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}carbs100'],
      )!,
      fat100: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}fat100'],
      )!,
      sugar100: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}sugar100'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      barcode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}barcode'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $FoodEntriesTable createAlias(String alias) {
    return $FoodEntriesTable(attachedDatabase, alias);
  }
}

class FoodEntry extends DataClass implements Insertable<FoodEntry> {
  final int id;
  final String date;

  /// breakfast, lunch, snack, dinner.
  final String meal;
  final String name;
  final double grams;
  final double kcal100;
  final double protein100;
  final double carbs100;
  final double fat100;
  final double sugar100;
  final String source;
  final String? barcode;
  final DateTime createdAt;
  const FoodEntry({
    required this.id,
    required this.date,
    required this.meal,
    required this.name,
    required this.grams,
    required this.kcal100,
    required this.protein100,
    required this.carbs100,
    required this.fat100,
    required this.sugar100,
    required this.source,
    this.barcode,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['date'] = Variable<String>(date);
    map['meal'] = Variable<String>(meal);
    map['name'] = Variable<String>(name);
    map['grams'] = Variable<double>(grams);
    map['kcal100'] = Variable<double>(kcal100);
    map['protein100'] = Variable<double>(protein100);
    map['carbs100'] = Variable<double>(carbs100);
    map['fat100'] = Variable<double>(fat100);
    map['sugar100'] = Variable<double>(sugar100);
    map['source'] = Variable<String>(source);
    if (!nullToAbsent || barcode != null) {
      map['barcode'] = Variable<String>(barcode);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  FoodEntriesCompanion toCompanion(bool nullToAbsent) {
    return FoodEntriesCompanion(
      id: Value(id),
      date: Value(date),
      meal: Value(meal),
      name: Value(name),
      grams: Value(grams),
      kcal100: Value(kcal100),
      protein100: Value(protein100),
      carbs100: Value(carbs100),
      fat100: Value(fat100),
      sugar100: Value(sugar100),
      source: Value(source),
      barcode: barcode == null && nullToAbsent
          ? const Value.absent()
          : Value(barcode),
      createdAt: Value(createdAt),
    );
  }

  factory FoodEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FoodEntry(
      id: serializer.fromJson<int>(json['id']),
      date: serializer.fromJson<String>(json['date']),
      meal: serializer.fromJson<String>(json['meal']),
      name: serializer.fromJson<String>(json['name']),
      grams: serializer.fromJson<double>(json['grams']),
      kcal100: serializer.fromJson<double>(json['kcal100']),
      protein100: serializer.fromJson<double>(json['protein100']),
      carbs100: serializer.fromJson<double>(json['carbs100']),
      fat100: serializer.fromJson<double>(json['fat100']),
      sugar100: serializer.fromJson<double>(json['sugar100']),
      source: serializer.fromJson<String>(json['source']),
      barcode: serializer.fromJson<String?>(json['barcode']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'date': serializer.toJson<String>(date),
      'meal': serializer.toJson<String>(meal),
      'name': serializer.toJson<String>(name),
      'grams': serializer.toJson<double>(grams),
      'kcal100': serializer.toJson<double>(kcal100),
      'protein100': serializer.toJson<double>(protein100),
      'carbs100': serializer.toJson<double>(carbs100),
      'fat100': serializer.toJson<double>(fat100),
      'sugar100': serializer.toJson<double>(sugar100),
      'source': serializer.toJson<String>(source),
      'barcode': serializer.toJson<String?>(barcode),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  FoodEntry copyWith({
    int? id,
    String? date,
    String? meal,
    String? name,
    double? grams,
    double? kcal100,
    double? protein100,
    double? carbs100,
    double? fat100,
    double? sugar100,
    String? source,
    Value<String?> barcode = const Value.absent(),
    DateTime? createdAt,
  }) => FoodEntry(
    id: id ?? this.id,
    date: date ?? this.date,
    meal: meal ?? this.meal,
    name: name ?? this.name,
    grams: grams ?? this.grams,
    kcal100: kcal100 ?? this.kcal100,
    protein100: protein100 ?? this.protein100,
    carbs100: carbs100 ?? this.carbs100,
    fat100: fat100 ?? this.fat100,
    sugar100: sugar100 ?? this.sugar100,
    source: source ?? this.source,
    barcode: barcode.present ? barcode.value : this.barcode,
    createdAt: createdAt ?? this.createdAt,
  );
  FoodEntry copyWithCompanion(FoodEntriesCompanion data) {
    return FoodEntry(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      meal: data.meal.present ? data.meal.value : this.meal,
      name: data.name.present ? data.name.value : this.name,
      grams: data.grams.present ? data.grams.value : this.grams,
      kcal100: data.kcal100.present ? data.kcal100.value : this.kcal100,
      protein100: data.protein100.present
          ? data.protein100.value
          : this.protein100,
      carbs100: data.carbs100.present ? data.carbs100.value : this.carbs100,
      fat100: data.fat100.present ? data.fat100.value : this.fat100,
      sugar100: data.sugar100.present ? data.sugar100.value : this.sugar100,
      source: data.source.present ? data.source.value : this.source,
      barcode: data.barcode.present ? data.barcode.value : this.barcode,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FoodEntry(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('meal: $meal, ')
          ..write('name: $name, ')
          ..write('grams: $grams, ')
          ..write('kcal100: $kcal100, ')
          ..write('protein100: $protein100, ')
          ..write('carbs100: $carbs100, ')
          ..write('fat100: $fat100, ')
          ..write('sugar100: $sugar100, ')
          ..write('source: $source, ')
          ..write('barcode: $barcode, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    date,
    meal,
    name,
    grams,
    kcal100,
    protein100,
    carbs100,
    fat100,
    sugar100,
    source,
    barcode,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FoodEntry &&
          other.id == this.id &&
          other.date == this.date &&
          other.meal == this.meal &&
          other.name == this.name &&
          other.grams == this.grams &&
          other.kcal100 == this.kcal100 &&
          other.protein100 == this.protein100 &&
          other.carbs100 == this.carbs100 &&
          other.fat100 == this.fat100 &&
          other.sugar100 == this.sugar100 &&
          other.source == this.source &&
          other.barcode == this.barcode &&
          other.createdAt == this.createdAt);
}

class FoodEntriesCompanion extends UpdateCompanion<FoodEntry> {
  final Value<int> id;
  final Value<String> date;
  final Value<String> meal;
  final Value<String> name;
  final Value<double> grams;
  final Value<double> kcal100;
  final Value<double> protein100;
  final Value<double> carbs100;
  final Value<double> fat100;
  final Value<double> sugar100;
  final Value<String> source;
  final Value<String?> barcode;
  final Value<DateTime> createdAt;
  const FoodEntriesCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.meal = const Value.absent(),
    this.name = const Value.absent(),
    this.grams = const Value.absent(),
    this.kcal100 = const Value.absent(),
    this.protein100 = const Value.absent(),
    this.carbs100 = const Value.absent(),
    this.fat100 = const Value.absent(),
    this.sugar100 = const Value.absent(),
    this.source = const Value.absent(),
    this.barcode = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  FoodEntriesCompanion.insert({
    this.id = const Value.absent(),
    required String date,
    required String meal,
    required String name,
    required double grams,
    required double kcal100,
    required double protein100,
    required double carbs100,
    required double fat100,
    required double sugar100,
    required String source,
    this.barcode = const Value.absent(),
    required DateTime createdAt,
  }) : date = Value(date),
       meal = Value(meal),
       name = Value(name),
       grams = Value(grams),
       kcal100 = Value(kcal100),
       protein100 = Value(protein100),
       carbs100 = Value(carbs100),
       fat100 = Value(fat100),
       sugar100 = Value(sugar100),
       source = Value(source),
       createdAt = Value(createdAt);
  static Insertable<FoodEntry> custom({
    Expression<int>? id,
    Expression<String>? date,
    Expression<String>? meal,
    Expression<String>? name,
    Expression<double>? grams,
    Expression<double>? kcal100,
    Expression<double>? protein100,
    Expression<double>? carbs100,
    Expression<double>? fat100,
    Expression<double>? sugar100,
    Expression<String>? source,
    Expression<String>? barcode,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (meal != null) 'meal': meal,
      if (name != null) 'name': name,
      if (grams != null) 'grams': grams,
      if (kcal100 != null) 'kcal100': kcal100,
      if (protein100 != null) 'protein100': protein100,
      if (carbs100 != null) 'carbs100': carbs100,
      if (fat100 != null) 'fat100': fat100,
      if (sugar100 != null) 'sugar100': sugar100,
      if (source != null) 'source': source,
      if (barcode != null) 'barcode': barcode,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  FoodEntriesCompanion copyWith({
    Value<int>? id,
    Value<String>? date,
    Value<String>? meal,
    Value<String>? name,
    Value<double>? grams,
    Value<double>? kcal100,
    Value<double>? protein100,
    Value<double>? carbs100,
    Value<double>? fat100,
    Value<double>? sugar100,
    Value<String>? source,
    Value<String?>? barcode,
    Value<DateTime>? createdAt,
  }) {
    return FoodEntriesCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      meal: meal ?? this.meal,
      name: name ?? this.name,
      grams: grams ?? this.grams,
      kcal100: kcal100 ?? this.kcal100,
      protein100: protein100 ?? this.protein100,
      carbs100: carbs100 ?? this.carbs100,
      fat100: fat100 ?? this.fat100,
      sugar100: sugar100 ?? this.sugar100,
      source: source ?? this.source,
      barcode: barcode ?? this.barcode,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (meal.present) {
      map['meal'] = Variable<String>(meal.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (grams.present) {
      map['grams'] = Variable<double>(grams.value);
    }
    if (kcal100.present) {
      map['kcal100'] = Variable<double>(kcal100.value);
    }
    if (protein100.present) {
      map['protein100'] = Variable<double>(protein100.value);
    }
    if (carbs100.present) {
      map['carbs100'] = Variable<double>(carbs100.value);
    }
    if (fat100.present) {
      map['fat100'] = Variable<double>(fat100.value);
    }
    if (sugar100.present) {
      map['sugar100'] = Variable<double>(sugar100.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (barcode.present) {
      map['barcode'] = Variable<String>(barcode.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FoodEntriesCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('meal: $meal, ')
          ..write('name: $name, ')
          ..write('grams: $grams, ')
          ..write('kcal100: $kcal100, ')
          ..write('protein100: $protein100, ')
          ..write('carbs100: $carbs100, ')
          ..write('fat100: $fat100, ')
          ..write('sugar100: $sugar100, ')
          ..write('source: $source, ')
          ..write('barcode: $barcode, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $FavoriteFoodsTable extends FavoriteFoods
    with TableInfo<$FavoriteFoodsTable, FavoriteFood> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FavoriteFoodsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _gramsMeta = const VerificationMeta('grams');
  @override
  late final GeneratedColumn<double> grams = GeneratedColumn<double>(
    'grams',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kcal100Meta = const VerificationMeta(
    'kcal100',
  );
  @override
  late final GeneratedColumn<double> kcal100 = GeneratedColumn<double>(
    'kcal100',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _protein100Meta = const VerificationMeta(
    'protein100',
  );
  @override
  late final GeneratedColumn<double> protein100 = GeneratedColumn<double>(
    'protein100',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _carbs100Meta = const VerificationMeta(
    'carbs100',
  );
  @override
  late final GeneratedColumn<double> carbs100 = GeneratedColumn<double>(
    'carbs100',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fat100Meta = const VerificationMeta('fat100');
  @override
  late final GeneratedColumn<double> fat100 = GeneratedColumn<double>(
    'fat100',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sugar100Meta = const VerificationMeta(
    'sugar100',
  );
  @override
  late final GeneratedColumn<double> sugar100 = GeneratedColumn<double>(
    'sugar100',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _barcodeMeta = const VerificationMeta(
    'barcode',
  );
  @override
  late final GeneratedColumn<String> barcode = GeneratedColumn<String>(
    'barcode',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    grams,
    kcal100,
    protein100,
    carbs100,
    fat100,
    sugar100,
    source,
    barcode,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'favorite_foods';
  @override
  VerificationContext validateIntegrity(
    Insertable<FavoriteFood> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('grams')) {
      context.handle(
        _gramsMeta,
        grams.isAcceptableOrUnknown(data['grams']!, _gramsMeta),
      );
    } else if (isInserting) {
      context.missing(_gramsMeta);
    }
    if (data.containsKey('kcal100')) {
      context.handle(
        _kcal100Meta,
        kcal100.isAcceptableOrUnknown(data['kcal100']!, _kcal100Meta),
      );
    } else if (isInserting) {
      context.missing(_kcal100Meta);
    }
    if (data.containsKey('protein100')) {
      context.handle(
        _protein100Meta,
        protein100.isAcceptableOrUnknown(data['protein100']!, _protein100Meta),
      );
    } else if (isInserting) {
      context.missing(_protein100Meta);
    }
    if (data.containsKey('carbs100')) {
      context.handle(
        _carbs100Meta,
        carbs100.isAcceptableOrUnknown(data['carbs100']!, _carbs100Meta),
      );
    } else if (isInserting) {
      context.missing(_carbs100Meta);
    }
    if (data.containsKey('fat100')) {
      context.handle(
        _fat100Meta,
        fat100.isAcceptableOrUnknown(data['fat100']!, _fat100Meta),
      );
    } else if (isInserting) {
      context.missing(_fat100Meta);
    }
    if (data.containsKey('sugar100')) {
      context.handle(
        _sugar100Meta,
        sugar100.isAcceptableOrUnknown(data['sugar100']!, _sugar100Meta),
      );
    } else if (isInserting) {
      context.missing(_sugar100Meta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('barcode')) {
      context.handle(
        _barcodeMeta,
        barcode.isAcceptableOrUnknown(data['barcode']!, _barcodeMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FavoriteFood map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FavoriteFood(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      grams: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}grams'],
      )!,
      kcal100: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}kcal100'],
      )!,
      protein100: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}protein100'],
      )!,
      carbs100: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}carbs100'],
      )!,
      fat100: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}fat100'],
      )!,
      sugar100: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}sugar100'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      barcode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}barcode'],
      ),
    );
  }

  @override
  $FavoriteFoodsTable createAlias(String alias) {
    return $FavoriteFoodsTable(attachedDatabase, alias);
  }
}

class FavoriteFood extends DataClass implements Insertable<FavoriteFood> {
  final int id;
  final String name;
  final double grams;
  final double kcal100;
  final double protein100;
  final double carbs100;
  final double fat100;
  final double sugar100;
  final String source;
  final String? barcode;
  const FavoriteFood({
    required this.id,
    required this.name,
    required this.grams,
    required this.kcal100,
    required this.protein100,
    required this.carbs100,
    required this.fat100,
    required this.sugar100,
    required this.source,
    this.barcode,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['grams'] = Variable<double>(grams);
    map['kcal100'] = Variable<double>(kcal100);
    map['protein100'] = Variable<double>(protein100);
    map['carbs100'] = Variable<double>(carbs100);
    map['fat100'] = Variable<double>(fat100);
    map['sugar100'] = Variable<double>(sugar100);
    map['source'] = Variable<String>(source);
    if (!nullToAbsent || barcode != null) {
      map['barcode'] = Variable<String>(barcode);
    }
    return map;
  }

  FavoriteFoodsCompanion toCompanion(bool nullToAbsent) {
    return FavoriteFoodsCompanion(
      id: Value(id),
      name: Value(name),
      grams: Value(grams),
      kcal100: Value(kcal100),
      protein100: Value(protein100),
      carbs100: Value(carbs100),
      fat100: Value(fat100),
      sugar100: Value(sugar100),
      source: Value(source),
      barcode: barcode == null && nullToAbsent
          ? const Value.absent()
          : Value(barcode),
    );
  }

  factory FavoriteFood.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FavoriteFood(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      grams: serializer.fromJson<double>(json['grams']),
      kcal100: serializer.fromJson<double>(json['kcal100']),
      protein100: serializer.fromJson<double>(json['protein100']),
      carbs100: serializer.fromJson<double>(json['carbs100']),
      fat100: serializer.fromJson<double>(json['fat100']),
      sugar100: serializer.fromJson<double>(json['sugar100']),
      source: serializer.fromJson<String>(json['source']),
      barcode: serializer.fromJson<String?>(json['barcode']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'grams': serializer.toJson<double>(grams),
      'kcal100': serializer.toJson<double>(kcal100),
      'protein100': serializer.toJson<double>(protein100),
      'carbs100': serializer.toJson<double>(carbs100),
      'fat100': serializer.toJson<double>(fat100),
      'sugar100': serializer.toJson<double>(sugar100),
      'source': serializer.toJson<String>(source),
      'barcode': serializer.toJson<String?>(barcode),
    };
  }

  FavoriteFood copyWith({
    int? id,
    String? name,
    double? grams,
    double? kcal100,
    double? protein100,
    double? carbs100,
    double? fat100,
    double? sugar100,
    String? source,
    Value<String?> barcode = const Value.absent(),
  }) => FavoriteFood(
    id: id ?? this.id,
    name: name ?? this.name,
    grams: grams ?? this.grams,
    kcal100: kcal100 ?? this.kcal100,
    protein100: protein100 ?? this.protein100,
    carbs100: carbs100 ?? this.carbs100,
    fat100: fat100 ?? this.fat100,
    sugar100: sugar100 ?? this.sugar100,
    source: source ?? this.source,
    barcode: barcode.present ? barcode.value : this.barcode,
  );
  FavoriteFood copyWithCompanion(FavoriteFoodsCompanion data) {
    return FavoriteFood(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      grams: data.grams.present ? data.grams.value : this.grams,
      kcal100: data.kcal100.present ? data.kcal100.value : this.kcal100,
      protein100: data.protein100.present
          ? data.protein100.value
          : this.protein100,
      carbs100: data.carbs100.present ? data.carbs100.value : this.carbs100,
      fat100: data.fat100.present ? data.fat100.value : this.fat100,
      sugar100: data.sugar100.present ? data.sugar100.value : this.sugar100,
      source: data.source.present ? data.source.value : this.source,
      barcode: data.barcode.present ? data.barcode.value : this.barcode,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FavoriteFood(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('grams: $grams, ')
          ..write('kcal100: $kcal100, ')
          ..write('protein100: $protein100, ')
          ..write('carbs100: $carbs100, ')
          ..write('fat100: $fat100, ')
          ..write('sugar100: $sugar100, ')
          ..write('source: $source, ')
          ..write('barcode: $barcode')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    grams,
    kcal100,
    protein100,
    carbs100,
    fat100,
    sugar100,
    source,
    barcode,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FavoriteFood &&
          other.id == this.id &&
          other.name == this.name &&
          other.grams == this.grams &&
          other.kcal100 == this.kcal100 &&
          other.protein100 == this.protein100 &&
          other.carbs100 == this.carbs100 &&
          other.fat100 == this.fat100 &&
          other.sugar100 == this.sugar100 &&
          other.source == this.source &&
          other.barcode == this.barcode);
}

class FavoriteFoodsCompanion extends UpdateCompanion<FavoriteFood> {
  final Value<int> id;
  final Value<String> name;
  final Value<double> grams;
  final Value<double> kcal100;
  final Value<double> protein100;
  final Value<double> carbs100;
  final Value<double> fat100;
  final Value<double> sugar100;
  final Value<String> source;
  final Value<String?> barcode;
  const FavoriteFoodsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.grams = const Value.absent(),
    this.kcal100 = const Value.absent(),
    this.protein100 = const Value.absent(),
    this.carbs100 = const Value.absent(),
    this.fat100 = const Value.absent(),
    this.sugar100 = const Value.absent(),
    this.source = const Value.absent(),
    this.barcode = const Value.absent(),
  });
  FavoriteFoodsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required double grams,
    required double kcal100,
    required double protein100,
    required double carbs100,
    required double fat100,
    required double sugar100,
    required String source,
    this.barcode = const Value.absent(),
  }) : name = Value(name),
       grams = Value(grams),
       kcal100 = Value(kcal100),
       protein100 = Value(protein100),
       carbs100 = Value(carbs100),
       fat100 = Value(fat100),
       sugar100 = Value(sugar100),
       source = Value(source);
  static Insertable<FavoriteFood> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<double>? grams,
    Expression<double>? kcal100,
    Expression<double>? protein100,
    Expression<double>? carbs100,
    Expression<double>? fat100,
    Expression<double>? sugar100,
    Expression<String>? source,
    Expression<String>? barcode,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (grams != null) 'grams': grams,
      if (kcal100 != null) 'kcal100': kcal100,
      if (protein100 != null) 'protein100': protein100,
      if (carbs100 != null) 'carbs100': carbs100,
      if (fat100 != null) 'fat100': fat100,
      if (sugar100 != null) 'sugar100': sugar100,
      if (source != null) 'source': source,
      if (barcode != null) 'barcode': barcode,
    });
  }

  FavoriteFoodsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<double>? grams,
    Value<double>? kcal100,
    Value<double>? protein100,
    Value<double>? carbs100,
    Value<double>? fat100,
    Value<double>? sugar100,
    Value<String>? source,
    Value<String?>? barcode,
  }) {
    return FavoriteFoodsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      grams: grams ?? this.grams,
      kcal100: kcal100 ?? this.kcal100,
      protein100: protein100 ?? this.protein100,
      carbs100: carbs100 ?? this.carbs100,
      fat100: fat100 ?? this.fat100,
      sugar100: sugar100 ?? this.sugar100,
      source: source ?? this.source,
      barcode: barcode ?? this.barcode,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (grams.present) {
      map['grams'] = Variable<double>(grams.value);
    }
    if (kcal100.present) {
      map['kcal100'] = Variable<double>(kcal100.value);
    }
    if (protein100.present) {
      map['protein100'] = Variable<double>(protein100.value);
    }
    if (carbs100.present) {
      map['carbs100'] = Variable<double>(carbs100.value);
    }
    if (fat100.present) {
      map['fat100'] = Variable<double>(fat100.value);
    }
    if (sugar100.present) {
      map['sugar100'] = Variable<double>(sugar100.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (barcode.present) {
      map['barcode'] = Variable<String>(barcode.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FavoriteFoodsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('grams: $grams, ')
          ..write('kcal100: $kcal100, ')
          ..write('protein100: $protein100, ')
          ..write('carbs100: $carbs100, ')
          ..write('fat100: $fat100, ')
          ..write('sugar100: $sugar100, ')
          ..write('source: $source, ')
          ..write('barcode: $barcode')
          ..write(')'))
        .toString();
  }
}

class $ChallengeResultsTable extends ChallengeResults
    with TableInfo<$ChallengeResultsTable, ChallengeResult> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChallengeResultsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _friendIdMeta = const VerificationMeta(
    'friendId',
  );
  @override
  late final GeneratedColumn<String> friendId = GeneratedColumn<String>(
    'friend_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _friendNameMeta = const VerificationMeta(
    'friendName',
  );
  @override
  late final GeneratedColumn<String> friendName = GeneratedColumn<String>(
    'friend_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _modeMeta = const VerificationMeta('mode');
  @override
  late final GeneratedColumn<String> mode = GeneratedColumn<String>(
    'mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _myScoreMeta = const VerificationMeta(
    'myScore',
  );
  @override
  late final GeneratedColumn<int> myScore = GeneratedColumn<int>(
    'my_score',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _friendScoreMeta = const VerificationMeta(
    'friendScore',
  );
  @override
  late final GeneratedColumn<int> friendScore = GeneratedColumn<int>(
    'friend_score',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _manualRepsMeta = const VerificationMeta(
    'manualReps',
  );
  @override
  late final GeneratedColumn<int> manualReps = GeneratedColumn<int>(
    'manual_reps',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _outcomeMeta = const VerificationMeta(
    'outcome',
  );
  @override
  late final GeneratedColumn<String> outcome = GeneratedColumn<String>(
    'outcome',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _playedAtMeta = const VerificationMeta(
    'playedAt',
  );
  @override
  late final GeneratedColumn<DateTime> playedAt = GeneratedColumn<DateTime>(
    'played_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    friendId,
    friendName,
    mode,
    myScore,
    friendScore,
    manualReps,
    outcome,
    playedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'challenge_results';
  @override
  VerificationContext validateIntegrity(
    Insertable<ChallengeResult> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('friend_id')) {
      context.handle(
        _friendIdMeta,
        friendId.isAcceptableOrUnknown(data['friend_id']!, _friendIdMeta),
      );
    } else if (isInserting) {
      context.missing(_friendIdMeta);
    }
    if (data.containsKey('friend_name')) {
      context.handle(
        _friendNameMeta,
        friendName.isAcceptableOrUnknown(data['friend_name']!, _friendNameMeta),
      );
    } else if (isInserting) {
      context.missing(_friendNameMeta);
    }
    if (data.containsKey('mode')) {
      context.handle(
        _modeMeta,
        mode.isAcceptableOrUnknown(data['mode']!, _modeMeta),
      );
    } else if (isInserting) {
      context.missing(_modeMeta);
    }
    if (data.containsKey('my_score')) {
      context.handle(
        _myScoreMeta,
        myScore.isAcceptableOrUnknown(data['my_score']!, _myScoreMeta),
      );
    } else if (isInserting) {
      context.missing(_myScoreMeta);
    }
    if (data.containsKey('friend_score')) {
      context.handle(
        _friendScoreMeta,
        friendScore.isAcceptableOrUnknown(
          data['friend_score']!,
          _friendScoreMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_friendScoreMeta);
    }
    if (data.containsKey('manual_reps')) {
      context.handle(
        _manualRepsMeta,
        manualReps.isAcceptableOrUnknown(data['manual_reps']!, _manualRepsMeta),
      );
    }
    if (data.containsKey('outcome')) {
      context.handle(
        _outcomeMeta,
        outcome.isAcceptableOrUnknown(data['outcome']!, _outcomeMeta),
      );
    } else if (isInserting) {
      context.missing(_outcomeMeta);
    }
    if (data.containsKey('played_at')) {
      context.handle(
        _playedAtMeta,
        playedAt.isAcceptableOrUnknown(data['played_at']!, _playedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_playedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ChallengeResult map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChallengeResult(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      friendId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}friend_id'],
      )!,
      friendName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}friend_name'],
      )!,
      mode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mode'],
      )!,
      myScore: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}my_score'],
      )!,
      friendScore: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}friend_score'],
      )!,
      manualReps: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}manual_reps'],
      )!,
      outcome: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}outcome'],
      )!,
      playedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}played_at'],
      )!,
    );
  }

  @override
  $ChallengeResultsTable createAlias(String alias) {
    return $ChallengeResultsTable(attachedDatabase, alias);
  }
}

class ChallengeResult extends DataClass implements Insertable<ChallengeResult> {
  final String id;
  final String friendId;
  final String friendName;
  final String mode;
  final int myScore;
  final int friendScore;

  /// Ripetizioni contate a mano con "+1".
  final int manualReps;

  /// win, loss, draw, team.
  final String outcome;
  final DateTime playedAt;
  const ChallengeResult({
    required this.id,
    required this.friendId,
    required this.friendName,
    required this.mode,
    required this.myScore,
    required this.friendScore,
    required this.manualReps,
    required this.outcome,
    required this.playedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['friend_id'] = Variable<String>(friendId);
    map['friend_name'] = Variable<String>(friendName);
    map['mode'] = Variable<String>(mode);
    map['my_score'] = Variable<int>(myScore);
    map['friend_score'] = Variable<int>(friendScore);
    map['manual_reps'] = Variable<int>(manualReps);
    map['outcome'] = Variable<String>(outcome);
    map['played_at'] = Variable<DateTime>(playedAt);
    return map;
  }

  ChallengeResultsCompanion toCompanion(bool nullToAbsent) {
    return ChallengeResultsCompanion(
      id: Value(id),
      friendId: Value(friendId),
      friendName: Value(friendName),
      mode: Value(mode),
      myScore: Value(myScore),
      friendScore: Value(friendScore),
      manualReps: Value(manualReps),
      outcome: Value(outcome),
      playedAt: Value(playedAt),
    );
  }

  factory ChallengeResult.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChallengeResult(
      id: serializer.fromJson<String>(json['id']),
      friendId: serializer.fromJson<String>(json['friendId']),
      friendName: serializer.fromJson<String>(json['friendName']),
      mode: serializer.fromJson<String>(json['mode']),
      myScore: serializer.fromJson<int>(json['myScore']),
      friendScore: serializer.fromJson<int>(json['friendScore']),
      manualReps: serializer.fromJson<int>(json['manualReps']),
      outcome: serializer.fromJson<String>(json['outcome']),
      playedAt: serializer.fromJson<DateTime>(json['playedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'friendId': serializer.toJson<String>(friendId),
      'friendName': serializer.toJson<String>(friendName),
      'mode': serializer.toJson<String>(mode),
      'myScore': serializer.toJson<int>(myScore),
      'friendScore': serializer.toJson<int>(friendScore),
      'manualReps': serializer.toJson<int>(manualReps),
      'outcome': serializer.toJson<String>(outcome),
      'playedAt': serializer.toJson<DateTime>(playedAt),
    };
  }

  ChallengeResult copyWith({
    String? id,
    String? friendId,
    String? friendName,
    String? mode,
    int? myScore,
    int? friendScore,
    int? manualReps,
    String? outcome,
    DateTime? playedAt,
  }) => ChallengeResult(
    id: id ?? this.id,
    friendId: friendId ?? this.friendId,
    friendName: friendName ?? this.friendName,
    mode: mode ?? this.mode,
    myScore: myScore ?? this.myScore,
    friendScore: friendScore ?? this.friendScore,
    manualReps: manualReps ?? this.manualReps,
    outcome: outcome ?? this.outcome,
    playedAt: playedAt ?? this.playedAt,
  );
  ChallengeResult copyWithCompanion(ChallengeResultsCompanion data) {
    return ChallengeResult(
      id: data.id.present ? data.id.value : this.id,
      friendId: data.friendId.present ? data.friendId.value : this.friendId,
      friendName: data.friendName.present
          ? data.friendName.value
          : this.friendName,
      mode: data.mode.present ? data.mode.value : this.mode,
      myScore: data.myScore.present ? data.myScore.value : this.myScore,
      friendScore: data.friendScore.present
          ? data.friendScore.value
          : this.friendScore,
      manualReps: data.manualReps.present
          ? data.manualReps.value
          : this.manualReps,
      outcome: data.outcome.present ? data.outcome.value : this.outcome,
      playedAt: data.playedAt.present ? data.playedAt.value : this.playedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChallengeResult(')
          ..write('id: $id, ')
          ..write('friendId: $friendId, ')
          ..write('friendName: $friendName, ')
          ..write('mode: $mode, ')
          ..write('myScore: $myScore, ')
          ..write('friendScore: $friendScore, ')
          ..write('manualReps: $manualReps, ')
          ..write('outcome: $outcome, ')
          ..write('playedAt: $playedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    friendId,
    friendName,
    mode,
    myScore,
    friendScore,
    manualReps,
    outcome,
    playedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChallengeResult &&
          other.id == this.id &&
          other.friendId == this.friendId &&
          other.friendName == this.friendName &&
          other.mode == this.mode &&
          other.myScore == this.myScore &&
          other.friendScore == this.friendScore &&
          other.manualReps == this.manualReps &&
          other.outcome == this.outcome &&
          other.playedAt == this.playedAt);
}

class ChallengeResultsCompanion extends UpdateCompanion<ChallengeResult> {
  final Value<String> id;
  final Value<String> friendId;
  final Value<String> friendName;
  final Value<String> mode;
  final Value<int> myScore;
  final Value<int> friendScore;
  final Value<int> manualReps;
  final Value<String> outcome;
  final Value<DateTime> playedAt;
  final Value<int> rowid;
  const ChallengeResultsCompanion({
    this.id = const Value.absent(),
    this.friendId = const Value.absent(),
    this.friendName = const Value.absent(),
    this.mode = const Value.absent(),
    this.myScore = const Value.absent(),
    this.friendScore = const Value.absent(),
    this.manualReps = const Value.absent(),
    this.outcome = const Value.absent(),
    this.playedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ChallengeResultsCompanion.insert({
    required String id,
    required String friendId,
    required String friendName,
    required String mode,
    required int myScore,
    required int friendScore,
    this.manualReps = const Value.absent(),
    required String outcome,
    required DateTime playedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       friendId = Value(friendId),
       friendName = Value(friendName),
       mode = Value(mode),
       myScore = Value(myScore),
       friendScore = Value(friendScore),
       outcome = Value(outcome),
       playedAt = Value(playedAt);
  static Insertable<ChallengeResult> custom({
    Expression<String>? id,
    Expression<String>? friendId,
    Expression<String>? friendName,
    Expression<String>? mode,
    Expression<int>? myScore,
    Expression<int>? friendScore,
    Expression<int>? manualReps,
    Expression<String>? outcome,
    Expression<DateTime>? playedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (friendId != null) 'friend_id': friendId,
      if (friendName != null) 'friend_name': friendName,
      if (mode != null) 'mode': mode,
      if (myScore != null) 'my_score': myScore,
      if (friendScore != null) 'friend_score': friendScore,
      if (manualReps != null) 'manual_reps': manualReps,
      if (outcome != null) 'outcome': outcome,
      if (playedAt != null) 'played_at': playedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ChallengeResultsCompanion copyWith({
    Value<String>? id,
    Value<String>? friendId,
    Value<String>? friendName,
    Value<String>? mode,
    Value<int>? myScore,
    Value<int>? friendScore,
    Value<int>? manualReps,
    Value<String>? outcome,
    Value<DateTime>? playedAt,
    Value<int>? rowid,
  }) {
    return ChallengeResultsCompanion(
      id: id ?? this.id,
      friendId: friendId ?? this.friendId,
      friendName: friendName ?? this.friendName,
      mode: mode ?? this.mode,
      myScore: myScore ?? this.myScore,
      friendScore: friendScore ?? this.friendScore,
      manualReps: manualReps ?? this.manualReps,
      outcome: outcome ?? this.outcome,
      playedAt: playedAt ?? this.playedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (friendId.present) {
      map['friend_id'] = Variable<String>(friendId.value);
    }
    if (friendName.present) {
      map['friend_name'] = Variable<String>(friendName.value);
    }
    if (mode.present) {
      map['mode'] = Variable<String>(mode.value);
    }
    if (myScore.present) {
      map['my_score'] = Variable<int>(myScore.value);
    }
    if (friendScore.present) {
      map['friend_score'] = Variable<int>(friendScore.value);
    }
    if (manualReps.present) {
      map['manual_reps'] = Variable<int>(manualReps.value);
    }
    if (outcome.present) {
      map['outcome'] = Variable<String>(outcome.value);
    }
    if (playedAt.present) {
      map['played_at'] = Variable<DateTime>(playedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChallengeResultsCompanion(')
          ..write('id: $id, ')
          ..write('friendId: $friendId, ')
          ..write('friendName: $friendName, ')
          ..write('mode: $mode, ')
          ..write('myScore: $myScore, ')
          ..write('friendScore: $friendScore, ')
          ..write('manualReps: $manualReps, ')
          ..write('outcome: $outcome, ')
          ..write('playedAt: $playedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $KeyValuesTable keyValues = $KeyValuesTable(this);
  late final $WorkoutSessionsTable workoutSessions = $WorkoutSessionsTable(
    this,
  );
  late final $SetLogsTable setLogs = $SetLogsTable(this);
  late final $FoodEntriesTable foodEntries = $FoodEntriesTable(this);
  late final $FavoriteFoodsTable favoriteFoods = $FavoriteFoodsTable(this);
  late final $ChallengeResultsTable challengeResults = $ChallengeResultsTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    keyValues,
    workoutSessions,
    setLogs,
    foodEntries,
    favoriteFoods,
    challengeResults,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'workout_sessions',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('set_logs', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$KeyValuesTableCreateCompanionBuilder = KeyValuesCompanion Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $$KeyValuesTableUpdateCompanionBuilder = KeyValuesCompanion Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$KeyValuesTableFilterComposer
    extends Composer<_$AppDatabase, $KeyValuesTable> {
  $$KeyValuesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$KeyValuesTableOrderingComposer
    extends Composer<_$AppDatabase, $KeyValuesTable> {
  $$KeyValuesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$KeyValuesTableAnnotationComposer
    extends Composer<_$AppDatabase, $KeyValuesTable> {
  $$KeyValuesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$KeyValuesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $KeyValuesTable,
          KeyValue,
          $$KeyValuesTableFilterComposer,
          $$KeyValuesTableOrderingComposer,
          $$KeyValuesTableAnnotationComposer,
          $$KeyValuesTableCreateCompanionBuilder,
          $$KeyValuesTableUpdateCompanionBuilder,
          (KeyValue, BaseReferences<_$AppDatabase, $KeyValuesTable, KeyValue>),
          KeyValue,
          PrefetchHooks Function()
        > {
  $$KeyValuesTableTableManager(_$AppDatabase db, $KeyValuesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$KeyValuesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$KeyValuesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$KeyValuesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => KeyValuesCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) => KeyValuesCompanion.insert(key: key, value: value, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$KeyValuesTable, KeyValue>(table),
                  BaseReferences<_$AppDatabase, $KeyValuesTable, KeyValue>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$KeyValuesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $KeyValuesTable,
      KeyValue,
      $$KeyValuesTableFilterComposer,
      $$KeyValuesTableOrderingComposer,
      $$KeyValuesTableAnnotationComposer,
      $$KeyValuesTableCreateCompanionBuilder,
      $$KeyValuesTableUpdateCompanionBuilder,
      (KeyValue, BaseReferences<_$AppDatabase, $KeyValuesTable, KeyValue>),
      KeyValue,
      PrefetchHooks Function()
    >;
typedef $$WorkoutSessionsTableCreateCompanionBuilder =
    WorkoutSessionsCompanion Function({
      Value<int> id,
      required String date,
      required DateTime startedAt,
      Value<DateTime?> endedAt,
      required String template,
      required int plannedSets,
      Value<int> completedSets,
    });
typedef $$WorkoutSessionsTableUpdateCompanionBuilder =
    WorkoutSessionsCompanion Function({
      Value<int> id,
      Value<String> date,
      Value<DateTime> startedAt,
      Value<DateTime?> endedAt,
      Value<String> template,
      Value<int> plannedSets,
      Value<int> completedSets,
    });

final class $$WorkoutSessionsTableReferences
    extends
        BaseReferences<_$AppDatabase, $WorkoutSessionsTable, WorkoutSession> {
  $$WorkoutSessionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$SetLogsTable, List<SetLog>> _setLogsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.setLogs,
    aliasName: 'workout_sessions__id__set_logs__session_id',
  );

  $$SetLogsTableProcessedTableManager get setLogsRefs {
    final manager = $$SetLogsTableTableManager(
      $_db,
      $_db.setLogs,
    ).filter((f) => f.sessionId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_setLogsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$WorkoutSessionsTableFilterComposer
    extends Composer<_$AppDatabase, $WorkoutSessionsTable> {
  $$WorkoutSessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get template => $composableBuilder(
    column: $table.template,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get plannedSets => $composableBuilder(
    column: $table.plannedSets,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get completedSets => $composableBuilder(
    column: $table.completedSets,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> setLogsRefs(
    Expression<bool> Function($$SetLogsTableFilterComposer f) f,
  ) {
    final $$SetLogsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.setLogs,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SetLogsTableFilterComposer(
            $db: $db,
            $table: $db.setLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$WorkoutSessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $WorkoutSessionsTable> {
  $$WorkoutSessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get template => $composableBuilder(
    column: $table.template,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get plannedSets => $composableBuilder(
    column: $table.plannedSets,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get completedSets => $composableBuilder(
    column: $table.completedSets,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WorkoutSessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WorkoutSessionsTable> {
  $$WorkoutSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => column);

  GeneratedColumn<String> get template =>
      $composableBuilder(column: $table.template, builder: (column) => column);

  GeneratedColumn<int> get plannedSets => $composableBuilder(
    column: $table.plannedSets,
    builder: (column) => column,
  );

  GeneratedColumn<int> get completedSets => $composableBuilder(
    column: $table.completedSets,
    builder: (column) => column,
  );

  Expression<T> setLogsRefs<T extends Object>(
    Expression<T> Function($$SetLogsTableAnnotationComposer a) f,
  ) {
    final $$SetLogsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.setLogs,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SetLogsTableAnnotationComposer(
            $db: $db,
            $table: $db.setLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$WorkoutSessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WorkoutSessionsTable,
          WorkoutSession,
          $$WorkoutSessionsTableFilterComposer,
          $$WorkoutSessionsTableOrderingComposer,
          $$WorkoutSessionsTableAnnotationComposer,
          $$WorkoutSessionsTableCreateCompanionBuilder,
          $$WorkoutSessionsTableUpdateCompanionBuilder,
          (WorkoutSession, $$WorkoutSessionsTableReferences),
          WorkoutSession,
          PrefetchHooks Function({bool setLogsRefs})
        > {
  $$WorkoutSessionsTableTableManager(
    _$AppDatabase db,
    $WorkoutSessionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorkoutSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WorkoutSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WorkoutSessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime?> endedAt = const Value.absent(),
                Value<String> template = const Value.absent(),
                Value<int> plannedSets = const Value.absent(),
                Value<int> completedSets = const Value.absent(),
              }) => WorkoutSessionsCompanion(
                id: id,
                date: date,
                startedAt: startedAt,
                endedAt: endedAt,
                template: template,
                plannedSets: plannedSets,
                completedSets: completedSets,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String date,
                required DateTime startedAt,
                Value<DateTime?> endedAt = const Value.absent(),
                required String template,
                required int plannedSets,
                Value<int> completedSets = const Value.absent(),
              }) => WorkoutSessionsCompanion.insert(
                id: id,
                date: date,
                startedAt: startedAt,
                endedAt: endedAt,
                template: template,
                plannedSets: plannedSets,
                completedSets: completedSets,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$WorkoutSessionsTable, WorkoutSession>(table),
                  $$WorkoutSessionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({setLogsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (setLogsRefs) db.setLogs],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (setLogsRefs)
                    await $_getPrefetchedData<
                      WorkoutSession,
                      $WorkoutSessionsTable,
                      SetLog
                    >(
                      currentTable: table,
                      referencedTable: $$WorkoutSessionsTableReferences
                          ._setLogsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$WorkoutSessionsTableReferences(
                            db,
                            table,
                            p0,
                          ).setLogsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.sessionId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$WorkoutSessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WorkoutSessionsTable,
      WorkoutSession,
      $$WorkoutSessionsTableFilterComposer,
      $$WorkoutSessionsTableOrderingComposer,
      $$WorkoutSessionsTableAnnotationComposer,
      $$WorkoutSessionsTableCreateCompanionBuilder,
      $$WorkoutSessionsTableUpdateCompanionBuilder,
      (WorkoutSession, $$WorkoutSessionsTableReferences),
      WorkoutSession,
      PrefetchHooks Function({bool setLogsRefs})
    >;
typedef $$SetLogsTableCreateCompanionBuilder = SetLogsCompanion Function({
  Value<int> id,
  required int sessionId,
  required String exerciseId,
  required String chain,
  required int value,
  Value<bool> isVolume,
  required DateTime createdAt,
});
typedef $$SetLogsTableUpdateCompanionBuilder = SetLogsCompanion Function({
  Value<int> id,
  Value<int> sessionId,
  Value<String> exerciseId,
  Value<String> chain,
  Value<int> value,
  Value<bool> isVolume,
  Value<DateTime> createdAt,
});

final class $$SetLogsTableReferences
    extends BaseReferences<_$AppDatabase, $SetLogsTable, SetLog> {
  $$SetLogsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $WorkoutSessionsTable _sessionIdTable(_$AppDatabase db) => db
      .workoutSessions
      .createAlias('set_logs__session_id__workout_sessions__id');

  $$WorkoutSessionsTableProcessedTableManager get sessionId {
    final $_column = $_itemColumn<int>('session_id')!;

    final manager = $$WorkoutSessionsTableTableManager(
      $_db,
      $_db.workoutSessions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sessionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SetLogsTableFilterComposer
    extends Composer<_$AppDatabase, $SetLogsTable> {
  $$SetLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get exerciseId => $composableBuilder(
    column: $table.exerciseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get chain => $composableBuilder(
    column: $table.chain,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isVolume => $composableBuilder(
    column: $table.isVolume,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$WorkoutSessionsTableFilterComposer get sessionId {
    final $$WorkoutSessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.workoutSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutSessionsTableFilterComposer(
            $db: $db,
            $table: $db.workoutSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SetLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $SetLogsTable> {
  $$SetLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get exerciseId => $composableBuilder(
    column: $table.exerciseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get chain => $composableBuilder(
    column: $table.chain,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isVolume => $composableBuilder(
    column: $table.isVolume,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$WorkoutSessionsTableOrderingComposer get sessionId {
    final $$WorkoutSessionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.workoutSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutSessionsTableOrderingComposer(
            $db: $db,
            $table: $db.workoutSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SetLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SetLogsTable> {
  $$SetLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get exerciseId => $composableBuilder(
    column: $table.exerciseId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get chain =>
      $composableBuilder(column: $table.chain, builder: (column) => column);

  GeneratedColumn<int> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<bool> get isVolume =>
      $composableBuilder(column: $table.isVolume, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$WorkoutSessionsTableAnnotationComposer get sessionId {
    final $$WorkoutSessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.workoutSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutSessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.workoutSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SetLogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SetLogsTable,
          SetLog,
          $$SetLogsTableFilterComposer,
          $$SetLogsTableOrderingComposer,
          $$SetLogsTableAnnotationComposer,
          $$SetLogsTableCreateCompanionBuilder,
          $$SetLogsTableUpdateCompanionBuilder,
          (SetLog, $$SetLogsTableReferences),
          SetLog,
          PrefetchHooks Function({bool sessionId})
        > {
  $$SetLogsTableTableManager(_$AppDatabase db, $SetLogsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SetLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SetLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SetLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> sessionId = const Value.absent(),
                Value<String> exerciseId = const Value.absent(),
                Value<String> chain = const Value.absent(),
                Value<int> value = const Value.absent(),
                Value<bool> isVolume = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => SetLogsCompanion(
                id: id,
                sessionId: sessionId,
                exerciseId: exerciseId,
                chain: chain,
                value: value,
                isVolume: isVolume,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int sessionId,
                required String exerciseId,
                required String chain,
                required int value,
                Value<bool> isVolume = const Value.absent(),
                required DateTime createdAt,
              }) => SetLogsCompanion.insert(
                id: id,
                sessionId: sessionId,
                exerciseId: exerciseId,
                chain: chain,
                value: value,
                isVolume: isVolume,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SetLogsTable, SetLog>(table),
                  $$SetLogsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({sessionId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (sessionId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.sessionId,
                        referencedTable: $$SetLogsTableReferences
                            ._sessionIdTable(db),
                        referencedColumn: $$SetLogsTableReferences
                            ._sessionIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$SetLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SetLogsTable,
      SetLog,
      $$SetLogsTableFilterComposer,
      $$SetLogsTableOrderingComposer,
      $$SetLogsTableAnnotationComposer,
      $$SetLogsTableCreateCompanionBuilder,
      $$SetLogsTableUpdateCompanionBuilder,
      (SetLog, $$SetLogsTableReferences),
      SetLog,
      PrefetchHooks Function({bool sessionId})
    >;
typedef $$FoodEntriesTableCreateCompanionBuilder =
    FoodEntriesCompanion Function({
      Value<int> id,
      required String date,
      required String meal,
      required String name,
      required double grams,
      required double kcal100,
      required double protein100,
      required double carbs100,
      required double fat100,
      required double sugar100,
      required String source,
      Value<String?> barcode,
      required DateTime createdAt,
    });
typedef $$FoodEntriesTableUpdateCompanionBuilder =
    FoodEntriesCompanion Function({
      Value<int> id,
      Value<String> date,
      Value<String> meal,
      Value<String> name,
      Value<double> grams,
      Value<double> kcal100,
      Value<double> protein100,
      Value<double> carbs100,
      Value<double> fat100,
      Value<double> sugar100,
      Value<String> source,
      Value<String?> barcode,
      Value<DateTime> createdAt,
    });

class $$FoodEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $FoodEntriesTable> {
  $$FoodEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get meal => $composableBuilder(
    column: $table.meal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get grams => $composableBuilder(
    column: $table.grams,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get kcal100 => $composableBuilder(
    column: $table.kcal100,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get protein100 => $composableBuilder(
    column: $table.protein100,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get carbs100 => $composableBuilder(
    column: $table.carbs100,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get fat100 => $composableBuilder(
    column: $table.fat100,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get sugar100 => $composableBuilder(
    column: $table.sugar100,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get barcode => $composableBuilder(
    column: $table.barcode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FoodEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $FoodEntriesTable> {
  $$FoodEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get meal => $composableBuilder(
    column: $table.meal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get grams => $composableBuilder(
    column: $table.grams,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get kcal100 => $composableBuilder(
    column: $table.kcal100,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get protein100 => $composableBuilder(
    column: $table.protein100,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get carbs100 => $composableBuilder(
    column: $table.carbs100,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get fat100 => $composableBuilder(
    column: $table.fat100,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get sugar100 => $composableBuilder(
    column: $table.sugar100,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get barcode => $composableBuilder(
    column: $table.barcode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FoodEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $FoodEntriesTable> {
  $$FoodEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get meal =>
      $composableBuilder(column: $table.meal, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<double> get grams =>
      $composableBuilder(column: $table.grams, builder: (column) => column);

  GeneratedColumn<double> get kcal100 =>
      $composableBuilder(column: $table.kcal100, builder: (column) => column);

  GeneratedColumn<double> get protein100 => $composableBuilder(
    column: $table.protein100,
    builder: (column) => column,
  );

  GeneratedColumn<double> get carbs100 =>
      $composableBuilder(column: $table.carbs100, builder: (column) => column);

  GeneratedColumn<double> get fat100 =>
      $composableBuilder(column: $table.fat100, builder: (column) => column);

  GeneratedColumn<double> get sugar100 =>
      $composableBuilder(column: $table.sugar100, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get barcode =>
      $composableBuilder(column: $table.barcode, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$FoodEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FoodEntriesTable,
          FoodEntry,
          $$FoodEntriesTableFilterComposer,
          $$FoodEntriesTableOrderingComposer,
          $$FoodEntriesTableAnnotationComposer,
          $$FoodEntriesTableCreateCompanionBuilder,
          $$FoodEntriesTableUpdateCompanionBuilder,
          (
            FoodEntry,
            BaseReferences<_$AppDatabase, $FoodEntriesTable, FoodEntry>,
          ),
          FoodEntry,
          PrefetchHooks Function()
        > {
  $$FoodEntriesTableTableManager(_$AppDatabase db, $FoodEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FoodEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FoodEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FoodEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<String> meal = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<double> grams = const Value.absent(),
                Value<double> kcal100 = const Value.absent(),
                Value<double> protein100 = const Value.absent(),
                Value<double> carbs100 = const Value.absent(),
                Value<double> fat100 = const Value.absent(),
                Value<double> sugar100 = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String?> barcode = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => FoodEntriesCompanion(
                id: id,
                date: date,
                meal: meal,
                name: name,
                grams: grams,
                kcal100: kcal100,
                protein100: protein100,
                carbs100: carbs100,
                fat100: fat100,
                sugar100: sugar100,
                source: source,
                barcode: barcode,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String date,
                required String meal,
                required String name,
                required double grams,
                required double kcal100,
                required double protein100,
                required double carbs100,
                required double fat100,
                required double sugar100,
                required String source,
                Value<String?> barcode = const Value.absent(),
                required DateTime createdAt,
              }) => FoodEntriesCompanion.insert(
                id: id,
                date: date,
                meal: meal,
                name: name,
                grams: grams,
                kcal100: kcal100,
                protein100: protein100,
                carbs100: carbs100,
                fat100: fat100,
                sugar100: sugar100,
                source: source,
                barcode: barcode,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$FoodEntriesTable, FoodEntry>(table),
                  BaseReferences<_$AppDatabase, $FoodEntriesTable, FoodEntry>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FoodEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FoodEntriesTable,
      FoodEntry,
      $$FoodEntriesTableFilterComposer,
      $$FoodEntriesTableOrderingComposer,
      $$FoodEntriesTableAnnotationComposer,
      $$FoodEntriesTableCreateCompanionBuilder,
      $$FoodEntriesTableUpdateCompanionBuilder,
      (FoodEntry, BaseReferences<_$AppDatabase, $FoodEntriesTable, FoodEntry>),
      FoodEntry,
      PrefetchHooks Function()
    >;
typedef $$FavoriteFoodsTableCreateCompanionBuilder =
    FavoriteFoodsCompanion Function({
      Value<int> id,
      required String name,
      required double grams,
      required double kcal100,
      required double protein100,
      required double carbs100,
      required double fat100,
      required double sugar100,
      required String source,
      Value<String?> barcode,
    });
typedef $$FavoriteFoodsTableUpdateCompanionBuilder =
    FavoriteFoodsCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<double> grams,
      Value<double> kcal100,
      Value<double> protein100,
      Value<double> carbs100,
      Value<double> fat100,
      Value<double> sugar100,
      Value<String> source,
      Value<String?> barcode,
    });

class $$FavoriteFoodsTableFilterComposer
    extends Composer<_$AppDatabase, $FavoriteFoodsTable> {
  $$FavoriteFoodsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get grams => $composableBuilder(
    column: $table.grams,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get kcal100 => $composableBuilder(
    column: $table.kcal100,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get protein100 => $composableBuilder(
    column: $table.protein100,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get carbs100 => $composableBuilder(
    column: $table.carbs100,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get fat100 => $composableBuilder(
    column: $table.fat100,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get sugar100 => $composableBuilder(
    column: $table.sugar100,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get barcode => $composableBuilder(
    column: $table.barcode,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FavoriteFoodsTableOrderingComposer
    extends Composer<_$AppDatabase, $FavoriteFoodsTable> {
  $$FavoriteFoodsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get grams => $composableBuilder(
    column: $table.grams,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get kcal100 => $composableBuilder(
    column: $table.kcal100,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get protein100 => $composableBuilder(
    column: $table.protein100,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get carbs100 => $composableBuilder(
    column: $table.carbs100,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get fat100 => $composableBuilder(
    column: $table.fat100,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get sugar100 => $composableBuilder(
    column: $table.sugar100,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get barcode => $composableBuilder(
    column: $table.barcode,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FavoriteFoodsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FavoriteFoodsTable> {
  $$FavoriteFoodsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<double> get grams =>
      $composableBuilder(column: $table.grams, builder: (column) => column);

  GeneratedColumn<double> get kcal100 =>
      $composableBuilder(column: $table.kcal100, builder: (column) => column);

  GeneratedColumn<double> get protein100 => $composableBuilder(
    column: $table.protein100,
    builder: (column) => column,
  );

  GeneratedColumn<double> get carbs100 =>
      $composableBuilder(column: $table.carbs100, builder: (column) => column);

  GeneratedColumn<double> get fat100 =>
      $composableBuilder(column: $table.fat100, builder: (column) => column);

  GeneratedColumn<double> get sugar100 =>
      $composableBuilder(column: $table.sugar100, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get barcode =>
      $composableBuilder(column: $table.barcode, builder: (column) => column);
}

class $$FavoriteFoodsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FavoriteFoodsTable,
          FavoriteFood,
          $$FavoriteFoodsTableFilterComposer,
          $$FavoriteFoodsTableOrderingComposer,
          $$FavoriteFoodsTableAnnotationComposer,
          $$FavoriteFoodsTableCreateCompanionBuilder,
          $$FavoriteFoodsTableUpdateCompanionBuilder,
          (
            FavoriteFood,
            BaseReferences<_$AppDatabase, $FavoriteFoodsTable, FavoriteFood>,
          ),
          FavoriteFood,
          PrefetchHooks Function()
        > {
  $$FavoriteFoodsTableTableManager(_$AppDatabase db, $FavoriteFoodsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FavoriteFoodsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FavoriteFoodsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FavoriteFoodsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<double> grams = const Value.absent(),
                Value<double> kcal100 = const Value.absent(),
                Value<double> protein100 = const Value.absent(),
                Value<double> carbs100 = const Value.absent(),
                Value<double> fat100 = const Value.absent(),
                Value<double> sugar100 = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String?> barcode = const Value.absent(),
              }) => FavoriteFoodsCompanion(
                id: id,
                name: name,
                grams: grams,
                kcal100: kcal100,
                protein100: protein100,
                carbs100: carbs100,
                fat100: fat100,
                sugar100: sugar100,
                source: source,
                barcode: barcode,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required double grams,
                required double kcal100,
                required double protein100,
                required double carbs100,
                required double fat100,
                required double sugar100,
                required String source,
                Value<String?> barcode = const Value.absent(),
              }) => FavoriteFoodsCompanion.insert(
                id: id,
                name: name,
                grams: grams,
                kcal100: kcal100,
                protein100: protein100,
                carbs100: carbs100,
                fat100: fat100,
                sugar100: sugar100,
                source: source,
                barcode: barcode,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$FavoriteFoodsTable, FavoriteFood>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $FavoriteFoodsTable,
                    FavoriteFood
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FavoriteFoodsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FavoriteFoodsTable,
      FavoriteFood,
      $$FavoriteFoodsTableFilterComposer,
      $$FavoriteFoodsTableOrderingComposer,
      $$FavoriteFoodsTableAnnotationComposer,
      $$FavoriteFoodsTableCreateCompanionBuilder,
      $$FavoriteFoodsTableUpdateCompanionBuilder,
      (
        FavoriteFood,
        BaseReferences<_$AppDatabase, $FavoriteFoodsTable, FavoriteFood>,
      ),
      FavoriteFood,
      PrefetchHooks Function()
    >;
typedef $$ChallengeResultsTableCreateCompanionBuilder =
    ChallengeResultsCompanion Function({
      required String id,
      required String friendId,
      required String friendName,
      required String mode,
      required int myScore,
      required int friendScore,
      Value<int> manualReps,
      required String outcome,
      required DateTime playedAt,
      Value<int> rowid,
    });
typedef $$ChallengeResultsTableUpdateCompanionBuilder =
    ChallengeResultsCompanion Function({
      Value<String> id,
      Value<String> friendId,
      Value<String> friendName,
      Value<String> mode,
      Value<int> myScore,
      Value<int> friendScore,
      Value<int> manualReps,
      Value<String> outcome,
      Value<DateTime> playedAt,
      Value<int> rowid,
    });

class $$ChallengeResultsTableFilterComposer
    extends Composer<_$AppDatabase, $ChallengeResultsTable> {
  $$ChallengeResultsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get friendId => $composableBuilder(
    column: $table.friendId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get friendName => $composableBuilder(
    column: $table.friendName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mode => $composableBuilder(
    column: $table.mode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get myScore => $composableBuilder(
    column: $table.myScore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get friendScore => $composableBuilder(
    column: $table.friendScore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get manualReps => $composableBuilder(
    column: $table.manualReps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get outcome => $composableBuilder(
    column: $table.outcome,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get playedAt => $composableBuilder(
    column: $table.playedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ChallengeResultsTableOrderingComposer
    extends Composer<_$AppDatabase, $ChallengeResultsTable> {
  $$ChallengeResultsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get friendId => $composableBuilder(
    column: $table.friendId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get friendName => $composableBuilder(
    column: $table.friendName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mode => $composableBuilder(
    column: $table.mode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get myScore => $composableBuilder(
    column: $table.myScore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get friendScore => $composableBuilder(
    column: $table.friendScore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get manualReps => $composableBuilder(
    column: $table.manualReps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get outcome => $composableBuilder(
    column: $table.outcome,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get playedAt => $composableBuilder(
    column: $table.playedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ChallengeResultsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ChallengeResultsTable> {
  $$ChallengeResultsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get friendId =>
      $composableBuilder(column: $table.friendId, builder: (column) => column);

  GeneratedColumn<String> get friendName => $composableBuilder(
    column: $table.friendName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get mode =>
      $composableBuilder(column: $table.mode, builder: (column) => column);

  GeneratedColumn<int> get myScore =>
      $composableBuilder(column: $table.myScore, builder: (column) => column);

  GeneratedColumn<int> get friendScore => $composableBuilder(
    column: $table.friendScore,
    builder: (column) => column,
  );

  GeneratedColumn<int> get manualReps => $composableBuilder(
    column: $table.manualReps,
    builder: (column) => column,
  );

  GeneratedColumn<String> get outcome =>
      $composableBuilder(column: $table.outcome, builder: (column) => column);

  GeneratedColumn<DateTime> get playedAt =>
      $composableBuilder(column: $table.playedAt, builder: (column) => column);
}

class $$ChallengeResultsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ChallengeResultsTable,
          ChallengeResult,
          $$ChallengeResultsTableFilterComposer,
          $$ChallengeResultsTableOrderingComposer,
          $$ChallengeResultsTableAnnotationComposer,
          $$ChallengeResultsTableCreateCompanionBuilder,
          $$ChallengeResultsTableUpdateCompanionBuilder,
          (
            ChallengeResult,
            BaseReferences<
              _$AppDatabase,
              $ChallengeResultsTable,
              ChallengeResult
            >,
          ),
          ChallengeResult,
          PrefetchHooks Function()
        > {
  $$ChallengeResultsTableTableManager(
    _$AppDatabase db,
    $ChallengeResultsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChallengeResultsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChallengeResultsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChallengeResultsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> friendId = const Value.absent(),
                Value<String> friendName = const Value.absent(),
                Value<String> mode = const Value.absent(),
                Value<int> myScore = const Value.absent(),
                Value<int> friendScore = const Value.absent(),
                Value<int> manualReps = const Value.absent(),
                Value<String> outcome = const Value.absent(),
                Value<DateTime> playedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ChallengeResultsCompanion(
                id: id,
                friendId: friendId,
                friendName: friendName,
                mode: mode,
                myScore: myScore,
                friendScore: friendScore,
                manualReps: manualReps,
                outcome: outcome,
                playedAt: playedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String friendId,
                required String friendName,
                required String mode,
                required int myScore,
                required int friendScore,
                Value<int> manualReps = const Value.absent(),
                required String outcome,
                required DateTime playedAt,
                Value<int> rowid = const Value.absent(),
              }) => ChallengeResultsCompanion.insert(
                id: id,
                friendId: friendId,
                friendName: friendName,
                mode: mode,
                myScore: myScore,
                friendScore: friendScore,
                manualReps: manualReps,
                outcome: outcome,
                playedAt: playedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ChallengeResultsTable, ChallengeResult>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $ChallengeResultsTable,
                    ChallengeResult
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ChallengeResultsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ChallengeResultsTable,
      ChallengeResult,
      $$ChallengeResultsTableFilterComposer,
      $$ChallengeResultsTableOrderingComposer,
      $$ChallengeResultsTableAnnotationComposer,
      $$ChallengeResultsTableCreateCompanionBuilder,
      $$ChallengeResultsTableUpdateCompanionBuilder,
      (
        ChallengeResult,
        BaseReferences<_$AppDatabase, $ChallengeResultsTable, ChallengeResult>,
      ),
      ChallengeResult,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$KeyValuesTableTableManager get keyValues =>
      $$KeyValuesTableTableManager(_db, _db.keyValues);
  $$WorkoutSessionsTableTableManager get workoutSessions =>
      $$WorkoutSessionsTableTableManager(_db, _db.workoutSessions);
  $$SetLogsTableTableManager get setLogs =>
      $$SetLogsTableTableManager(_db, _db.setLogs);
  $$FoodEntriesTableTableManager get foodEntries =>
      $$FoodEntriesTableTableManager(_db, _db.foodEntries);
  $$FavoriteFoodsTableTableManager get favoriteFoods =>
      $$FavoriteFoodsTableTableManager(_db, _db.favoriteFoods);
  $$ChallengeResultsTableTableManager get challengeResults =>
      $$ChallengeResultsTableTableManager(_db, _db.challengeResults);
}

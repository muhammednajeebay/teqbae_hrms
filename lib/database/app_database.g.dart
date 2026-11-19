// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $EmployeeCachesTable extends EmployeeCaches
    with TableInfo<$EmployeeCachesTable, EmployeeCacheRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EmployeeCachesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
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
  static const VerificationMeta _departmentMeta = const VerificationMeta(
    'department',
  );
  @override
  late final GeneratedColumn<String> department = GeneratedColumn<String>(
    'department',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _officeLatitudeMeta = const VerificationMeta(
    'officeLatitude',
  );
  @override
  late final GeneratedColumn<double> officeLatitude = GeneratedColumn<double>(
    'office_latitude',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _officeLongitudeMeta = const VerificationMeta(
    'officeLongitude',
  );
  @override
  late final GeneratedColumn<double> officeLongitude = GeneratedColumn<double>(
    'office_longitude',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _officeRadiusMetersMeta =
      const VerificationMeta('officeRadiusMeters');
  @override
  late final GeneratedColumn<double> officeRadiusMeters =
      GeneratedColumn<double>(
        'office_radius_meters',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _companyTimeZoneMeta = const VerificationMeta(
    'companyTimeZone',
  );
  @override
  late final GeneratedColumn<String> companyTimeZone = GeneratedColumn<String>(
    'company_time_zone',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    department,
    officeLatitude,
    officeLongitude,
    officeRadiusMeters,
    companyTimeZone,
    cachedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'employee_caches';
  @override
  VerificationContext validateIntegrity(
    Insertable<EmployeeCacheRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('department')) {
      context.handle(
        _departmentMeta,
        department.isAcceptableOrUnknown(data['department']!, _departmentMeta),
      );
    } else if (isInserting) {
      context.missing(_departmentMeta);
    }
    if (data.containsKey('office_latitude')) {
      context.handle(
        _officeLatitudeMeta,
        officeLatitude.isAcceptableOrUnknown(
          data['office_latitude']!,
          _officeLatitudeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_officeLatitudeMeta);
    }
    if (data.containsKey('office_longitude')) {
      context.handle(
        _officeLongitudeMeta,
        officeLongitude.isAcceptableOrUnknown(
          data['office_longitude']!,
          _officeLongitudeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_officeLongitudeMeta);
    }
    if (data.containsKey('office_radius_meters')) {
      context.handle(
        _officeRadiusMetersMeta,
        officeRadiusMeters.isAcceptableOrUnknown(
          data['office_radius_meters']!,
          _officeRadiusMetersMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_officeRadiusMetersMeta);
    }
    if (data.containsKey('company_time_zone')) {
      context.handle(
        _companyTimeZoneMeta,
        companyTimeZone.isAcceptableOrUnknown(
          data['company_time_zone']!,
          _companyTimeZoneMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_companyTimeZoneMeta);
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EmployeeCacheRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EmployeeCacheRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      department: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}department'],
      )!,
      officeLatitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}office_latitude'],
      )!,
      officeLongitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}office_longitude'],
      )!,
      officeRadiusMeters: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}office_radius_meters'],
      )!,
      companyTimeZone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}company_time_zone'],
      )!,
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $EmployeeCachesTable createAlias(String alias) {
    return $EmployeeCachesTable(attachedDatabase, alias);
  }
}

class EmployeeCacheRow extends DataClass
    implements Insertable<EmployeeCacheRow> {
  final String id;
  final String name;
  final String department;
  final double officeLatitude;
  final double officeLongitude;
  final double officeRadiusMeters;
  final String companyTimeZone;
  final DateTime cachedAt;
  const EmployeeCacheRow({
    required this.id,
    required this.name,
    required this.department,
    required this.officeLatitude,
    required this.officeLongitude,
    required this.officeRadiusMeters,
    required this.companyTimeZone,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['department'] = Variable<String>(department);
    map['office_latitude'] = Variable<double>(officeLatitude);
    map['office_longitude'] = Variable<double>(officeLongitude);
    map['office_radius_meters'] = Variable<double>(officeRadiusMeters);
    map['company_time_zone'] = Variable<String>(companyTimeZone);
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  EmployeeCachesCompanion toCompanion(bool nullToAbsent) {
    return EmployeeCachesCompanion(
      id: Value(id),
      name: Value(name),
      department: Value(department),
      officeLatitude: Value(officeLatitude),
      officeLongitude: Value(officeLongitude),
      officeRadiusMeters: Value(officeRadiusMeters),
      companyTimeZone: Value(companyTimeZone),
      cachedAt: Value(cachedAt),
    );
  }

  factory EmployeeCacheRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EmployeeCacheRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      department: serializer.fromJson<String>(json['department']),
      officeLatitude: serializer.fromJson<double>(json['officeLatitude']),
      officeLongitude: serializer.fromJson<double>(json['officeLongitude']),
      officeRadiusMeters: serializer.fromJson<double>(
        json['officeRadiusMeters'],
      ),
      companyTimeZone: serializer.fromJson<String>(json['companyTimeZone']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'department': serializer.toJson<String>(department),
      'officeLatitude': serializer.toJson<double>(officeLatitude),
      'officeLongitude': serializer.toJson<double>(officeLongitude),
      'officeRadiusMeters': serializer.toJson<double>(officeRadiusMeters),
      'companyTimeZone': serializer.toJson<String>(companyTimeZone),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  EmployeeCacheRow copyWith({
    String? id,
    String? name,
    String? department,
    double? officeLatitude,
    double? officeLongitude,
    double? officeRadiusMeters,
    String? companyTimeZone,
    DateTime? cachedAt,
  }) => EmployeeCacheRow(
    id: id ?? this.id,
    name: name ?? this.name,
    department: department ?? this.department,
    officeLatitude: officeLatitude ?? this.officeLatitude,
    officeLongitude: officeLongitude ?? this.officeLongitude,
    officeRadiusMeters: officeRadiusMeters ?? this.officeRadiusMeters,
    companyTimeZone: companyTimeZone ?? this.companyTimeZone,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  EmployeeCacheRow copyWithCompanion(EmployeeCachesCompanion data) {
    return EmployeeCacheRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      department: data.department.present
          ? data.department.value
          : this.department,
      officeLatitude: data.officeLatitude.present
          ? data.officeLatitude.value
          : this.officeLatitude,
      officeLongitude: data.officeLongitude.present
          ? data.officeLongitude.value
          : this.officeLongitude,
      officeRadiusMeters: data.officeRadiusMeters.present
          ? data.officeRadiusMeters.value
          : this.officeRadiusMeters,
      companyTimeZone: data.companyTimeZone.present
          ? data.companyTimeZone.value
          : this.companyTimeZone,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EmployeeCacheRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('department: $department, ')
          ..write('officeLatitude: $officeLatitude, ')
          ..write('officeLongitude: $officeLongitude, ')
          ..write('officeRadiusMeters: $officeRadiusMeters, ')
          ..write('companyTimeZone: $companyTimeZone, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    department,
    officeLatitude,
    officeLongitude,
    officeRadiusMeters,
    companyTimeZone,
    cachedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EmployeeCacheRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.department == this.department &&
          other.officeLatitude == this.officeLatitude &&
          other.officeLongitude == this.officeLongitude &&
          other.officeRadiusMeters == this.officeRadiusMeters &&
          other.companyTimeZone == this.companyTimeZone &&
          other.cachedAt == this.cachedAt);
}

class EmployeeCachesCompanion extends UpdateCompanion<EmployeeCacheRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> department;
  final Value<double> officeLatitude;
  final Value<double> officeLongitude;
  final Value<double> officeRadiusMeters;
  final Value<String> companyTimeZone;
  final Value<DateTime> cachedAt;
  final Value<int> rowid;
  const EmployeeCachesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.department = const Value.absent(),
    this.officeLatitude = const Value.absent(),
    this.officeLongitude = const Value.absent(),
    this.officeRadiusMeters = const Value.absent(),
    this.companyTimeZone = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EmployeeCachesCompanion.insert({
    required String id,
    required String name,
    required String department,
    required double officeLatitude,
    required double officeLongitude,
    required double officeRadiusMeters,
    required String companyTimeZone,
    required DateTime cachedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       department = Value(department),
       officeLatitude = Value(officeLatitude),
       officeLongitude = Value(officeLongitude),
       officeRadiusMeters = Value(officeRadiusMeters),
       companyTimeZone = Value(companyTimeZone),
       cachedAt = Value(cachedAt);
  static Insertable<EmployeeCacheRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? department,
    Expression<double>? officeLatitude,
    Expression<double>? officeLongitude,
    Expression<double>? officeRadiusMeters,
    Expression<String>? companyTimeZone,
    Expression<DateTime>? cachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (department != null) 'department': department,
      if (officeLatitude != null) 'office_latitude': officeLatitude,
      if (officeLongitude != null) 'office_longitude': officeLongitude,
      if (officeRadiusMeters != null)
        'office_radius_meters': officeRadiusMeters,
      if (companyTimeZone != null) 'company_time_zone': companyTimeZone,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EmployeeCachesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? department,
    Value<double>? officeLatitude,
    Value<double>? officeLongitude,
    Value<double>? officeRadiusMeters,
    Value<String>? companyTimeZone,
    Value<DateTime>? cachedAt,
    Value<int>? rowid,
  }) {
    return EmployeeCachesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      department: department ?? this.department,
      officeLatitude: officeLatitude ?? this.officeLatitude,
      officeLongitude: officeLongitude ?? this.officeLongitude,
      officeRadiusMeters: officeRadiusMeters ?? this.officeRadiusMeters,
      companyTimeZone: companyTimeZone ?? this.companyTimeZone,
      cachedAt: cachedAt ?? this.cachedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (department.present) {
      map['department'] = Variable<String>(department.value);
    }
    if (officeLatitude.present) {
      map['office_latitude'] = Variable<double>(officeLatitude.value);
    }
    if (officeLongitude.present) {
      map['office_longitude'] = Variable<double>(officeLongitude.value);
    }
    if (officeRadiusMeters.present) {
      map['office_radius_meters'] = Variable<double>(officeRadiusMeters.value);
    }
    if (companyTimeZone.present) {
      map['company_time_zone'] = Variable<String>(companyTimeZone.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EmployeeCachesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('department: $department, ')
          ..write('officeLatitude: $officeLatitude, ')
          ..write('officeLongitude: $officeLongitude, ')
          ..write('officeRadiusMeters: $officeRadiusMeters, ')
          ..write('companyTimeZone: $companyTimeZone, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AttendanceRecordsTable extends AttendanceRecords
    with TableInfo<$AttendanceRecordsTable, AttendanceRecordRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AttendanceRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _companyDateMeta = const VerificationMeta(
    'companyDate',
  );
  @override
  late final GeneratedColumn<String> companyDate = GeneratedColumn<String>(
    'company_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _checkInAtMeta = const VerificationMeta(
    'checkInAt',
  );
  @override
  late final GeneratedColumn<DateTime> checkInAt = GeneratedColumn<DateTime>(
    'check_in_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _checkOutAtMeta = const VerificationMeta(
    'checkOutAt',
  );
  @override
  late final GeneratedColumn<DateTime> checkOutAt = GeneratedColumn<DateTime>(
    'check_out_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [companyDate, checkInAt, checkOutAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'attendance_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<AttendanceRecordRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('company_date')) {
      context.handle(
        _companyDateMeta,
        companyDate.isAcceptableOrUnknown(
          data['company_date']!,
          _companyDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_companyDateMeta);
    }
    if (data.containsKey('check_in_at')) {
      context.handle(
        _checkInAtMeta,
        checkInAt.isAcceptableOrUnknown(data['check_in_at']!, _checkInAtMeta),
      );
    }
    if (data.containsKey('check_out_at')) {
      context.handle(
        _checkOutAtMeta,
        checkOutAt.isAcceptableOrUnknown(
          data['check_out_at']!,
          _checkOutAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {companyDate};
  @override
  AttendanceRecordRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AttendanceRecordRow(
      companyDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}company_date'],
      )!,
      checkInAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}check_in_at'],
      ),
      checkOutAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}check_out_at'],
      ),
    );
  }

  @override
  $AttendanceRecordsTable createAlias(String alias) {
    return $AttendanceRecordsTable(attachedDatabase, alias);
  }
}

class AttendanceRecordRow extends DataClass
    implements Insertable<AttendanceRecordRow> {
  final String companyDate;
  final DateTime? checkInAt;
  final DateTime? checkOutAt;
  const AttendanceRecordRow({
    required this.companyDate,
    this.checkInAt,
    this.checkOutAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['company_date'] = Variable<String>(companyDate);
    if (!nullToAbsent || checkInAt != null) {
      map['check_in_at'] = Variable<DateTime>(checkInAt);
    }
    if (!nullToAbsent || checkOutAt != null) {
      map['check_out_at'] = Variable<DateTime>(checkOutAt);
    }
    return map;
  }

  AttendanceRecordsCompanion toCompanion(bool nullToAbsent) {
    return AttendanceRecordsCompanion(
      companyDate: Value(companyDate),
      checkInAt: checkInAt == null && nullToAbsent
          ? const Value.absent()
          : Value(checkInAt),
      checkOutAt: checkOutAt == null && nullToAbsent
          ? const Value.absent()
          : Value(checkOutAt),
    );
  }

  factory AttendanceRecordRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AttendanceRecordRow(
      companyDate: serializer.fromJson<String>(json['companyDate']),
      checkInAt: serializer.fromJson<DateTime?>(json['checkInAt']),
      checkOutAt: serializer.fromJson<DateTime?>(json['checkOutAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'companyDate': serializer.toJson<String>(companyDate),
      'checkInAt': serializer.toJson<DateTime?>(checkInAt),
      'checkOutAt': serializer.toJson<DateTime?>(checkOutAt),
    };
  }

  AttendanceRecordRow copyWith({
    String? companyDate,
    Value<DateTime?> checkInAt = const Value.absent(),
    Value<DateTime?> checkOutAt = const Value.absent(),
  }) => AttendanceRecordRow(
    companyDate: companyDate ?? this.companyDate,
    checkInAt: checkInAt.present ? checkInAt.value : this.checkInAt,
    checkOutAt: checkOutAt.present ? checkOutAt.value : this.checkOutAt,
  );
  AttendanceRecordRow copyWithCompanion(AttendanceRecordsCompanion data) {
    return AttendanceRecordRow(
      companyDate: data.companyDate.present
          ? data.companyDate.value
          : this.companyDate,
      checkInAt: data.checkInAt.present ? data.checkInAt.value : this.checkInAt,
      checkOutAt: data.checkOutAt.present
          ? data.checkOutAt.value
          : this.checkOutAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AttendanceRecordRow(')
          ..write('companyDate: $companyDate, ')
          ..write('checkInAt: $checkInAt, ')
          ..write('checkOutAt: $checkOutAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(companyDate, checkInAt, checkOutAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AttendanceRecordRow &&
          other.companyDate == this.companyDate &&
          other.checkInAt == this.checkInAt &&
          other.checkOutAt == this.checkOutAt);
}

class AttendanceRecordsCompanion extends UpdateCompanion<AttendanceRecordRow> {
  final Value<String> companyDate;
  final Value<DateTime?> checkInAt;
  final Value<DateTime?> checkOutAt;
  final Value<int> rowid;
  const AttendanceRecordsCompanion({
    this.companyDate = const Value.absent(),
    this.checkInAt = const Value.absent(),
    this.checkOutAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AttendanceRecordsCompanion.insert({
    required String companyDate,
    this.checkInAt = const Value.absent(),
    this.checkOutAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : companyDate = Value(companyDate);
  static Insertable<AttendanceRecordRow> custom({
    Expression<String>? companyDate,
    Expression<DateTime>? checkInAt,
    Expression<DateTime>? checkOutAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (companyDate != null) 'company_date': companyDate,
      if (checkInAt != null) 'check_in_at': checkInAt,
      if (checkOutAt != null) 'check_out_at': checkOutAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AttendanceRecordsCompanion copyWith({
    Value<String>? companyDate,
    Value<DateTime?>? checkInAt,
    Value<DateTime?>? checkOutAt,
    Value<int>? rowid,
  }) {
    return AttendanceRecordsCompanion(
      companyDate: companyDate ?? this.companyDate,
      checkInAt: checkInAt ?? this.checkInAt,
      checkOutAt: checkOutAt ?? this.checkOutAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (companyDate.present) {
      map['company_date'] = Variable<String>(companyDate.value);
    }
    if (checkInAt.present) {
      map['check_in_at'] = Variable<DateTime>(checkInAt.value);
    }
    if (checkOutAt.present) {
      map['check_out_at'] = Variable<DateTime>(checkOutAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AttendanceRecordsCompanion(')
          ..write('companyDate: $companyDate, ')
          ..write('checkInAt: $checkInAt, ')
          ..write('checkOutAt: $checkOutAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AttendanceEventsTable extends AttendanceEvents
    with TableInfo<$AttendanceEventsTable, AttendanceEventRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AttendanceEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _sequenceMeta = const VerificationMeta(
    'sequence',
  );
  @override
  late final GeneratedColumn<int> sequence = GeneratedColumn<int>(
    'sequence',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _clientEventIdMeta = const VerificationMeta(
    'clientEventId',
  );
  @override
  late final GeneratedColumn<String> clientEventId = GeneratedColumn<String>(
    'client_event_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _occurredAtMeta = const VerificationMeta(
    'occurredAt',
  );
  @override
  late final GeneratedColumn<DateTime> occurredAt = GeneratedColumn<DateTime>(
    'occurred_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _companyDateMeta = const VerificationMeta(
    'companyDate',
  );
  @override
  late final GeneratedColumn<String> companyDate = GeneratedColumn<String>(
    'company_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _latitudeMeta = const VerificationMeta(
    'latitude',
  );
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
    'latitude',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _longitudeMeta = const VerificationMeta(
    'longitude',
  );
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
    'longitude',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accuracyMeta = const VerificationMeta(
    'accuracy',
  );
  @override
  late final GeneratedColumn<double> accuracy = GeneratedColumn<double>(
    'accuracy',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isMockedLocationMeta = const VerificationMeta(
    'isMockedLocation',
  );
  @override
  late final GeneratedColumn<bool> isMockedLocation = GeneratedColumn<bool>(
    'is_mocked_location',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_mocked_location" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _attemptsMeta = const VerificationMeta(
    'attempts',
  );
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
    'attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
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
    sequence,
    clientEventId,
    type,
    occurredAt,
    companyDate,
    latitude,
    longitude,
    accuracy,
    isMockedLocation,
    status,
    attempts,
    lastError,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'attendance_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<AttendanceEventRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('sequence')) {
      context.handle(
        _sequenceMeta,
        sequence.isAcceptableOrUnknown(data['sequence']!, _sequenceMeta),
      );
    }
    if (data.containsKey('client_event_id')) {
      context.handle(
        _clientEventIdMeta,
        clientEventId.isAcceptableOrUnknown(
          data['client_event_id']!,
          _clientEventIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_clientEventIdMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('occurred_at')) {
      context.handle(
        _occurredAtMeta,
        occurredAt.isAcceptableOrUnknown(data['occurred_at']!, _occurredAtMeta),
      );
    } else if (isInserting) {
      context.missing(_occurredAtMeta);
    }
    if (data.containsKey('company_date')) {
      context.handle(
        _companyDateMeta,
        companyDate.isAcceptableOrUnknown(
          data['company_date']!,
          _companyDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_companyDateMeta);
    }
    if (data.containsKey('latitude')) {
      context.handle(
        _latitudeMeta,
        latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta),
      );
    } else if (isInserting) {
      context.missing(_latitudeMeta);
    }
    if (data.containsKey('longitude')) {
      context.handle(
        _longitudeMeta,
        longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta),
      );
    } else if (isInserting) {
      context.missing(_longitudeMeta);
    }
    if (data.containsKey('accuracy')) {
      context.handle(
        _accuracyMeta,
        accuracy.isAcceptableOrUnknown(data['accuracy']!, _accuracyMeta),
      );
    }
    if (data.containsKey('is_mocked_location')) {
      context.handle(
        _isMockedLocationMeta,
        isMockedLocation.isAcceptableOrUnknown(
          data['is_mocked_location']!,
          _isMockedLocationMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
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
  Set<GeneratedColumn> get $primaryKey => {sequence};
  @override
  AttendanceEventRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AttendanceEventRow(
      sequence: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sequence'],
      )!,
      clientEventId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_event_id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      occurredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}occurred_at'],
      )!,
      companyDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}company_date'],
      )!,
      latitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}latitude'],
      )!,
      longitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}longitude'],
      )!,
      accuracy: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}accuracy'],
      ),
      isMockedLocation: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_mocked_location'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
      )!,
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $AttendanceEventsTable createAlias(String alias) {
    return $AttendanceEventsTable(attachedDatabase, alias);
  }
}

class AttendanceEventRow extends DataClass
    implements Insertable<AttendanceEventRow> {
  final int sequence;
  final String clientEventId;
  final String type;
  final DateTime occurredAt;
  final String companyDate;
  final double latitude;
  final double longitude;
  final double? accuracy;
  final bool isMockedLocation;
  final String status;
  final int attempts;
  final String? lastError;
  final DateTime createdAt;
  const AttendanceEventRow({
    required this.sequence,
    required this.clientEventId,
    required this.type,
    required this.occurredAt,
    required this.companyDate,
    required this.latitude,
    required this.longitude,
    this.accuracy,
    required this.isMockedLocation,
    required this.status,
    required this.attempts,
    this.lastError,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['sequence'] = Variable<int>(sequence);
    map['client_event_id'] = Variable<String>(clientEventId);
    map['type'] = Variable<String>(type);
    map['occurred_at'] = Variable<DateTime>(occurredAt);
    map['company_date'] = Variable<String>(companyDate);
    map['latitude'] = Variable<double>(latitude);
    map['longitude'] = Variable<double>(longitude);
    if (!nullToAbsent || accuracy != null) {
      map['accuracy'] = Variable<double>(accuracy);
    }
    map['is_mocked_location'] = Variable<bool>(isMockedLocation);
    map['status'] = Variable<String>(status);
    map['attempts'] = Variable<int>(attempts);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  AttendanceEventsCompanion toCompanion(bool nullToAbsent) {
    return AttendanceEventsCompanion(
      sequence: Value(sequence),
      clientEventId: Value(clientEventId),
      type: Value(type),
      occurredAt: Value(occurredAt),
      companyDate: Value(companyDate),
      latitude: Value(latitude),
      longitude: Value(longitude),
      accuracy: accuracy == null && nullToAbsent
          ? const Value.absent()
          : Value(accuracy),
      isMockedLocation: Value(isMockedLocation),
      status: Value(status),
      attempts: Value(attempts),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      createdAt: Value(createdAt),
    );
  }

  factory AttendanceEventRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AttendanceEventRow(
      sequence: serializer.fromJson<int>(json['sequence']),
      clientEventId: serializer.fromJson<String>(json['clientEventId']),
      type: serializer.fromJson<String>(json['type']),
      occurredAt: serializer.fromJson<DateTime>(json['occurredAt']),
      companyDate: serializer.fromJson<String>(json['companyDate']),
      latitude: serializer.fromJson<double>(json['latitude']),
      longitude: serializer.fromJson<double>(json['longitude']),
      accuracy: serializer.fromJson<double?>(json['accuracy']),
      isMockedLocation: serializer.fromJson<bool>(json['isMockedLocation']),
      status: serializer.fromJson<String>(json['status']),
      attempts: serializer.fromJson<int>(json['attempts']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'sequence': serializer.toJson<int>(sequence),
      'clientEventId': serializer.toJson<String>(clientEventId),
      'type': serializer.toJson<String>(type),
      'occurredAt': serializer.toJson<DateTime>(occurredAt),
      'companyDate': serializer.toJson<String>(companyDate),
      'latitude': serializer.toJson<double>(latitude),
      'longitude': serializer.toJson<double>(longitude),
      'accuracy': serializer.toJson<double?>(accuracy),
      'isMockedLocation': serializer.toJson<bool>(isMockedLocation),
      'status': serializer.toJson<String>(status),
      'attempts': serializer.toJson<int>(attempts),
      'lastError': serializer.toJson<String?>(lastError),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  AttendanceEventRow copyWith({
    int? sequence,
    String? clientEventId,
    String? type,
    DateTime? occurredAt,
    String? companyDate,
    double? latitude,
    double? longitude,
    Value<double?> accuracy = const Value.absent(),
    bool? isMockedLocation,
    String? status,
    int? attempts,
    Value<String?> lastError = const Value.absent(),
    DateTime? createdAt,
  }) => AttendanceEventRow(
    sequence: sequence ?? this.sequence,
    clientEventId: clientEventId ?? this.clientEventId,
    type: type ?? this.type,
    occurredAt: occurredAt ?? this.occurredAt,
    companyDate: companyDate ?? this.companyDate,
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
    accuracy: accuracy.present ? accuracy.value : this.accuracy,
    isMockedLocation: isMockedLocation ?? this.isMockedLocation,
    status: status ?? this.status,
    attempts: attempts ?? this.attempts,
    lastError: lastError.present ? lastError.value : this.lastError,
    createdAt: createdAt ?? this.createdAt,
  );
  AttendanceEventRow copyWithCompanion(AttendanceEventsCompanion data) {
    return AttendanceEventRow(
      sequence: data.sequence.present ? data.sequence.value : this.sequence,
      clientEventId: data.clientEventId.present
          ? data.clientEventId.value
          : this.clientEventId,
      type: data.type.present ? data.type.value : this.type,
      occurredAt: data.occurredAt.present
          ? data.occurredAt.value
          : this.occurredAt,
      companyDate: data.companyDate.present
          ? data.companyDate.value
          : this.companyDate,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      accuracy: data.accuracy.present ? data.accuracy.value : this.accuracy,
      isMockedLocation: data.isMockedLocation.present
          ? data.isMockedLocation.value
          : this.isMockedLocation,
      status: data.status.present ? data.status.value : this.status,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AttendanceEventRow(')
          ..write('sequence: $sequence, ')
          ..write('clientEventId: $clientEventId, ')
          ..write('type: $type, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('companyDate: $companyDate, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('accuracy: $accuracy, ')
          ..write('isMockedLocation: $isMockedLocation, ')
          ..write('status: $status, ')
          ..write('attempts: $attempts, ')
          ..write('lastError: $lastError, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    sequence,
    clientEventId,
    type,
    occurredAt,
    companyDate,
    latitude,
    longitude,
    accuracy,
    isMockedLocation,
    status,
    attempts,
    lastError,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AttendanceEventRow &&
          other.sequence == this.sequence &&
          other.clientEventId == this.clientEventId &&
          other.type == this.type &&
          other.occurredAt == this.occurredAt &&
          other.companyDate == this.companyDate &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.accuracy == this.accuracy &&
          other.isMockedLocation == this.isMockedLocation &&
          other.status == this.status &&
          other.attempts == this.attempts &&
          other.lastError == this.lastError &&
          other.createdAt == this.createdAt);
}

class AttendanceEventsCompanion extends UpdateCompanion<AttendanceEventRow> {
  final Value<int> sequence;
  final Value<String> clientEventId;
  final Value<String> type;
  final Value<DateTime> occurredAt;
  final Value<String> companyDate;
  final Value<double> latitude;
  final Value<double> longitude;
  final Value<double?> accuracy;
  final Value<bool> isMockedLocation;
  final Value<String> status;
  final Value<int> attempts;
  final Value<String?> lastError;
  final Value<DateTime> createdAt;
  const AttendanceEventsCompanion({
    this.sequence = const Value.absent(),
    this.clientEventId = const Value.absent(),
    this.type = const Value.absent(),
    this.occurredAt = const Value.absent(),
    this.companyDate = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.accuracy = const Value.absent(),
    this.isMockedLocation = const Value.absent(),
    this.status = const Value.absent(),
    this.attempts = const Value.absent(),
    this.lastError = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  AttendanceEventsCompanion.insert({
    this.sequence = const Value.absent(),
    required String clientEventId,
    required String type,
    required DateTime occurredAt,
    required String companyDate,
    required double latitude,
    required double longitude,
    this.accuracy = const Value.absent(),
    this.isMockedLocation = const Value.absent(),
    required String status,
    this.attempts = const Value.absent(),
    this.lastError = const Value.absent(),
    required DateTime createdAt,
  }) : clientEventId = Value(clientEventId),
       type = Value(type),
       occurredAt = Value(occurredAt),
       companyDate = Value(companyDate),
       latitude = Value(latitude),
       longitude = Value(longitude),
       status = Value(status),
       createdAt = Value(createdAt);
  static Insertable<AttendanceEventRow> custom({
    Expression<int>? sequence,
    Expression<String>? clientEventId,
    Expression<String>? type,
    Expression<DateTime>? occurredAt,
    Expression<String>? companyDate,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<double>? accuracy,
    Expression<bool>? isMockedLocation,
    Expression<String>? status,
    Expression<int>? attempts,
    Expression<String>? lastError,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (sequence != null) 'sequence': sequence,
      if (clientEventId != null) 'client_event_id': clientEventId,
      if (type != null) 'type': type,
      if (occurredAt != null) 'occurred_at': occurredAt,
      if (companyDate != null) 'company_date': companyDate,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (accuracy != null) 'accuracy': accuracy,
      if (isMockedLocation != null) 'is_mocked_location': isMockedLocation,
      if (status != null) 'status': status,
      if (attempts != null) 'attempts': attempts,
      if (lastError != null) 'last_error': lastError,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  AttendanceEventsCompanion copyWith({
    Value<int>? sequence,
    Value<String>? clientEventId,
    Value<String>? type,
    Value<DateTime>? occurredAt,
    Value<String>? companyDate,
    Value<double>? latitude,
    Value<double>? longitude,
    Value<double?>? accuracy,
    Value<bool>? isMockedLocation,
    Value<String>? status,
    Value<int>? attempts,
    Value<String?>? lastError,
    Value<DateTime>? createdAt,
  }) {
    return AttendanceEventsCompanion(
      sequence: sequence ?? this.sequence,
      clientEventId: clientEventId ?? this.clientEventId,
      type: type ?? this.type,
      occurredAt: occurredAt ?? this.occurredAt,
      companyDate: companyDate ?? this.companyDate,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      accuracy: accuracy ?? this.accuracy,
      isMockedLocation: isMockedLocation ?? this.isMockedLocation,
      status: status ?? this.status,
      attempts: attempts ?? this.attempts,
      lastError: lastError ?? this.lastError,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (sequence.present) {
      map['sequence'] = Variable<int>(sequence.value);
    }
    if (clientEventId.present) {
      map['client_event_id'] = Variable<String>(clientEventId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (occurredAt.present) {
      map['occurred_at'] = Variable<DateTime>(occurredAt.value);
    }
    if (companyDate.present) {
      map['company_date'] = Variable<String>(companyDate.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    if (accuracy.present) {
      map['accuracy'] = Variable<double>(accuracy.value);
    }
    if (isMockedLocation.present) {
      map['is_mocked_location'] = Variable<bool>(isMockedLocation.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AttendanceEventsCompanion(')
          ..write('sequence: $sequence, ')
          ..write('clientEventId: $clientEventId, ')
          ..write('type: $type, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('companyDate: $companyDate, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('accuracy: $accuracy, ')
          ..write('isMockedLocation: $isMockedLocation, ')
          ..write('status: $status, ')
          ..write('attempts: $attempts, ')
          ..write('lastError: $lastError, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $LeaveRequestRowsTable extends LeaveRequestRows
    with TableInfo<$LeaveRequestRowsTable, LeaveRequestRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LeaveRequestRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startDateMeta = const VerificationMeta(
    'startDate',
  );
  @override
  late final GeneratedColumn<DateTime> startDate = GeneratedColumn<DateTime>(
    'start_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endDateMeta = const VerificationMeta(
    'endDate',
  );
  @override
  late final GeneratedColumn<DateTime> endDate = GeneratedColumn<DateTime>(
    'end_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
    'reason',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    type,
    startDate,
    endDate,
    reason,
    status,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'leave_request_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<LeaveRequestRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('start_date')) {
      context.handle(
        _startDateMeta,
        startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta),
      );
    } else if (isInserting) {
      context.missing(_startDateMeta);
    }
    if (data.containsKey('end_date')) {
      context.handle(
        _endDateMeta,
        endDate.isAcceptableOrUnknown(data['end_date']!, _endDateMeta),
      );
    } else if (isInserting) {
      context.missing(_endDateMeta);
    }
    if (data.containsKey('reason')) {
      context.handle(
        _reasonMeta,
        reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta),
      );
    } else if (isInserting) {
      context.missing(_reasonMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LeaveRequestRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LeaveRequestRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      startDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}start_date'],
      )!,
      endDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}end_date'],
      )!,
      reason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reason'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
    );
  }

  @override
  $LeaveRequestRowsTable createAlias(String alias) {
    return $LeaveRequestRowsTable(attachedDatabase, alias);
  }
}

class LeaveRequestRow extends DataClass implements Insertable<LeaveRequestRow> {
  final String id;
  final String type;
  final DateTime startDate;
  final DateTime endDate;
  final String reason;
  final String status;
  const LeaveRequestRow({
    required this.id,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.reason,
    required this.status,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['type'] = Variable<String>(type);
    map['start_date'] = Variable<DateTime>(startDate);
    map['end_date'] = Variable<DateTime>(endDate);
    map['reason'] = Variable<String>(reason);
    map['status'] = Variable<String>(status);
    return map;
  }

  LeaveRequestRowsCompanion toCompanion(bool nullToAbsent) {
    return LeaveRequestRowsCompanion(
      id: Value(id),
      type: Value(type),
      startDate: Value(startDate),
      endDate: Value(endDate),
      reason: Value(reason),
      status: Value(status),
    );
  }

  factory LeaveRequestRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LeaveRequestRow(
      id: serializer.fromJson<String>(json['id']),
      type: serializer.fromJson<String>(json['type']),
      startDate: serializer.fromJson<DateTime>(json['startDate']),
      endDate: serializer.fromJson<DateTime>(json['endDate']),
      reason: serializer.fromJson<String>(json['reason']),
      status: serializer.fromJson<String>(json['status']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'type': serializer.toJson<String>(type),
      'startDate': serializer.toJson<DateTime>(startDate),
      'endDate': serializer.toJson<DateTime>(endDate),
      'reason': serializer.toJson<String>(reason),
      'status': serializer.toJson<String>(status),
    };
  }

  LeaveRequestRow copyWith({
    String? id,
    String? type,
    DateTime? startDate,
    DateTime? endDate,
    String? reason,
    String? status,
  }) => LeaveRequestRow(
    id: id ?? this.id,
    type: type ?? this.type,
    startDate: startDate ?? this.startDate,
    endDate: endDate ?? this.endDate,
    reason: reason ?? this.reason,
    status: status ?? this.status,
  );
  LeaveRequestRow copyWithCompanion(LeaveRequestRowsCompanion data) {
    return LeaveRequestRow(
      id: data.id.present ? data.id.value : this.id,
      type: data.type.present ? data.type.value : this.type,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      endDate: data.endDate.present ? data.endDate.value : this.endDate,
      reason: data.reason.present ? data.reason.value : this.reason,
      status: data.status.present ? data.status.value : this.status,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LeaveRequestRow(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('reason: $reason, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, type, startDate, endDate, reason, status);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LeaveRequestRow &&
          other.id == this.id &&
          other.type == this.type &&
          other.startDate == this.startDate &&
          other.endDate == this.endDate &&
          other.reason == this.reason &&
          other.status == this.status);
}

class LeaveRequestRowsCompanion extends UpdateCompanion<LeaveRequestRow> {
  final Value<String> id;
  final Value<String> type;
  final Value<DateTime> startDate;
  final Value<DateTime> endDate;
  final Value<String> reason;
  final Value<String> status;
  final Value<int> rowid;
  const LeaveRequestRowsCompanion({
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.reason = const Value.absent(),
    this.status = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LeaveRequestRowsCompanion.insert({
    required String id,
    required String type,
    required DateTime startDate,
    required DateTime endDate,
    required String reason,
    required String status,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       type = Value(type),
       startDate = Value(startDate),
       endDate = Value(endDate),
       reason = Value(reason),
       status = Value(status);
  static Insertable<LeaveRequestRow> custom({
    Expression<String>? id,
    Expression<String>? type,
    Expression<DateTime>? startDate,
    Expression<DateTime>? endDate,
    Expression<String>? reason,
    Expression<String>? status,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      if (reason != null) 'reason': reason,
      if (status != null) 'status': status,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LeaveRequestRowsCompanion copyWith({
    Value<String>? id,
    Value<String>? type,
    Value<DateTime>? startDate,
    Value<DateTime>? endDate,
    Value<String>? reason,
    Value<String>? status,
    Value<int>? rowid,
  }) {
    return LeaveRequestRowsCompanion(
      id: id ?? this.id,
      type: type ?? this.type,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      reason: reason ?? this.reason,
      status: status ?? this.status,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<DateTime>(startDate.value);
    }
    if (endDate.present) {
      map['end_date'] = Variable<DateTime>(endDate.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LeaveRequestRowsCompanion(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('reason: $reason, ')
          ..write('status: $status, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LeaveBalanceRowsTable extends LeaveBalanceRows
    with TableInfo<$LeaveBalanceRowsTable, LeaveBalanceRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LeaveBalanceRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _singletonIdMeta = const VerificationMeta(
    'singletonId',
  );
  @override
  late final GeneratedColumn<int> singletonId = GeneratedColumn<int>(
    'singleton_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _availableDaysMeta = const VerificationMeta(
    'availableDays',
  );
  @override
  late final GeneratedColumn<int> availableDays = GeneratedColumn<int>(
    'available_days',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [singletonId, availableDays, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'leave_balance_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<LeaveBalanceRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('singleton_id')) {
      context.handle(
        _singletonIdMeta,
        singletonId.isAcceptableOrUnknown(
          data['singleton_id']!,
          _singletonIdMeta,
        ),
      );
    }
    if (data.containsKey('available_days')) {
      context.handle(
        _availableDaysMeta,
        availableDays.isAcceptableOrUnknown(
          data['available_days']!,
          _availableDaysMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_availableDaysMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {singletonId};
  @override
  LeaveBalanceRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LeaveBalanceRow(
      singletonId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}singleton_id'],
      )!,
      availableDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}available_days'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $LeaveBalanceRowsTable createAlias(String alias) {
    return $LeaveBalanceRowsTable(attachedDatabase, alias);
  }
}

class LeaveBalanceRow extends DataClass implements Insertable<LeaveBalanceRow> {
  final int singletonId;
  final int availableDays;
  final DateTime updatedAt;
  const LeaveBalanceRow({
    required this.singletonId,
    required this.availableDays,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['singleton_id'] = Variable<int>(singletonId);
    map['available_days'] = Variable<int>(availableDays);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  LeaveBalanceRowsCompanion toCompanion(bool nullToAbsent) {
    return LeaveBalanceRowsCompanion(
      singletonId: Value(singletonId),
      availableDays: Value(availableDays),
      updatedAt: Value(updatedAt),
    );
  }

  factory LeaveBalanceRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LeaveBalanceRow(
      singletonId: serializer.fromJson<int>(json['singletonId']),
      availableDays: serializer.fromJson<int>(json['availableDays']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'singletonId': serializer.toJson<int>(singletonId),
      'availableDays': serializer.toJson<int>(availableDays),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  LeaveBalanceRow copyWith({
    int? singletonId,
    int? availableDays,
    DateTime? updatedAt,
  }) => LeaveBalanceRow(
    singletonId: singletonId ?? this.singletonId,
    availableDays: availableDays ?? this.availableDays,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  LeaveBalanceRow copyWithCompanion(LeaveBalanceRowsCompanion data) {
    return LeaveBalanceRow(
      singletonId: data.singletonId.present
          ? data.singletonId.value
          : this.singletonId,
      availableDays: data.availableDays.present
          ? data.availableDays.value
          : this.availableDays,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LeaveBalanceRow(')
          ..write('singletonId: $singletonId, ')
          ..write('availableDays: $availableDays, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(singletonId, availableDays, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LeaveBalanceRow &&
          other.singletonId == this.singletonId &&
          other.availableDays == this.availableDays &&
          other.updatedAt == this.updatedAt);
}

class LeaveBalanceRowsCompanion extends UpdateCompanion<LeaveBalanceRow> {
  final Value<int> singletonId;
  final Value<int> availableDays;
  final Value<DateTime> updatedAt;
  const LeaveBalanceRowsCompanion({
    this.singletonId = const Value.absent(),
    this.availableDays = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  LeaveBalanceRowsCompanion.insert({
    this.singletonId = const Value.absent(),
    required int availableDays,
    required DateTime updatedAt,
  }) : availableDays = Value(availableDays),
       updatedAt = Value(updatedAt);
  static Insertable<LeaveBalanceRow> custom({
    Expression<int>? singletonId,
    Expression<int>? availableDays,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (singletonId != null) 'singleton_id': singletonId,
      if (availableDays != null) 'available_days': availableDays,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  LeaveBalanceRowsCompanion copyWith({
    Value<int>? singletonId,
    Value<int>? availableDays,
    Value<DateTime>? updatedAt,
  }) {
    return LeaveBalanceRowsCompanion(
      singletonId: singletonId ?? this.singletonId,
      availableDays: availableDays ?? this.availableDays,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (singletonId.present) {
      map['singleton_id'] = Variable<int>(singletonId.value);
    }
    if (availableDays.present) {
      map['available_days'] = Variable<int>(availableDays.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LeaveBalanceRowsCompanion(')
          ..write('singletonId: $singletonId, ')
          ..write('availableDays: $availableDays, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $EmployeeCachesTable employeeCaches = $EmployeeCachesTable(this);
  late final $AttendanceRecordsTable attendanceRecords =
      $AttendanceRecordsTable(this);
  late final $AttendanceEventsTable attendanceEvents = $AttendanceEventsTable(
    this,
  );
  late final $LeaveRequestRowsTable leaveRequestRows = $LeaveRequestRowsTable(
    this,
  );
  late final $LeaveBalanceRowsTable leaveBalanceRows = $LeaveBalanceRowsTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    employeeCaches,
    attendanceRecords,
    attendanceEvents,
    leaveRequestRows,
    leaveBalanceRows,
  ];
}

typedef $$EmployeeCachesTableCreateCompanionBuilder =
    EmployeeCachesCompanion Function({
      required String id,
      required String name,
      required String department,
      required double officeLatitude,
      required double officeLongitude,
      required double officeRadiusMeters,
      required String companyTimeZone,
      required DateTime cachedAt,
      Value<int> rowid,
    });
typedef $$EmployeeCachesTableUpdateCompanionBuilder =
    EmployeeCachesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> department,
      Value<double> officeLatitude,
      Value<double> officeLongitude,
      Value<double> officeRadiusMeters,
      Value<String> companyTimeZone,
      Value<DateTime> cachedAt,
      Value<int> rowid,
    });

class $$EmployeeCachesTableFilterComposer
    extends Composer<_$AppDatabase, $EmployeeCachesTable> {
  $$EmployeeCachesTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get department => $composableBuilder(
    column: $table.department,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get officeLatitude => $composableBuilder(
    column: $table.officeLatitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get officeLongitude => $composableBuilder(
    column: $table.officeLongitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get officeRadiusMeters => $composableBuilder(
    column: $table.officeRadiusMeters,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get companyTimeZone => $composableBuilder(
    column: $table.companyTimeZone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$EmployeeCachesTableOrderingComposer
    extends Composer<_$AppDatabase, $EmployeeCachesTable> {
  $$EmployeeCachesTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get department => $composableBuilder(
    column: $table.department,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get officeLatitude => $composableBuilder(
    column: $table.officeLatitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get officeLongitude => $composableBuilder(
    column: $table.officeLongitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get officeRadiusMeters => $composableBuilder(
    column: $table.officeRadiusMeters,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get companyTimeZone => $composableBuilder(
    column: $table.companyTimeZone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EmployeeCachesTableAnnotationComposer
    extends Composer<_$AppDatabase, $EmployeeCachesTable> {
  $$EmployeeCachesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get department => $composableBuilder(
    column: $table.department,
    builder: (column) => column,
  );

  GeneratedColumn<double> get officeLatitude => $composableBuilder(
    column: $table.officeLatitude,
    builder: (column) => column,
  );

  GeneratedColumn<double> get officeLongitude => $composableBuilder(
    column: $table.officeLongitude,
    builder: (column) => column,
  );

  GeneratedColumn<double> get officeRadiusMeters => $composableBuilder(
    column: $table.officeRadiusMeters,
    builder: (column) => column,
  );

  GeneratedColumn<String> get companyTimeZone => $composableBuilder(
    column: $table.companyTimeZone,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$EmployeeCachesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EmployeeCachesTable,
          EmployeeCacheRow,
          $$EmployeeCachesTableFilterComposer,
          $$EmployeeCachesTableOrderingComposer,
          $$EmployeeCachesTableAnnotationComposer,
          $$EmployeeCachesTableCreateCompanionBuilder,
          $$EmployeeCachesTableUpdateCompanionBuilder,
          (
            EmployeeCacheRow,
            BaseReferences<
              _$AppDatabase,
              $EmployeeCachesTable,
              EmployeeCacheRow
            >,
          ),
          EmployeeCacheRow,
          PrefetchHooks Function()
        > {
  $$EmployeeCachesTableTableManager(
    _$AppDatabase db,
    $EmployeeCachesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EmployeeCachesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EmployeeCachesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EmployeeCachesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> department = const Value.absent(),
                Value<double> officeLatitude = const Value.absent(),
                Value<double> officeLongitude = const Value.absent(),
                Value<double> officeRadiusMeters = const Value.absent(),
                Value<String> companyTimeZone = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EmployeeCachesCompanion(
                id: id,
                name: name,
                department: department,
                officeLatitude: officeLatitude,
                officeLongitude: officeLongitude,
                officeRadiusMeters: officeRadiusMeters,
                companyTimeZone: companyTimeZone,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String department,
                required double officeLatitude,
                required double officeLongitude,
                required double officeRadiusMeters,
                required String companyTimeZone,
                required DateTime cachedAt,
                Value<int> rowid = const Value.absent(),
              }) => EmployeeCachesCompanion.insert(
                id: id,
                name: name,
                department: department,
                officeLatitude: officeLatitude,
                officeLongitude: officeLongitude,
                officeRadiusMeters: officeRadiusMeters,
                companyTimeZone: companyTimeZone,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EmployeeCachesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EmployeeCachesTable,
      EmployeeCacheRow,
      $$EmployeeCachesTableFilterComposer,
      $$EmployeeCachesTableOrderingComposer,
      $$EmployeeCachesTableAnnotationComposer,
      $$EmployeeCachesTableCreateCompanionBuilder,
      $$EmployeeCachesTableUpdateCompanionBuilder,
      (
        EmployeeCacheRow,
        BaseReferences<_$AppDatabase, $EmployeeCachesTable, EmployeeCacheRow>,
      ),
      EmployeeCacheRow,
      PrefetchHooks Function()
    >;
typedef $$AttendanceRecordsTableCreateCompanionBuilder =
    AttendanceRecordsCompanion Function({
      required String companyDate,
      Value<DateTime?> checkInAt,
      Value<DateTime?> checkOutAt,
      Value<int> rowid,
    });
typedef $$AttendanceRecordsTableUpdateCompanionBuilder =
    AttendanceRecordsCompanion Function({
      Value<String> companyDate,
      Value<DateTime?> checkInAt,
      Value<DateTime?> checkOutAt,
      Value<int> rowid,
    });

class $$AttendanceRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $AttendanceRecordsTable> {
  $$AttendanceRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get companyDate => $composableBuilder(
    column: $table.companyDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get checkInAt => $composableBuilder(
    column: $table.checkInAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get checkOutAt => $composableBuilder(
    column: $table.checkOutAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AttendanceRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $AttendanceRecordsTable> {
  $$AttendanceRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get companyDate => $composableBuilder(
    column: $table.companyDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get checkInAt => $composableBuilder(
    column: $table.checkInAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get checkOutAt => $composableBuilder(
    column: $table.checkOutAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AttendanceRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AttendanceRecordsTable> {
  $$AttendanceRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get companyDate => $composableBuilder(
    column: $table.companyDate,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get checkInAt =>
      $composableBuilder(column: $table.checkInAt, builder: (column) => column);

  GeneratedColumn<DateTime> get checkOutAt => $composableBuilder(
    column: $table.checkOutAt,
    builder: (column) => column,
  );
}

class $$AttendanceRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AttendanceRecordsTable,
          AttendanceRecordRow,
          $$AttendanceRecordsTableFilterComposer,
          $$AttendanceRecordsTableOrderingComposer,
          $$AttendanceRecordsTableAnnotationComposer,
          $$AttendanceRecordsTableCreateCompanionBuilder,
          $$AttendanceRecordsTableUpdateCompanionBuilder,
          (
            AttendanceRecordRow,
            BaseReferences<
              _$AppDatabase,
              $AttendanceRecordsTable,
              AttendanceRecordRow
            >,
          ),
          AttendanceRecordRow,
          PrefetchHooks Function()
        > {
  $$AttendanceRecordsTableTableManager(
    _$AppDatabase db,
    $AttendanceRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AttendanceRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AttendanceRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AttendanceRecordsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> companyDate = const Value.absent(),
                Value<DateTime?> checkInAt = const Value.absent(),
                Value<DateTime?> checkOutAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AttendanceRecordsCompanion(
                companyDate: companyDate,
                checkInAt: checkInAt,
                checkOutAt: checkOutAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String companyDate,
                Value<DateTime?> checkInAt = const Value.absent(),
                Value<DateTime?> checkOutAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AttendanceRecordsCompanion.insert(
                companyDate: companyDate,
                checkInAt: checkInAt,
                checkOutAt: checkOutAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AttendanceRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AttendanceRecordsTable,
      AttendanceRecordRow,
      $$AttendanceRecordsTableFilterComposer,
      $$AttendanceRecordsTableOrderingComposer,
      $$AttendanceRecordsTableAnnotationComposer,
      $$AttendanceRecordsTableCreateCompanionBuilder,
      $$AttendanceRecordsTableUpdateCompanionBuilder,
      (
        AttendanceRecordRow,
        BaseReferences<
          _$AppDatabase,
          $AttendanceRecordsTable,
          AttendanceRecordRow
        >,
      ),
      AttendanceRecordRow,
      PrefetchHooks Function()
    >;
typedef $$AttendanceEventsTableCreateCompanionBuilder =
    AttendanceEventsCompanion Function({
      Value<int> sequence,
      required String clientEventId,
      required String type,
      required DateTime occurredAt,
      required String companyDate,
      required double latitude,
      required double longitude,
      Value<double?> accuracy,
      Value<bool> isMockedLocation,
      required String status,
      Value<int> attempts,
      Value<String?> lastError,
      required DateTime createdAt,
    });
typedef $$AttendanceEventsTableUpdateCompanionBuilder =
    AttendanceEventsCompanion Function({
      Value<int> sequence,
      Value<String> clientEventId,
      Value<String> type,
      Value<DateTime> occurredAt,
      Value<String> companyDate,
      Value<double> latitude,
      Value<double> longitude,
      Value<double?> accuracy,
      Value<bool> isMockedLocation,
      Value<String> status,
      Value<int> attempts,
      Value<String?> lastError,
      Value<DateTime> createdAt,
    });

class $$AttendanceEventsTableFilterComposer
    extends Composer<_$AppDatabase, $AttendanceEventsTable> {
  $$AttendanceEventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get sequence => $composableBuilder(
    column: $table.sequence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clientEventId => $composableBuilder(
    column: $table.clientEventId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get companyDate => $composableBuilder(
    column: $table.companyDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get accuracy => $composableBuilder(
    column: $table.accuracy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isMockedLocation => $composableBuilder(
    column: $table.isMockedLocation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AttendanceEventsTableOrderingComposer
    extends Composer<_$AppDatabase, $AttendanceEventsTable> {
  $$AttendanceEventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get sequence => $composableBuilder(
    column: $table.sequence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clientEventId => $composableBuilder(
    column: $table.clientEventId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get companyDate => $composableBuilder(
    column: $table.companyDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get accuracy => $composableBuilder(
    column: $table.accuracy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isMockedLocation => $composableBuilder(
    column: $table.isMockedLocation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AttendanceEventsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AttendanceEventsTable> {
  $$AttendanceEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get sequence =>
      $composableBuilder(column: $table.sequence, builder: (column) => column);

  GeneratedColumn<String> get clientEventId => $composableBuilder(
    column: $table.clientEventId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get companyDate => $composableBuilder(
    column: $table.companyDate,
    builder: (column) => column,
  );

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);

  GeneratedColumn<double> get accuracy =>
      $composableBuilder(column: $table.accuracy, builder: (column) => column);

  GeneratedColumn<bool> get isMockedLocation => $composableBuilder(
    column: $table.isMockedLocation,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$AttendanceEventsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AttendanceEventsTable,
          AttendanceEventRow,
          $$AttendanceEventsTableFilterComposer,
          $$AttendanceEventsTableOrderingComposer,
          $$AttendanceEventsTableAnnotationComposer,
          $$AttendanceEventsTableCreateCompanionBuilder,
          $$AttendanceEventsTableUpdateCompanionBuilder,
          (
            AttendanceEventRow,
            BaseReferences<
              _$AppDatabase,
              $AttendanceEventsTable,
              AttendanceEventRow
            >,
          ),
          AttendanceEventRow,
          PrefetchHooks Function()
        > {
  $$AttendanceEventsTableTableManager(
    _$AppDatabase db,
    $AttendanceEventsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AttendanceEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AttendanceEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AttendanceEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> sequence = const Value.absent(),
                Value<String> clientEventId = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<DateTime> occurredAt = const Value.absent(),
                Value<String> companyDate = const Value.absent(),
                Value<double> latitude = const Value.absent(),
                Value<double> longitude = const Value.absent(),
                Value<double?> accuracy = const Value.absent(),
                Value<bool> isMockedLocation = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => AttendanceEventsCompanion(
                sequence: sequence,
                clientEventId: clientEventId,
                type: type,
                occurredAt: occurredAt,
                companyDate: companyDate,
                latitude: latitude,
                longitude: longitude,
                accuracy: accuracy,
                isMockedLocation: isMockedLocation,
                status: status,
                attempts: attempts,
                lastError: lastError,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> sequence = const Value.absent(),
                required String clientEventId,
                required String type,
                required DateTime occurredAt,
                required String companyDate,
                required double latitude,
                required double longitude,
                Value<double?> accuracy = const Value.absent(),
                Value<bool> isMockedLocation = const Value.absent(),
                required String status,
                Value<int> attempts = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                required DateTime createdAt,
              }) => AttendanceEventsCompanion.insert(
                sequence: sequence,
                clientEventId: clientEventId,
                type: type,
                occurredAt: occurredAt,
                companyDate: companyDate,
                latitude: latitude,
                longitude: longitude,
                accuracy: accuracy,
                isMockedLocation: isMockedLocation,
                status: status,
                attempts: attempts,
                lastError: lastError,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AttendanceEventsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AttendanceEventsTable,
      AttendanceEventRow,
      $$AttendanceEventsTableFilterComposer,
      $$AttendanceEventsTableOrderingComposer,
      $$AttendanceEventsTableAnnotationComposer,
      $$AttendanceEventsTableCreateCompanionBuilder,
      $$AttendanceEventsTableUpdateCompanionBuilder,
      (
        AttendanceEventRow,
        BaseReferences<
          _$AppDatabase,
          $AttendanceEventsTable,
          AttendanceEventRow
        >,
      ),
      AttendanceEventRow,
      PrefetchHooks Function()
    >;
typedef $$LeaveRequestRowsTableCreateCompanionBuilder =
    LeaveRequestRowsCompanion Function({
      required String id,
      required String type,
      required DateTime startDate,
      required DateTime endDate,
      required String reason,
      required String status,
      Value<int> rowid,
    });
typedef $$LeaveRequestRowsTableUpdateCompanionBuilder =
    LeaveRequestRowsCompanion Function({
      Value<String> id,
      Value<String> type,
      Value<DateTime> startDate,
      Value<DateTime> endDate,
      Value<String> reason,
      Value<String> status,
      Value<int> rowid,
    });

class $$LeaveRequestRowsTableFilterComposer
    extends Composer<_$AppDatabase, $LeaveRequestRowsTable> {
  $$LeaveRequestRowsTableFilterComposer({
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

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LeaveRequestRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $LeaveRequestRowsTable> {
  $$LeaveRequestRowsTableOrderingComposer({
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

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LeaveRequestRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LeaveRequestRowsTable> {
  $$LeaveRequestRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<DateTime> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<DateTime> get endDate =>
      $composableBuilder(column: $table.endDate, builder: (column) => column);

  GeneratedColumn<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);
}

class $$LeaveRequestRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LeaveRequestRowsTable,
          LeaveRequestRow,
          $$LeaveRequestRowsTableFilterComposer,
          $$LeaveRequestRowsTableOrderingComposer,
          $$LeaveRequestRowsTableAnnotationComposer,
          $$LeaveRequestRowsTableCreateCompanionBuilder,
          $$LeaveRequestRowsTableUpdateCompanionBuilder,
          (
            LeaveRequestRow,
            BaseReferences<
              _$AppDatabase,
              $LeaveRequestRowsTable,
              LeaveRequestRow
            >,
          ),
          LeaveRequestRow,
          PrefetchHooks Function()
        > {
  $$LeaveRequestRowsTableTableManager(
    _$AppDatabase db,
    $LeaveRequestRowsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LeaveRequestRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LeaveRequestRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LeaveRequestRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<DateTime> startDate = const Value.absent(),
                Value<DateTime> endDate = const Value.absent(),
                Value<String> reason = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LeaveRequestRowsCompanion(
                id: id,
                type: type,
                startDate: startDate,
                endDate: endDate,
                reason: reason,
                status: status,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String type,
                required DateTime startDate,
                required DateTime endDate,
                required String reason,
                required String status,
                Value<int> rowid = const Value.absent(),
              }) => LeaveRequestRowsCompanion.insert(
                id: id,
                type: type,
                startDate: startDate,
                endDate: endDate,
                reason: reason,
                status: status,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LeaveRequestRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LeaveRequestRowsTable,
      LeaveRequestRow,
      $$LeaveRequestRowsTableFilterComposer,
      $$LeaveRequestRowsTableOrderingComposer,
      $$LeaveRequestRowsTableAnnotationComposer,
      $$LeaveRequestRowsTableCreateCompanionBuilder,
      $$LeaveRequestRowsTableUpdateCompanionBuilder,
      (
        LeaveRequestRow,
        BaseReferences<_$AppDatabase, $LeaveRequestRowsTable, LeaveRequestRow>,
      ),
      LeaveRequestRow,
      PrefetchHooks Function()
    >;
typedef $$LeaveBalanceRowsTableCreateCompanionBuilder =
    LeaveBalanceRowsCompanion Function({
      Value<int> singletonId,
      required int availableDays,
      required DateTime updatedAt,
    });
typedef $$LeaveBalanceRowsTableUpdateCompanionBuilder =
    LeaveBalanceRowsCompanion Function({
      Value<int> singletonId,
      Value<int> availableDays,
      Value<DateTime> updatedAt,
    });

class $$LeaveBalanceRowsTableFilterComposer
    extends Composer<_$AppDatabase, $LeaveBalanceRowsTable> {
  $$LeaveBalanceRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get singletonId => $composableBuilder(
    column: $table.singletonId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get availableDays => $composableBuilder(
    column: $table.availableDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LeaveBalanceRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $LeaveBalanceRowsTable> {
  $$LeaveBalanceRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get singletonId => $composableBuilder(
    column: $table.singletonId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get availableDays => $composableBuilder(
    column: $table.availableDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LeaveBalanceRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LeaveBalanceRowsTable> {
  $$LeaveBalanceRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get singletonId => $composableBuilder(
    column: $table.singletonId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get availableDays => $composableBuilder(
    column: $table.availableDays,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LeaveBalanceRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LeaveBalanceRowsTable,
          LeaveBalanceRow,
          $$LeaveBalanceRowsTableFilterComposer,
          $$LeaveBalanceRowsTableOrderingComposer,
          $$LeaveBalanceRowsTableAnnotationComposer,
          $$LeaveBalanceRowsTableCreateCompanionBuilder,
          $$LeaveBalanceRowsTableUpdateCompanionBuilder,
          (
            LeaveBalanceRow,
            BaseReferences<
              _$AppDatabase,
              $LeaveBalanceRowsTable,
              LeaveBalanceRow
            >,
          ),
          LeaveBalanceRow,
          PrefetchHooks Function()
        > {
  $$LeaveBalanceRowsTableTableManager(
    _$AppDatabase db,
    $LeaveBalanceRowsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LeaveBalanceRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LeaveBalanceRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LeaveBalanceRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> singletonId = const Value.absent(),
                Value<int> availableDays = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => LeaveBalanceRowsCompanion(
                singletonId: singletonId,
                availableDays: availableDays,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> singletonId = const Value.absent(),
                required int availableDays,
                required DateTime updatedAt,
              }) => LeaveBalanceRowsCompanion.insert(
                singletonId: singletonId,
                availableDays: availableDays,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LeaveBalanceRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LeaveBalanceRowsTable,
      LeaveBalanceRow,
      $$LeaveBalanceRowsTableFilterComposer,
      $$LeaveBalanceRowsTableOrderingComposer,
      $$LeaveBalanceRowsTableAnnotationComposer,
      $$LeaveBalanceRowsTableCreateCompanionBuilder,
      $$LeaveBalanceRowsTableUpdateCompanionBuilder,
      (
        LeaveBalanceRow,
        BaseReferences<_$AppDatabase, $LeaveBalanceRowsTable, LeaveBalanceRow>,
      ),
      LeaveBalanceRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$EmployeeCachesTableTableManager get employeeCaches =>
      $$EmployeeCachesTableTableManager(_db, _db.employeeCaches);
  $$AttendanceRecordsTableTableManager get attendanceRecords =>
      $$AttendanceRecordsTableTableManager(_db, _db.attendanceRecords);
  $$AttendanceEventsTableTableManager get attendanceEvents =>
      $$AttendanceEventsTableTableManager(_db, _db.attendanceEvents);
  $$LeaveRequestRowsTableTableManager get leaveRequestRows =>
      $$LeaveRequestRowsTableTableManager(_db, _db.leaveRequestRows);
  $$LeaveBalanceRowsTableTableManager get leaveBalanceRows =>
      $$LeaveBalanceRowsTableTableManager(_db, _db.leaveBalanceRows);
}

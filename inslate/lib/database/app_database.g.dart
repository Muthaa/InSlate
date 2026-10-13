// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $AccountsTable extends Accounts with TableInfo<$AccountsTable, Account> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AccountsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
    'uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
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
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _institutionMeta = const VerificationMeta(
    'institution',
  );
  @override
  late final GeneratedColumn<String> institution = GeneratedColumn<String>(
    'institution',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _isUserRegisteredMeta = const VerificationMeta(
    'isUserRegistered',
  );
  @override
  late final GeneratedColumn<bool> isUserRegistered = GeneratedColumn<bool>(
    'is_user_registered',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_user_registered" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _identifiersMeta = const VerificationMeta(
    'identifiers',
  );
  @override
  late final GeneratedColumn<String> identifiers = GeneratedColumn<String>(
    'identifiers',
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    uuid,
    name,
    type,
    institution,
    isActive,
    isUserRegistered,
    identifiers,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'accounts';
  @override
  VerificationContext validateIntegrity(
    Insertable<Account> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('uuid')) {
      context.handle(
        _uuidMeta,
        uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta),
      );
    } else if (isInserting) {
      context.missing(_uuidMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('institution')) {
      context.handle(
        _institutionMeta,
        institution.isAcceptableOrUnknown(
          data['institution']!,
          _institutionMeta,
        ),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('is_user_registered')) {
      context.handle(
        _isUserRegisteredMeta,
        isUserRegistered.isAcceptableOrUnknown(
          data['is_user_registered']!,
          _isUserRegisteredMeta,
        ),
      );
    }
    if (data.containsKey('identifiers')) {
      context.handle(
        _identifiersMeta,
        identifiers.isAcceptableOrUnknown(
          data['identifiers']!,
          _identifiersMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Account map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Account(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      uuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uuid'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      institution: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}institution'],
      ),
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      isUserRegistered: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_user_registered'],
      )!,
      identifiers: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}identifiers'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $AccountsTable createAlias(String alias) {
    return $AccountsTable(attachedDatabase, alias);
  }
}

class Account extends DataClass implements Insertable<Account> {
  final int id;
  final String uuid;
  final String name;
  final String type;
  final String? institution;
  final bool isActive;

  /// Only explicit registration sets this. Legacy/provider rows stay unconfirmed.
  final bool isUserRegistered;

  /// Optional descriptive identifiers, never credentials or inferred identities.
  final String? identifiers;
  final DateTime createdAt;
  const Account({
    required this.id,
    required this.uuid,
    required this.name,
    required this.type,
    this.institution,
    required this.isActive,
    required this.isUserRegistered,
    this.identifiers,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['uuid'] = Variable<String>(uuid);
    map['name'] = Variable<String>(name);
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || institution != null) {
      map['institution'] = Variable<String>(institution);
    }
    map['is_active'] = Variable<bool>(isActive);
    map['is_user_registered'] = Variable<bool>(isUserRegistered);
    if (!nullToAbsent || identifiers != null) {
      map['identifiers'] = Variable<String>(identifiers);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  AccountsCompanion toCompanion(bool nullToAbsent) {
    return AccountsCompanion(
      id: Value(id),
      uuid: Value(uuid),
      name: Value(name),
      type: Value(type),
      institution: institution == null && nullToAbsent
          ? const Value.absent()
          : Value(institution),
      isActive: Value(isActive),
      isUserRegistered: Value(isUserRegistered),
      identifiers: identifiers == null && nullToAbsent
          ? const Value.absent()
          : Value(identifiers),
      createdAt: Value(createdAt),
    );
  }

  factory Account.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Account(
      id: serializer.fromJson<int>(json['id']),
      uuid: serializer.fromJson<String>(json['uuid']),
      name: serializer.fromJson<String>(json['name']),
      type: serializer.fromJson<String>(json['type']),
      institution: serializer.fromJson<String?>(json['institution']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      isUserRegistered: serializer.fromJson<bool>(json['isUserRegistered']),
      identifiers: serializer.fromJson<String?>(json['identifiers']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'uuid': serializer.toJson<String>(uuid),
      'name': serializer.toJson<String>(name),
      'type': serializer.toJson<String>(type),
      'institution': serializer.toJson<String?>(institution),
      'isActive': serializer.toJson<bool>(isActive),
      'isUserRegistered': serializer.toJson<bool>(isUserRegistered),
      'identifiers': serializer.toJson<String?>(identifiers),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Account copyWith({
    int? id,
    String? uuid,
    String? name,
    String? type,
    Value<String?> institution = const Value.absent(),
    bool? isActive,
    bool? isUserRegistered,
    Value<String?> identifiers = const Value.absent(),
    DateTime? createdAt,
  }) => Account(
    id: id ?? this.id,
    uuid: uuid ?? this.uuid,
    name: name ?? this.name,
    type: type ?? this.type,
    institution: institution.present ? institution.value : this.institution,
    isActive: isActive ?? this.isActive,
    isUserRegistered: isUserRegistered ?? this.isUserRegistered,
    identifiers: identifiers.present ? identifiers.value : this.identifiers,
    createdAt: createdAt ?? this.createdAt,
  );
  Account copyWithCompanion(AccountsCompanion data) {
    return Account(
      id: data.id.present ? data.id.value : this.id,
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
      institution: data.institution.present
          ? data.institution.value
          : this.institution,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      isUserRegistered: data.isUserRegistered.present
          ? data.isUserRegistered.value
          : this.isUserRegistered,
      identifiers: data.identifiers.present
          ? data.identifiers.value
          : this.identifiers,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Account(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('institution: $institution, ')
          ..write('isActive: $isActive, ')
          ..write('isUserRegistered: $isUserRegistered, ')
          ..write('identifiers: $identifiers, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    uuid,
    name,
    type,
    institution,
    isActive,
    isUserRegistered,
    identifiers,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Account &&
          other.id == this.id &&
          other.uuid == this.uuid &&
          other.name == this.name &&
          other.type == this.type &&
          other.institution == this.institution &&
          other.isActive == this.isActive &&
          other.isUserRegistered == this.isUserRegistered &&
          other.identifiers == this.identifiers &&
          other.createdAt == this.createdAt);
}

class AccountsCompanion extends UpdateCompanion<Account> {
  final Value<int> id;
  final Value<String> uuid;
  final Value<String> name;
  final Value<String> type;
  final Value<String?> institution;
  final Value<bool> isActive;
  final Value<bool> isUserRegistered;
  final Value<String?> identifiers;
  final Value<DateTime> createdAt;
  const AccountsCompanion({
    this.id = const Value.absent(),
    this.uuid = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.institution = const Value.absent(),
    this.isActive = const Value.absent(),
    this.isUserRegistered = const Value.absent(),
    this.identifiers = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  AccountsCompanion.insert({
    this.id = const Value.absent(),
    required String uuid,
    required String name,
    required String type,
    this.institution = const Value.absent(),
    this.isActive = const Value.absent(),
    this.isUserRegistered = const Value.absent(),
    this.identifiers = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : uuid = Value(uuid),
       name = Value(name),
       type = Value(type);
  static Insertable<Account> custom({
    Expression<int>? id,
    Expression<String>? uuid,
    Expression<String>? name,
    Expression<String>? type,
    Expression<String>? institution,
    Expression<bool>? isActive,
    Expression<bool>? isUserRegistered,
    Expression<String>? identifiers,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (uuid != null) 'uuid': uuid,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (institution != null) 'institution': institution,
      if (isActive != null) 'is_active': isActive,
      if (isUserRegistered != null) 'is_user_registered': isUserRegistered,
      if (identifiers != null) 'identifiers': identifiers,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  AccountsCompanion copyWith({
    Value<int>? id,
    Value<String>? uuid,
    Value<String>? name,
    Value<String>? type,
    Value<String?>? institution,
    Value<bool>? isActive,
    Value<bool>? isUserRegistered,
    Value<String?>? identifiers,
    Value<DateTime>? createdAt,
  }) {
    return AccountsCompanion(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      name: name ?? this.name,
      type: type ?? this.type,
      institution: institution ?? this.institution,
      isActive: isActive ?? this.isActive,
      isUserRegistered: isUserRegistered ?? this.isUserRegistered,
      identifiers: identifiers ?? this.identifiers,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (institution.present) {
      map['institution'] = Variable<String>(institution.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (isUserRegistered.present) {
      map['is_user_registered'] = Variable<bool>(isUserRegistered.value);
    }
    if (identifiers.present) {
      map['identifiers'] = Variable<String>(identifiers.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AccountsCompanion(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('institution: $institution, ')
          ..write('isActive: $isActive, ')
          ..write('isUserRegistered: $isUserRegistered, ')
          ..write('identifiers: $identifiers, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $TransactionCategoriesTable extends TransactionCategories
    with TableInfo<$TransactionCategoriesTable, StoredCategory> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransactionCategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (length(trim(display_name)) > 0)',
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (kind IN (\'expense\', \'income\'))',
  );
  static const VerificationMeta _isBuiltInMeta = const VerificationMeta(
    'isBuiltIn',
  );
  @override
  late final GeneratedColumn<bool> isBuiltIn = GeneratedColumn<bool>(
    'is_built_in',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_built_in" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isHiddenMeta = const VerificationMeta(
    'isHidden',
  );
  @override
  late final GeneratedColumn<bool> isHidden = GeneratedColumn<bool>(
    'is_hidden',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_hidden" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    displayName,
    kind,
    isBuiltIn,
    isHidden,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transaction_categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<StoredCategory> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('is_built_in')) {
      context.handle(
        _isBuiltInMeta,
        isBuiltIn.isAcceptableOrUnknown(data['is_built_in']!, _isBuiltInMeta),
      );
    }
    if (data.containsKey('is_hidden')) {
      context.handle(
        _isHiddenMeta,
        isHidden.isAcceptableOrUnknown(data['is_hidden']!, _isHiddenMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StoredCategory map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StoredCategory(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      isBuiltIn: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_built_in'],
      )!,
      isHidden: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_hidden'],
      )!,
    );
  }

  @override
  $TransactionCategoriesTable createAlias(String alias) {
    return $TransactionCategoriesTable(attachedDatabase, alias);
  }
}

class StoredCategory extends DataClass implements Insertable<StoredCategory> {
  final String id;
  final String displayName;
  final String kind;
  final bool isBuiltIn;
  final bool isHidden;
  const StoredCategory({
    required this.id,
    required this.displayName,
    required this.kind,
    required this.isBuiltIn,
    required this.isHidden,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['display_name'] = Variable<String>(displayName);
    map['kind'] = Variable<String>(kind);
    map['is_built_in'] = Variable<bool>(isBuiltIn);
    map['is_hidden'] = Variable<bool>(isHidden);
    return map;
  }

  TransactionCategoriesCompanion toCompanion(bool nullToAbsent) {
    return TransactionCategoriesCompanion(
      id: Value(id),
      displayName: Value(displayName),
      kind: Value(kind),
      isBuiltIn: Value(isBuiltIn),
      isHidden: Value(isHidden),
    );
  }

  factory StoredCategory.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StoredCategory(
      id: serializer.fromJson<String>(json['id']),
      displayName: serializer.fromJson<String>(json['displayName']),
      kind: serializer.fromJson<String>(json['kind']),
      isBuiltIn: serializer.fromJson<bool>(json['isBuiltIn']),
      isHidden: serializer.fromJson<bool>(json['isHidden']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'displayName': serializer.toJson<String>(displayName),
      'kind': serializer.toJson<String>(kind),
      'isBuiltIn': serializer.toJson<bool>(isBuiltIn),
      'isHidden': serializer.toJson<bool>(isHidden),
    };
  }

  StoredCategory copyWith({
    String? id,
    String? displayName,
    String? kind,
    bool? isBuiltIn,
    bool? isHidden,
  }) => StoredCategory(
    id: id ?? this.id,
    displayName: displayName ?? this.displayName,
    kind: kind ?? this.kind,
    isBuiltIn: isBuiltIn ?? this.isBuiltIn,
    isHidden: isHidden ?? this.isHidden,
  );
  StoredCategory copyWithCompanion(TransactionCategoriesCompanion data) {
    return StoredCategory(
      id: data.id.present ? data.id.value : this.id,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      kind: data.kind.present ? data.kind.value : this.kind,
      isBuiltIn: data.isBuiltIn.present ? data.isBuiltIn.value : this.isBuiltIn,
      isHidden: data.isHidden.present ? data.isHidden.value : this.isHidden,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StoredCategory(')
          ..write('id: $id, ')
          ..write('displayName: $displayName, ')
          ..write('kind: $kind, ')
          ..write('isBuiltIn: $isBuiltIn, ')
          ..write('isHidden: $isHidden')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, displayName, kind, isBuiltIn, isHidden);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StoredCategory &&
          other.id == this.id &&
          other.displayName == this.displayName &&
          other.kind == this.kind &&
          other.isBuiltIn == this.isBuiltIn &&
          other.isHidden == this.isHidden);
}

class TransactionCategoriesCompanion extends UpdateCompanion<StoredCategory> {
  final Value<String> id;
  final Value<String> displayName;
  final Value<String> kind;
  final Value<bool> isBuiltIn;
  final Value<bool> isHidden;
  final Value<int> rowid;
  const TransactionCategoriesCompanion({
    this.id = const Value.absent(),
    this.displayName = const Value.absent(),
    this.kind = const Value.absent(),
    this.isBuiltIn = const Value.absent(),
    this.isHidden = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TransactionCategoriesCompanion.insert({
    required String id,
    required String displayName,
    required String kind,
    this.isBuiltIn = const Value.absent(),
    this.isHidden = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       displayName = Value(displayName),
       kind = Value(kind);
  static Insertable<StoredCategory> custom({
    Expression<String>? id,
    Expression<String>? displayName,
    Expression<String>? kind,
    Expression<bool>? isBuiltIn,
    Expression<bool>? isHidden,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (displayName != null) 'display_name': displayName,
      if (kind != null) 'kind': kind,
      if (isBuiltIn != null) 'is_built_in': isBuiltIn,
      if (isHidden != null) 'is_hidden': isHidden,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TransactionCategoriesCompanion copyWith({
    Value<String>? id,
    Value<String>? displayName,
    Value<String>? kind,
    Value<bool>? isBuiltIn,
    Value<bool>? isHidden,
    Value<int>? rowid,
  }) {
    return TransactionCategoriesCompanion(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      kind: kind ?? this.kind,
      isBuiltIn: isBuiltIn ?? this.isBuiltIn,
      isHidden: isHidden ?? this.isHidden,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (isBuiltIn.present) {
      map['is_built_in'] = Variable<bool>(isBuiltIn.value);
    }
    if (isHidden.present) {
      map['is_hidden'] = Variable<bool>(isHidden.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransactionCategoriesCompanion(')
          ..write('id: $id, ')
          ..write('displayName: $displayName, ')
          ..write('kind: $kind, ')
          ..write('isBuiltIn: $isBuiltIn, ')
          ..write('isHidden: $isHidden, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BudgetsTable extends Budgets
    with TableInfo<$BudgetsTable, StoredBudget> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BudgetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scopeMeta = const VerificationMeta('scope');
  @override
  late final GeneratedColumn<String> scope = GeneratedColumn<String>(
    'scope',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (scope IN (\'overall\', \'category\'))',
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES transaction_categories (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _amountMinorMeta = const VerificationMeta(
    'amountMinor',
  );
  @override
  late final GeneratedColumn<int> amountMinor = GeneratedColumn<int>(
    'amount_minor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (amount_minor > 0)',
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    scope,
    categoryId,
    amountMinor,
    isActive,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'budgets';
  @override
  VerificationContext validateIntegrity(
    Insertable<StoredBudget> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('scope')) {
      context.handle(
        _scopeMeta,
        scope.isAcceptableOrUnknown(data['scope']!, _scopeMeta),
      );
    } else if (isInserting) {
      context.missing(_scopeMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    }
    if (data.containsKey('amount_minor')) {
      context.handle(
        _amountMinorMeta,
        amountMinor.isAcceptableOrUnknown(
          data['amount_minor']!,
          _amountMinorMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_amountMinorMeta);
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StoredBudget map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StoredBudget(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      scope: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scope'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      ),
      amountMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_minor'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
    );
  }

  @override
  $BudgetsTable createAlias(String alias) {
    return $BudgetsTable(attachedDatabase, alias);
  }
}

class StoredBudget extends DataClass implements Insertable<StoredBudget> {
  final String id;
  final String scope;
  final String? categoryId;
  final int amountMinor;
  final bool isActive;
  const StoredBudget({
    required this.id,
    required this.scope,
    this.categoryId,
    required this.amountMinor,
    required this.isActive,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['scope'] = Variable<String>(scope);
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<String>(categoryId);
    }
    map['amount_minor'] = Variable<int>(amountMinor);
    map['is_active'] = Variable<bool>(isActive);
    return map;
  }

  BudgetsCompanion toCompanion(bool nullToAbsent) {
    return BudgetsCompanion(
      id: Value(id),
      scope: Value(scope),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      amountMinor: Value(amountMinor),
      isActive: Value(isActive),
    );
  }

  factory StoredBudget.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StoredBudget(
      id: serializer.fromJson<String>(json['id']),
      scope: serializer.fromJson<String>(json['scope']),
      categoryId: serializer.fromJson<String?>(json['categoryId']),
      amountMinor: serializer.fromJson<int>(json['amountMinor']),
      isActive: serializer.fromJson<bool>(json['isActive']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'scope': serializer.toJson<String>(scope),
      'categoryId': serializer.toJson<String?>(categoryId),
      'amountMinor': serializer.toJson<int>(amountMinor),
      'isActive': serializer.toJson<bool>(isActive),
    };
  }

  StoredBudget copyWith({
    String? id,
    String? scope,
    Value<String?> categoryId = const Value.absent(),
    int? amountMinor,
    bool? isActive,
  }) => StoredBudget(
    id: id ?? this.id,
    scope: scope ?? this.scope,
    categoryId: categoryId.present ? categoryId.value : this.categoryId,
    amountMinor: amountMinor ?? this.amountMinor,
    isActive: isActive ?? this.isActive,
  );
  StoredBudget copyWithCompanion(BudgetsCompanion data) {
    return StoredBudget(
      id: data.id.present ? data.id.value : this.id,
      scope: data.scope.present ? data.scope.value : this.scope,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      amountMinor: data.amountMinor.present
          ? data.amountMinor.value
          : this.amountMinor,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StoredBudget(')
          ..write('id: $id, ')
          ..write('scope: $scope, ')
          ..write('categoryId: $categoryId, ')
          ..write('amountMinor: $amountMinor, ')
          ..write('isActive: $isActive')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, scope, categoryId, amountMinor, isActive);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StoredBudget &&
          other.id == this.id &&
          other.scope == this.scope &&
          other.categoryId == this.categoryId &&
          other.amountMinor == this.amountMinor &&
          other.isActive == this.isActive);
}

class BudgetsCompanion extends UpdateCompanion<StoredBudget> {
  final Value<String> id;
  final Value<String> scope;
  final Value<String?> categoryId;
  final Value<int> amountMinor;
  final Value<bool> isActive;
  final Value<int> rowid;
  const BudgetsCompanion({
    this.id = const Value.absent(),
    this.scope = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.amountMinor = const Value.absent(),
    this.isActive = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BudgetsCompanion.insert({
    required String id,
    required String scope,
    this.categoryId = const Value.absent(),
    required int amountMinor,
    this.isActive = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       scope = Value(scope),
       amountMinor = Value(amountMinor);
  static Insertable<StoredBudget> custom({
    Expression<String>? id,
    Expression<String>? scope,
    Expression<String>? categoryId,
    Expression<int>? amountMinor,
    Expression<bool>? isActive,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (scope != null) 'scope': scope,
      if (categoryId != null) 'category_id': categoryId,
      if (amountMinor != null) 'amount_minor': amountMinor,
      if (isActive != null) 'is_active': isActive,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BudgetsCompanion copyWith({
    Value<String>? id,
    Value<String>? scope,
    Value<String?>? categoryId,
    Value<int>? amountMinor,
    Value<bool>? isActive,
    Value<int>? rowid,
  }) {
    return BudgetsCompanion(
      id: id ?? this.id,
      scope: scope ?? this.scope,
      categoryId: categoryId ?? this.categoryId,
      amountMinor: amountMinor ?? this.amountMinor,
      isActive: isActive ?? this.isActive,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (scope.present) {
      map['scope'] = Variable<String>(scope.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (amountMinor.present) {
      map['amount_minor'] = Variable<int>(amountMinor.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BudgetsCompanion(')
          ..write('id: $id, ')
          ..write('scope: $scope, ')
          ..write('categoryId: $categoryId, ')
          ..write('amountMinor: $amountMinor, ')
          ..write('isActive: $isActive, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FinancialRecordsTable extends FinancialRecords
    with TableInfo<$FinancialRecordsTable, FinancialRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FinancialRecordsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _reversesRecordIdMeta = const VerificationMeta(
    'reversesRecordId',
  );
  @override
  late final GeneratedColumn<int> reversesRecordId = GeneratedColumn<int>(
    'reverses_record_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES financial_records (id) ON DELETE RESTRICT',
    ),
  );
  static const VerificationMeta _referenceMeta = const VerificationMeta(
    'reference',
  );
  @override
  late final GeneratedColumn<String> reference = GeneratedColumn<String>(
    'reference',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceMessageIdMeta = const VerificationMeta(
    'sourceMessageId',
  );
  @override
  late final GeneratedColumn<String> sourceMessageId = GeneratedColumn<String>(
    'source_message_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _transactionDateMeta = const VerificationMeta(
    'transactionDate',
  );
  @override
  late final GeneratedColumn<DateTime> transactionDate =
      GeneratedColumn<DateTime>(
        'transaction_date',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _receivedAtMeta = const VerificationMeta(
    'receivedAt',
  );
  @override
  late final GeneratedColumn<DateTime> receivedAt = GeneratedColumn<DateTime>(
    'received_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _balanceMeta = const VerificationMeta(
    'balance',
  );
  @override
  late final GeneratedColumn<double> balance = GeneratedColumn<double>(
    'balance',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _transactionCostMeta = const VerificationMeta(
    'transactionCost',
  );
  @override
  late final GeneratedColumn<double> transactionCost = GeneratedColumn<double>(
    'transaction_cost',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
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
  static const VerificationMeta _subtypeMeta = const VerificationMeta(
    'subtype',
  );
  @override
  late final GeneratedColumn<String> subtype = GeneratedColumn<String>(
    'subtype',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _interpretedTypeMeta = const VerificationMeta(
    'interpretedType',
  );
  @override
  late final GeneratedColumn<String> interpretedType = GeneratedColumn<String>(
    'interpreted_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _interpretedSubtypeMeta =
      const VerificationMeta('interpretedSubtype');
  @override
  late final GeneratedColumn<String> interpretedSubtype =
      GeneratedColumn<String>(
        'interpreted_subtype',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _interpretationMappingIdMeta =
      const VerificationMeta('interpretationMappingId');
  @override
  late final GeneratedColumn<int> interpretationMappingId =
      GeneratedColumn<int>(
        'interpretation_mapping_id',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
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
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rawMessageMeta = const VerificationMeta(
    'rawMessage',
  );
  @override
  late final GeneratedColumn<String> rawMessage = GeneratedColumn<String>(
    'raw_message',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceAccountIdMeta = const VerificationMeta(
    'sourceAccountId',
  );
  @override
  late final GeneratedColumn<int> sourceAccountId = GeneratedColumn<int>(
    'source_account_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _destinationAccountIdMeta =
      const VerificationMeta('destinationAccountId');
  @override
  late final GeneratedColumn<int> destinationAccountId = GeneratedColumn<int>(
    'destination_account_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _partyNameMeta = const VerificationMeta(
    'partyName',
  );
  @override
  late final GeneratedColumn<String> partyName = GeneratedColumn<String>(
    'party_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _partyTypeMeta = const VerificationMeta(
    'partyType',
  );
  @override
  late final GeneratedColumn<String> partyType = GeneratedColumn<String>(
    'party_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _partyPhoneMeta = const VerificationMeta(
    'partyPhone',
  );
  @override
  late final GeneratedColumn<String> partyPhone = GeneratedColumn<String>(
    'party_phone',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _partyAccountMeta = const VerificationMeta(
    'partyAccount',
  );
  @override
  late final GeneratedColumn<String> partyAccount = GeneratedColumn<String>(
    'party_account',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _partyIdentifierMeta = const VerificationMeta(
    'partyIdentifier',
  );
  @override
  late final GeneratedColumn<String> partyIdentifier = GeneratedColumn<String>(
    'party_identifier',
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    reversesRecordId,
    reference,
    sourceMessageId,
    transactionDate,
    receivedAt,
    amount,
    balance,
    transactionCost,
    type,
    subtype,
    interpretedType,
    interpretedSubtype,
    interpretationMappingId,
    status,
    title,
    rawMessage,
    sourceAccountId,
    destinationAccountId,
    partyName,
    partyType,
    partyPhone,
    partyAccount,
    partyIdentifier,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'financial_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<FinancialRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('reverses_record_id')) {
      context.handle(
        _reversesRecordIdMeta,
        reversesRecordId.isAcceptableOrUnknown(
          data['reverses_record_id']!,
          _reversesRecordIdMeta,
        ),
      );
    }
    if (data.containsKey('reference')) {
      context.handle(
        _referenceMeta,
        reference.isAcceptableOrUnknown(data['reference']!, _referenceMeta),
      );
    } else if (isInserting) {
      context.missing(_referenceMeta);
    }
    if (data.containsKey('source_message_id')) {
      context.handle(
        _sourceMessageIdMeta,
        sourceMessageId.isAcceptableOrUnknown(
          data['source_message_id']!,
          _sourceMessageIdMeta,
        ),
      );
    }
    if (data.containsKey('transaction_date')) {
      context.handle(
        _transactionDateMeta,
        transactionDate.isAcceptableOrUnknown(
          data['transaction_date']!,
          _transactionDateMeta,
        ),
      );
    }
    if (data.containsKey('received_at')) {
      context.handle(
        _receivedAtMeta,
        receivedAt.isAcceptableOrUnknown(data['received_at']!, _receivedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_receivedAtMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('balance')) {
      context.handle(
        _balanceMeta,
        balance.isAcceptableOrUnknown(data['balance']!, _balanceMeta),
      );
    }
    if (data.containsKey('transaction_cost')) {
      context.handle(
        _transactionCostMeta,
        transactionCost.isAcceptableOrUnknown(
          data['transaction_cost']!,
          _transactionCostMeta,
        ),
      );
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('subtype')) {
      context.handle(
        _subtypeMeta,
        subtype.isAcceptableOrUnknown(data['subtype']!, _subtypeMeta),
      );
    } else if (isInserting) {
      context.missing(_subtypeMeta);
    }
    if (data.containsKey('interpreted_type')) {
      context.handle(
        _interpretedTypeMeta,
        interpretedType.isAcceptableOrUnknown(
          data['interpreted_type']!,
          _interpretedTypeMeta,
        ),
      );
    }
    if (data.containsKey('interpreted_subtype')) {
      context.handle(
        _interpretedSubtypeMeta,
        interpretedSubtype.isAcceptableOrUnknown(
          data['interpreted_subtype']!,
          _interpretedSubtypeMeta,
        ),
      );
    }
    if (data.containsKey('interpretation_mapping_id')) {
      context.handle(
        _interpretationMappingIdMeta,
        interpretationMappingId.isAcceptableOrUnknown(
          data['interpretation_mapping_id']!,
          _interpretationMappingIdMeta,
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
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('raw_message')) {
      context.handle(
        _rawMessageMeta,
        rawMessage.isAcceptableOrUnknown(data['raw_message']!, _rawMessageMeta),
      );
    } else if (isInserting) {
      context.missing(_rawMessageMeta);
    }
    if (data.containsKey('source_account_id')) {
      context.handle(
        _sourceAccountIdMeta,
        sourceAccountId.isAcceptableOrUnknown(
          data['source_account_id']!,
          _sourceAccountIdMeta,
        ),
      );
    }
    if (data.containsKey('destination_account_id')) {
      context.handle(
        _destinationAccountIdMeta,
        destinationAccountId.isAcceptableOrUnknown(
          data['destination_account_id']!,
          _destinationAccountIdMeta,
        ),
      );
    }
    if (data.containsKey('party_name')) {
      context.handle(
        _partyNameMeta,
        partyName.isAcceptableOrUnknown(data['party_name']!, _partyNameMeta),
      );
    }
    if (data.containsKey('party_type')) {
      context.handle(
        _partyTypeMeta,
        partyType.isAcceptableOrUnknown(data['party_type']!, _partyTypeMeta),
      );
    }
    if (data.containsKey('party_phone')) {
      context.handle(
        _partyPhoneMeta,
        partyPhone.isAcceptableOrUnknown(data['party_phone']!, _partyPhoneMeta),
      );
    }
    if (data.containsKey('party_account')) {
      context.handle(
        _partyAccountMeta,
        partyAccount.isAcceptableOrUnknown(
          data['party_account']!,
          _partyAccountMeta,
        ),
      );
    }
    if (data.containsKey('party_identifier')) {
      context.handle(
        _partyIdentifierMeta,
        partyIdentifier.isAcceptableOrUnknown(
          data['party_identifier']!,
          _partyIdentifierMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FinancialRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FinancialRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      reversesRecordId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reverses_record_id'],
      ),
      reference: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reference'],
      )!,
      sourceMessageId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_message_id'],
      ),
      transactionDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}transaction_date'],
      ),
      receivedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}received_at'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}amount'],
      )!,
      balance: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}balance'],
      ),
      transactionCost: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}transaction_cost'],
      ),
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      subtype: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subtype'],
      )!,
      interpretedType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}interpreted_type'],
      ),
      interpretedSubtype: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}interpreted_subtype'],
      ),
      interpretationMappingId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}interpretation_mapping_id'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      rawMessage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}raw_message'],
      )!,
      sourceAccountId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}source_account_id'],
      ),
      destinationAccountId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}destination_account_id'],
      ),
      partyName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}party_name'],
      ),
      partyType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}party_type'],
      ),
      partyPhone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}party_phone'],
      ),
      partyAccount: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}party_account'],
      ),
      partyIdentifier: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}party_identifier'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $FinancialRecordsTable createAlias(String alias) {
    return $FinancialRecordsTable(attachedDatabase, alias);
  }
}

class FinancialRecord extends DataClass implements Insertable<FinancialRecord> {
  final int id;
  final int? reversesRecordId;
  final String reference;
  final String? sourceMessageId;
  final DateTime? transactionDate;
  final DateTime receivedAt;
  final double amount;
  final double? balance;
  final double? transactionCost;
  final String type;
  final String subtype;

  /// User-confirmed interpretation; parsed type/subtype remain unchanged.
  final String? interpretedType;
  final String? interpretedSubtype;
  final int? interpretationMappingId;
  final String status;
  final String title;
  final String rawMessage;
  final int? sourceAccountId;
  final int? destinationAccountId;
  final String? partyName;
  final String? partyType;
  final String? partyPhone;
  final String? partyAccount;
  final String? partyIdentifier;
  final DateTime createdAt;
  const FinancialRecord({
    required this.id,
    this.reversesRecordId,
    required this.reference,
    this.sourceMessageId,
    this.transactionDate,
    required this.receivedAt,
    required this.amount,
    this.balance,
    this.transactionCost,
    required this.type,
    required this.subtype,
    this.interpretedType,
    this.interpretedSubtype,
    this.interpretationMappingId,
    required this.status,
    required this.title,
    required this.rawMessage,
    this.sourceAccountId,
    this.destinationAccountId,
    this.partyName,
    this.partyType,
    this.partyPhone,
    this.partyAccount,
    this.partyIdentifier,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || reversesRecordId != null) {
      map['reverses_record_id'] = Variable<int>(reversesRecordId);
    }
    map['reference'] = Variable<String>(reference);
    if (!nullToAbsent || sourceMessageId != null) {
      map['source_message_id'] = Variable<String>(sourceMessageId);
    }
    if (!nullToAbsent || transactionDate != null) {
      map['transaction_date'] = Variable<DateTime>(transactionDate);
    }
    map['received_at'] = Variable<DateTime>(receivedAt);
    map['amount'] = Variable<double>(amount);
    if (!nullToAbsent || balance != null) {
      map['balance'] = Variable<double>(balance);
    }
    if (!nullToAbsent || transactionCost != null) {
      map['transaction_cost'] = Variable<double>(transactionCost);
    }
    map['type'] = Variable<String>(type);
    map['subtype'] = Variable<String>(subtype);
    if (!nullToAbsent || interpretedType != null) {
      map['interpreted_type'] = Variable<String>(interpretedType);
    }
    if (!nullToAbsent || interpretedSubtype != null) {
      map['interpreted_subtype'] = Variable<String>(interpretedSubtype);
    }
    if (!nullToAbsent || interpretationMappingId != null) {
      map['interpretation_mapping_id'] = Variable<int>(interpretationMappingId);
    }
    map['status'] = Variable<String>(status);
    map['title'] = Variable<String>(title);
    map['raw_message'] = Variable<String>(rawMessage);
    if (!nullToAbsent || sourceAccountId != null) {
      map['source_account_id'] = Variable<int>(sourceAccountId);
    }
    if (!nullToAbsent || destinationAccountId != null) {
      map['destination_account_id'] = Variable<int>(destinationAccountId);
    }
    if (!nullToAbsent || partyName != null) {
      map['party_name'] = Variable<String>(partyName);
    }
    if (!nullToAbsent || partyType != null) {
      map['party_type'] = Variable<String>(partyType);
    }
    if (!nullToAbsent || partyPhone != null) {
      map['party_phone'] = Variable<String>(partyPhone);
    }
    if (!nullToAbsent || partyAccount != null) {
      map['party_account'] = Variable<String>(partyAccount);
    }
    if (!nullToAbsent || partyIdentifier != null) {
      map['party_identifier'] = Variable<String>(partyIdentifier);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  FinancialRecordsCompanion toCompanion(bool nullToAbsent) {
    return FinancialRecordsCompanion(
      id: Value(id),
      reversesRecordId: reversesRecordId == null && nullToAbsent
          ? const Value.absent()
          : Value(reversesRecordId),
      reference: Value(reference),
      sourceMessageId: sourceMessageId == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceMessageId),
      transactionDate: transactionDate == null && nullToAbsent
          ? const Value.absent()
          : Value(transactionDate),
      receivedAt: Value(receivedAt),
      amount: Value(amount),
      balance: balance == null && nullToAbsent
          ? const Value.absent()
          : Value(balance),
      transactionCost: transactionCost == null && nullToAbsent
          ? const Value.absent()
          : Value(transactionCost),
      type: Value(type),
      subtype: Value(subtype),
      interpretedType: interpretedType == null && nullToAbsent
          ? const Value.absent()
          : Value(interpretedType),
      interpretedSubtype: interpretedSubtype == null && nullToAbsent
          ? const Value.absent()
          : Value(interpretedSubtype),
      interpretationMappingId: interpretationMappingId == null && nullToAbsent
          ? const Value.absent()
          : Value(interpretationMappingId),
      status: Value(status),
      title: Value(title),
      rawMessage: Value(rawMessage),
      sourceAccountId: sourceAccountId == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceAccountId),
      destinationAccountId: destinationAccountId == null && nullToAbsent
          ? const Value.absent()
          : Value(destinationAccountId),
      partyName: partyName == null && nullToAbsent
          ? const Value.absent()
          : Value(partyName),
      partyType: partyType == null && nullToAbsent
          ? const Value.absent()
          : Value(partyType),
      partyPhone: partyPhone == null && nullToAbsent
          ? const Value.absent()
          : Value(partyPhone),
      partyAccount: partyAccount == null && nullToAbsent
          ? const Value.absent()
          : Value(partyAccount),
      partyIdentifier: partyIdentifier == null && nullToAbsent
          ? const Value.absent()
          : Value(partyIdentifier),
      createdAt: Value(createdAt),
    );
  }

  factory FinancialRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FinancialRecord(
      id: serializer.fromJson<int>(json['id']),
      reversesRecordId: serializer.fromJson<int?>(json['reversesRecordId']),
      reference: serializer.fromJson<String>(json['reference']),
      sourceMessageId: serializer.fromJson<String?>(json['sourceMessageId']),
      transactionDate: serializer.fromJson<DateTime?>(json['transactionDate']),
      receivedAt: serializer.fromJson<DateTime>(json['receivedAt']),
      amount: serializer.fromJson<double>(json['amount']),
      balance: serializer.fromJson<double?>(json['balance']),
      transactionCost: serializer.fromJson<double?>(json['transactionCost']),
      type: serializer.fromJson<String>(json['type']),
      subtype: serializer.fromJson<String>(json['subtype']),
      interpretedType: serializer.fromJson<String?>(json['interpretedType']),
      interpretedSubtype: serializer.fromJson<String?>(
        json['interpretedSubtype'],
      ),
      interpretationMappingId: serializer.fromJson<int?>(
        json['interpretationMappingId'],
      ),
      status: serializer.fromJson<String>(json['status']),
      title: serializer.fromJson<String>(json['title']),
      rawMessage: serializer.fromJson<String>(json['rawMessage']),
      sourceAccountId: serializer.fromJson<int?>(json['sourceAccountId']),
      destinationAccountId: serializer.fromJson<int?>(
        json['destinationAccountId'],
      ),
      partyName: serializer.fromJson<String?>(json['partyName']),
      partyType: serializer.fromJson<String?>(json['partyType']),
      partyPhone: serializer.fromJson<String?>(json['partyPhone']),
      partyAccount: serializer.fromJson<String?>(json['partyAccount']),
      partyIdentifier: serializer.fromJson<String?>(json['partyIdentifier']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'reversesRecordId': serializer.toJson<int?>(reversesRecordId),
      'reference': serializer.toJson<String>(reference),
      'sourceMessageId': serializer.toJson<String?>(sourceMessageId),
      'transactionDate': serializer.toJson<DateTime?>(transactionDate),
      'receivedAt': serializer.toJson<DateTime>(receivedAt),
      'amount': serializer.toJson<double>(amount),
      'balance': serializer.toJson<double?>(balance),
      'transactionCost': serializer.toJson<double?>(transactionCost),
      'type': serializer.toJson<String>(type),
      'subtype': serializer.toJson<String>(subtype),
      'interpretedType': serializer.toJson<String?>(interpretedType),
      'interpretedSubtype': serializer.toJson<String?>(interpretedSubtype),
      'interpretationMappingId': serializer.toJson<int?>(
        interpretationMappingId,
      ),
      'status': serializer.toJson<String>(status),
      'title': serializer.toJson<String>(title),
      'rawMessage': serializer.toJson<String>(rawMessage),
      'sourceAccountId': serializer.toJson<int?>(sourceAccountId),
      'destinationAccountId': serializer.toJson<int?>(destinationAccountId),
      'partyName': serializer.toJson<String?>(partyName),
      'partyType': serializer.toJson<String?>(partyType),
      'partyPhone': serializer.toJson<String?>(partyPhone),
      'partyAccount': serializer.toJson<String?>(partyAccount),
      'partyIdentifier': serializer.toJson<String?>(partyIdentifier),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  FinancialRecord copyWith({
    int? id,
    Value<int?> reversesRecordId = const Value.absent(),
    String? reference,
    Value<String?> sourceMessageId = const Value.absent(),
    Value<DateTime?> transactionDate = const Value.absent(),
    DateTime? receivedAt,
    double? amount,
    Value<double?> balance = const Value.absent(),
    Value<double?> transactionCost = const Value.absent(),
    String? type,
    String? subtype,
    Value<String?> interpretedType = const Value.absent(),
    Value<String?> interpretedSubtype = const Value.absent(),
    Value<int?> interpretationMappingId = const Value.absent(),
    String? status,
    String? title,
    String? rawMessage,
    Value<int?> sourceAccountId = const Value.absent(),
    Value<int?> destinationAccountId = const Value.absent(),
    Value<String?> partyName = const Value.absent(),
    Value<String?> partyType = const Value.absent(),
    Value<String?> partyPhone = const Value.absent(),
    Value<String?> partyAccount = const Value.absent(),
    Value<String?> partyIdentifier = const Value.absent(),
    DateTime? createdAt,
  }) => FinancialRecord(
    id: id ?? this.id,
    reversesRecordId: reversesRecordId.present
        ? reversesRecordId.value
        : this.reversesRecordId,
    reference: reference ?? this.reference,
    sourceMessageId: sourceMessageId.present
        ? sourceMessageId.value
        : this.sourceMessageId,
    transactionDate: transactionDate.present
        ? transactionDate.value
        : this.transactionDate,
    receivedAt: receivedAt ?? this.receivedAt,
    amount: amount ?? this.amount,
    balance: balance.present ? balance.value : this.balance,
    transactionCost: transactionCost.present
        ? transactionCost.value
        : this.transactionCost,
    type: type ?? this.type,
    subtype: subtype ?? this.subtype,
    interpretedType: interpretedType.present
        ? interpretedType.value
        : this.interpretedType,
    interpretedSubtype: interpretedSubtype.present
        ? interpretedSubtype.value
        : this.interpretedSubtype,
    interpretationMappingId: interpretationMappingId.present
        ? interpretationMappingId.value
        : this.interpretationMappingId,
    status: status ?? this.status,
    title: title ?? this.title,
    rawMessage: rawMessage ?? this.rawMessage,
    sourceAccountId: sourceAccountId.present
        ? sourceAccountId.value
        : this.sourceAccountId,
    destinationAccountId: destinationAccountId.present
        ? destinationAccountId.value
        : this.destinationAccountId,
    partyName: partyName.present ? partyName.value : this.partyName,
    partyType: partyType.present ? partyType.value : this.partyType,
    partyPhone: partyPhone.present ? partyPhone.value : this.partyPhone,
    partyAccount: partyAccount.present ? partyAccount.value : this.partyAccount,
    partyIdentifier: partyIdentifier.present
        ? partyIdentifier.value
        : this.partyIdentifier,
    createdAt: createdAt ?? this.createdAt,
  );
  FinancialRecord copyWithCompanion(FinancialRecordsCompanion data) {
    return FinancialRecord(
      id: data.id.present ? data.id.value : this.id,
      reversesRecordId: data.reversesRecordId.present
          ? data.reversesRecordId.value
          : this.reversesRecordId,
      reference: data.reference.present ? data.reference.value : this.reference,
      sourceMessageId: data.sourceMessageId.present
          ? data.sourceMessageId.value
          : this.sourceMessageId,
      transactionDate: data.transactionDate.present
          ? data.transactionDate.value
          : this.transactionDate,
      receivedAt: data.receivedAt.present
          ? data.receivedAt.value
          : this.receivedAt,
      amount: data.amount.present ? data.amount.value : this.amount,
      balance: data.balance.present ? data.balance.value : this.balance,
      transactionCost: data.transactionCost.present
          ? data.transactionCost.value
          : this.transactionCost,
      type: data.type.present ? data.type.value : this.type,
      subtype: data.subtype.present ? data.subtype.value : this.subtype,
      interpretedType: data.interpretedType.present
          ? data.interpretedType.value
          : this.interpretedType,
      interpretedSubtype: data.interpretedSubtype.present
          ? data.interpretedSubtype.value
          : this.interpretedSubtype,
      interpretationMappingId: data.interpretationMappingId.present
          ? data.interpretationMappingId.value
          : this.interpretationMappingId,
      status: data.status.present ? data.status.value : this.status,
      title: data.title.present ? data.title.value : this.title,
      rawMessage: data.rawMessage.present
          ? data.rawMessage.value
          : this.rawMessage,
      sourceAccountId: data.sourceAccountId.present
          ? data.sourceAccountId.value
          : this.sourceAccountId,
      destinationAccountId: data.destinationAccountId.present
          ? data.destinationAccountId.value
          : this.destinationAccountId,
      partyName: data.partyName.present ? data.partyName.value : this.partyName,
      partyType: data.partyType.present ? data.partyType.value : this.partyType,
      partyPhone: data.partyPhone.present
          ? data.partyPhone.value
          : this.partyPhone,
      partyAccount: data.partyAccount.present
          ? data.partyAccount.value
          : this.partyAccount,
      partyIdentifier: data.partyIdentifier.present
          ? data.partyIdentifier.value
          : this.partyIdentifier,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FinancialRecord(')
          ..write('id: $id, ')
          ..write('reversesRecordId: $reversesRecordId, ')
          ..write('reference: $reference, ')
          ..write('sourceMessageId: $sourceMessageId, ')
          ..write('transactionDate: $transactionDate, ')
          ..write('receivedAt: $receivedAt, ')
          ..write('amount: $amount, ')
          ..write('balance: $balance, ')
          ..write('transactionCost: $transactionCost, ')
          ..write('type: $type, ')
          ..write('subtype: $subtype, ')
          ..write('interpretedType: $interpretedType, ')
          ..write('interpretedSubtype: $interpretedSubtype, ')
          ..write('interpretationMappingId: $interpretationMappingId, ')
          ..write('status: $status, ')
          ..write('title: $title, ')
          ..write('rawMessage: $rawMessage, ')
          ..write('sourceAccountId: $sourceAccountId, ')
          ..write('destinationAccountId: $destinationAccountId, ')
          ..write('partyName: $partyName, ')
          ..write('partyType: $partyType, ')
          ..write('partyPhone: $partyPhone, ')
          ..write('partyAccount: $partyAccount, ')
          ..write('partyIdentifier: $partyIdentifier, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    reversesRecordId,
    reference,
    sourceMessageId,
    transactionDate,
    receivedAt,
    amount,
    balance,
    transactionCost,
    type,
    subtype,
    interpretedType,
    interpretedSubtype,
    interpretationMappingId,
    status,
    title,
    rawMessage,
    sourceAccountId,
    destinationAccountId,
    partyName,
    partyType,
    partyPhone,
    partyAccount,
    partyIdentifier,
    createdAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FinancialRecord &&
          other.id == this.id &&
          other.reversesRecordId == this.reversesRecordId &&
          other.reference == this.reference &&
          other.sourceMessageId == this.sourceMessageId &&
          other.transactionDate == this.transactionDate &&
          other.receivedAt == this.receivedAt &&
          other.amount == this.amount &&
          other.balance == this.balance &&
          other.transactionCost == this.transactionCost &&
          other.type == this.type &&
          other.subtype == this.subtype &&
          other.interpretedType == this.interpretedType &&
          other.interpretedSubtype == this.interpretedSubtype &&
          other.interpretationMappingId == this.interpretationMappingId &&
          other.status == this.status &&
          other.title == this.title &&
          other.rawMessage == this.rawMessage &&
          other.sourceAccountId == this.sourceAccountId &&
          other.destinationAccountId == this.destinationAccountId &&
          other.partyName == this.partyName &&
          other.partyType == this.partyType &&
          other.partyPhone == this.partyPhone &&
          other.partyAccount == this.partyAccount &&
          other.partyIdentifier == this.partyIdentifier &&
          other.createdAt == this.createdAt);
}

class FinancialRecordsCompanion extends UpdateCompanion<FinancialRecord> {
  final Value<int> id;
  final Value<int?> reversesRecordId;
  final Value<String> reference;
  final Value<String?> sourceMessageId;
  final Value<DateTime?> transactionDate;
  final Value<DateTime> receivedAt;
  final Value<double> amount;
  final Value<double?> balance;
  final Value<double?> transactionCost;
  final Value<String> type;
  final Value<String> subtype;
  final Value<String?> interpretedType;
  final Value<String?> interpretedSubtype;
  final Value<int?> interpretationMappingId;
  final Value<String> status;
  final Value<String> title;
  final Value<String> rawMessage;
  final Value<int?> sourceAccountId;
  final Value<int?> destinationAccountId;
  final Value<String?> partyName;
  final Value<String?> partyType;
  final Value<String?> partyPhone;
  final Value<String?> partyAccount;
  final Value<String?> partyIdentifier;
  final Value<DateTime> createdAt;
  const FinancialRecordsCompanion({
    this.id = const Value.absent(),
    this.reversesRecordId = const Value.absent(),
    this.reference = const Value.absent(),
    this.sourceMessageId = const Value.absent(),
    this.transactionDate = const Value.absent(),
    this.receivedAt = const Value.absent(),
    this.amount = const Value.absent(),
    this.balance = const Value.absent(),
    this.transactionCost = const Value.absent(),
    this.type = const Value.absent(),
    this.subtype = const Value.absent(),
    this.interpretedType = const Value.absent(),
    this.interpretedSubtype = const Value.absent(),
    this.interpretationMappingId = const Value.absent(),
    this.status = const Value.absent(),
    this.title = const Value.absent(),
    this.rawMessage = const Value.absent(),
    this.sourceAccountId = const Value.absent(),
    this.destinationAccountId = const Value.absent(),
    this.partyName = const Value.absent(),
    this.partyType = const Value.absent(),
    this.partyPhone = const Value.absent(),
    this.partyAccount = const Value.absent(),
    this.partyIdentifier = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  FinancialRecordsCompanion.insert({
    this.id = const Value.absent(),
    this.reversesRecordId = const Value.absent(),
    required String reference,
    this.sourceMessageId = const Value.absent(),
    this.transactionDate = const Value.absent(),
    required DateTime receivedAt,
    required double amount,
    this.balance = const Value.absent(),
    this.transactionCost = const Value.absent(),
    required String type,
    required String subtype,
    this.interpretedType = const Value.absent(),
    this.interpretedSubtype = const Value.absent(),
    this.interpretationMappingId = const Value.absent(),
    required String status,
    required String title,
    required String rawMessage,
    this.sourceAccountId = const Value.absent(),
    this.destinationAccountId = const Value.absent(),
    this.partyName = const Value.absent(),
    this.partyType = const Value.absent(),
    this.partyPhone = const Value.absent(),
    this.partyAccount = const Value.absent(),
    this.partyIdentifier = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : reference = Value(reference),
       receivedAt = Value(receivedAt),
       amount = Value(amount),
       type = Value(type),
       subtype = Value(subtype),
       status = Value(status),
       title = Value(title),
       rawMessage = Value(rawMessage);
  static Insertable<FinancialRecord> custom({
    Expression<int>? id,
    Expression<int>? reversesRecordId,
    Expression<String>? reference,
    Expression<String>? sourceMessageId,
    Expression<DateTime>? transactionDate,
    Expression<DateTime>? receivedAt,
    Expression<double>? amount,
    Expression<double>? balance,
    Expression<double>? transactionCost,
    Expression<String>? type,
    Expression<String>? subtype,
    Expression<String>? interpretedType,
    Expression<String>? interpretedSubtype,
    Expression<int>? interpretationMappingId,
    Expression<String>? status,
    Expression<String>? title,
    Expression<String>? rawMessage,
    Expression<int>? sourceAccountId,
    Expression<int>? destinationAccountId,
    Expression<String>? partyName,
    Expression<String>? partyType,
    Expression<String>? partyPhone,
    Expression<String>? partyAccount,
    Expression<String>? partyIdentifier,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (reversesRecordId != null) 'reverses_record_id': reversesRecordId,
      if (reference != null) 'reference': reference,
      if (sourceMessageId != null) 'source_message_id': sourceMessageId,
      if (transactionDate != null) 'transaction_date': transactionDate,
      if (receivedAt != null) 'received_at': receivedAt,
      if (amount != null) 'amount': amount,
      if (balance != null) 'balance': balance,
      if (transactionCost != null) 'transaction_cost': transactionCost,
      if (type != null) 'type': type,
      if (subtype != null) 'subtype': subtype,
      if (interpretedType != null) 'interpreted_type': interpretedType,
      if (interpretedSubtype != null) 'interpreted_subtype': interpretedSubtype,
      if (interpretationMappingId != null)
        'interpretation_mapping_id': interpretationMappingId,
      if (status != null) 'status': status,
      if (title != null) 'title': title,
      if (rawMessage != null) 'raw_message': rawMessage,
      if (sourceAccountId != null) 'source_account_id': sourceAccountId,
      if (destinationAccountId != null)
        'destination_account_id': destinationAccountId,
      if (partyName != null) 'party_name': partyName,
      if (partyType != null) 'party_type': partyType,
      if (partyPhone != null) 'party_phone': partyPhone,
      if (partyAccount != null) 'party_account': partyAccount,
      if (partyIdentifier != null) 'party_identifier': partyIdentifier,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  FinancialRecordsCompanion copyWith({
    Value<int>? id,
    Value<int?>? reversesRecordId,
    Value<String>? reference,
    Value<String?>? sourceMessageId,
    Value<DateTime?>? transactionDate,
    Value<DateTime>? receivedAt,
    Value<double>? amount,
    Value<double?>? balance,
    Value<double?>? transactionCost,
    Value<String>? type,
    Value<String>? subtype,
    Value<String?>? interpretedType,
    Value<String?>? interpretedSubtype,
    Value<int?>? interpretationMappingId,
    Value<String>? status,
    Value<String>? title,
    Value<String>? rawMessage,
    Value<int?>? sourceAccountId,
    Value<int?>? destinationAccountId,
    Value<String?>? partyName,
    Value<String?>? partyType,
    Value<String?>? partyPhone,
    Value<String?>? partyAccount,
    Value<String?>? partyIdentifier,
    Value<DateTime>? createdAt,
  }) {
    return FinancialRecordsCompanion(
      id: id ?? this.id,
      reversesRecordId: reversesRecordId ?? this.reversesRecordId,
      reference: reference ?? this.reference,
      sourceMessageId: sourceMessageId ?? this.sourceMessageId,
      transactionDate: transactionDate ?? this.transactionDate,
      receivedAt: receivedAt ?? this.receivedAt,
      amount: amount ?? this.amount,
      balance: balance ?? this.balance,
      transactionCost: transactionCost ?? this.transactionCost,
      type: type ?? this.type,
      subtype: subtype ?? this.subtype,
      interpretedType: interpretedType ?? this.interpretedType,
      interpretedSubtype: interpretedSubtype ?? this.interpretedSubtype,
      interpretationMappingId:
          interpretationMappingId ?? this.interpretationMappingId,
      status: status ?? this.status,
      title: title ?? this.title,
      rawMessage: rawMessage ?? this.rawMessage,
      sourceAccountId: sourceAccountId ?? this.sourceAccountId,
      destinationAccountId: destinationAccountId ?? this.destinationAccountId,
      partyName: partyName ?? this.partyName,
      partyType: partyType ?? this.partyType,
      partyPhone: partyPhone ?? this.partyPhone,
      partyAccount: partyAccount ?? this.partyAccount,
      partyIdentifier: partyIdentifier ?? this.partyIdentifier,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (reversesRecordId.present) {
      map['reverses_record_id'] = Variable<int>(reversesRecordId.value);
    }
    if (reference.present) {
      map['reference'] = Variable<String>(reference.value);
    }
    if (sourceMessageId.present) {
      map['source_message_id'] = Variable<String>(sourceMessageId.value);
    }
    if (transactionDate.present) {
      map['transaction_date'] = Variable<DateTime>(transactionDate.value);
    }
    if (receivedAt.present) {
      map['received_at'] = Variable<DateTime>(receivedAt.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (balance.present) {
      map['balance'] = Variable<double>(balance.value);
    }
    if (transactionCost.present) {
      map['transaction_cost'] = Variable<double>(transactionCost.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (subtype.present) {
      map['subtype'] = Variable<String>(subtype.value);
    }
    if (interpretedType.present) {
      map['interpreted_type'] = Variable<String>(interpretedType.value);
    }
    if (interpretedSubtype.present) {
      map['interpreted_subtype'] = Variable<String>(interpretedSubtype.value);
    }
    if (interpretationMappingId.present) {
      map['interpretation_mapping_id'] = Variable<int>(
        interpretationMappingId.value,
      );
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (rawMessage.present) {
      map['raw_message'] = Variable<String>(rawMessage.value);
    }
    if (sourceAccountId.present) {
      map['source_account_id'] = Variable<int>(sourceAccountId.value);
    }
    if (destinationAccountId.present) {
      map['destination_account_id'] = Variable<int>(destinationAccountId.value);
    }
    if (partyName.present) {
      map['party_name'] = Variable<String>(partyName.value);
    }
    if (partyType.present) {
      map['party_type'] = Variable<String>(partyType.value);
    }
    if (partyPhone.present) {
      map['party_phone'] = Variable<String>(partyPhone.value);
    }
    if (partyAccount.present) {
      map['party_account'] = Variable<String>(partyAccount.value);
    }
    if (partyIdentifier.present) {
      map['party_identifier'] = Variable<String>(partyIdentifier.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FinancialRecordsCompanion(')
          ..write('id: $id, ')
          ..write('reversesRecordId: $reversesRecordId, ')
          ..write('reference: $reference, ')
          ..write('sourceMessageId: $sourceMessageId, ')
          ..write('transactionDate: $transactionDate, ')
          ..write('receivedAt: $receivedAt, ')
          ..write('amount: $amount, ')
          ..write('balance: $balance, ')
          ..write('transactionCost: $transactionCost, ')
          ..write('type: $type, ')
          ..write('subtype: $subtype, ')
          ..write('interpretedType: $interpretedType, ')
          ..write('interpretedSubtype: $interpretedSubtype, ')
          ..write('interpretationMappingId: $interpretationMappingId, ')
          ..write('status: $status, ')
          ..write('title: $title, ')
          ..write('rawMessage: $rawMessage, ')
          ..write('sourceAccountId: $sourceAccountId, ')
          ..write('destinationAccountId: $destinationAccountId, ')
          ..write('partyName: $partyName, ')
          ..write('partyType: $partyType, ')
          ..write('partyPhone: $partyPhone, ')
          ..write('partyAccount: $partyAccount, ')
          ..write('partyIdentifier: $partyIdentifier, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $RawMessagesTable extends RawMessages
    with TableInfo<$RawMessagesTable, RawMessage> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RawMessagesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _sourceIdMeta = const VerificationMeta(
    'sourceId',
  );
  @override
  late final GeneratedColumn<String> sourceId = GeneratedColumn<String>(
    'source_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _senderMeta = const VerificationMeta('sender');
  @override
  late final GeneratedColumn<String> sender = GeneratedColumn<String>(
    'sender',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _receivedAtMeta = const VerificationMeta(
    'receivedAt',
  );
  @override
  late final GeneratedColumn<DateTime> receivedAt = GeneratedColumn<DateTime>(
    'received_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sourceId,
    sender,
    body,
    receivedAt,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'raw_messages';
  @override
  VerificationContext validateIntegrity(
    Insertable<RawMessage> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('source_id')) {
      context.handle(
        _sourceIdMeta,
        sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceIdMeta);
    }
    if (data.containsKey('sender')) {
      context.handle(
        _senderMeta,
        sender.isAcceptableOrUnknown(data['sender']!, _senderMeta),
      );
    } else if (isInserting) {
      context.missing(_senderMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    if (data.containsKey('received_at')) {
      context.handle(
        _receivedAtMeta,
        receivedAt.isAcceptableOrUnknown(data['received_at']!, _receivedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_receivedAtMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RawMessage map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RawMessage(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_id'],
      )!,
      sender: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sender'],
      )!,
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      )!,
      receivedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}received_at'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $RawMessagesTable createAlias(String alias) {
    return $RawMessagesTable(attachedDatabase, alias);
  }
}

class RawMessage extends DataClass implements Insertable<RawMessage> {
  final int id;
  final String sourceId;
  final String sender;
  final String body;
  final DateTime receivedAt;
  final DateTime createdAt;
  const RawMessage({
    required this.id,
    required this.sourceId,
    required this.sender,
    required this.body,
    required this.receivedAt,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['source_id'] = Variable<String>(sourceId);
    map['sender'] = Variable<String>(sender);
    map['body'] = Variable<String>(body);
    map['received_at'] = Variable<DateTime>(receivedAt);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  RawMessagesCompanion toCompanion(bool nullToAbsent) {
    return RawMessagesCompanion(
      id: Value(id),
      sourceId: Value(sourceId),
      sender: Value(sender),
      body: Value(body),
      receivedAt: Value(receivedAt),
      createdAt: Value(createdAt),
    );
  }

  factory RawMessage.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RawMessage(
      id: serializer.fromJson<int>(json['id']),
      sourceId: serializer.fromJson<String>(json['sourceId']),
      sender: serializer.fromJson<String>(json['sender']),
      body: serializer.fromJson<String>(json['body']),
      receivedAt: serializer.fromJson<DateTime>(json['receivedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sourceId': serializer.toJson<String>(sourceId),
      'sender': serializer.toJson<String>(sender),
      'body': serializer.toJson<String>(body),
      'receivedAt': serializer.toJson<DateTime>(receivedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  RawMessage copyWith({
    int? id,
    String? sourceId,
    String? sender,
    String? body,
    DateTime? receivedAt,
    DateTime? createdAt,
  }) => RawMessage(
    id: id ?? this.id,
    sourceId: sourceId ?? this.sourceId,
    sender: sender ?? this.sender,
    body: body ?? this.body,
    receivedAt: receivedAt ?? this.receivedAt,
    createdAt: createdAt ?? this.createdAt,
  );
  RawMessage copyWithCompanion(RawMessagesCompanion data) {
    return RawMessage(
      id: data.id.present ? data.id.value : this.id,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      sender: data.sender.present ? data.sender.value : this.sender,
      body: data.body.present ? data.body.value : this.body,
      receivedAt: data.receivedAt.present
          ? data.receivedAt.value
          : this.receivedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RawMessage(')
          ..write('id: $id, ')
          ..write('sourceId: $sourceId, ')
          ..write('sender: $sender, ')
          ..write('body: $body, ')
          ..write('receivedAt: $receivedAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, sourceId, sender, body, receivedAt, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RawMessage &&
          other.id == this.id &&
          other.sourceId == this.sourceId &&
          other.sender == this.sender &&
          other.body == this.body &&
          other.receivedAt == this.receivedAt &&
          other.createdAt == this.createdAt);
}

class RawMessagesCompanion extends UpdateCompanion<RawMessage> {
  final Value<int> id;
  final Value<String> sourceId;
  final Value<String> sender;
  final Value<String> body;
  final Value<DateTime> receivedAt;
  final Value<DateTime> createdAt;
  const RawMessagesCompanion({
    this.id = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.sender = const Value.absent(),
    this.body = const Value.absent(),
    this.receivedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  RawMessagesCompanion.insert({
    this.id = const Value.absent(),
    required String sourceId,
    required String sender,
    required String body,
    required DateTime receivedAt,
    this.createdAt = const Value.absent(),
  }) : sourceId = Value(sourceId),
       sender = Value(sender),
       body = Value(body),
       receivedAt = Value(receivedAt);
  static Insertable<RawMessage> custom({
    Expression<int>? id,
    Expression<String>? sourceId,
    Expression<String>? sender,
    Expression<String>? body,
    Expression<DateTime>? receivedAt,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sourceId != null) 'source_id': sourceId,
      if (sender != null) 'sender': sender,
      if (body != null) 'body': body,
      if (receivedAt != null) 'received_at': receivedAt,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  RawMessagesCompanion copyWith({
    Value<int>? id,
    Value<String>? sourceId,
    Value<String>? sender,
    Value<String>? body,
    Value<DateTime>? receivedAt,
    Value<DateTime>? createdAt,
  }) {
    return RawMessagesCompanion(
      id: id ?? this.id,
      sourceId: sourceId ?? this.sourceId,
      sender: sender ?? this.sender,
      body: body ?? this.body,
      receivedAt: receivedAt ?? this.receivedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sourceId.present) {
      map['source_id'] = Variable<String>(sourceId.value);
    }
    if (sender.present) {
      map['sender'] = Variable<String>(sender.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (receivedAt.present) {
      map['received_at'] = Variable<DateTime>(receivedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RawMessagesCompanion(')
          ..write('id: $id, ')
          ..write('sourceId: $sourceId, ')
          ..write('sender: $sender, ')
          ..write('body: $body, ')
          ..write('receivedAt: $receivedAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $BalanceEvidenceTable extends BalanceEvidence
    with TableInfo<$BalanceEvidenceTable, StoredBalanceEvidence> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BalanceEvidenceTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMinorMeta = const VerificationMeta(
    'amountMinor',
  );
  @override
  late final GeneratedColumn<int> amountMinor = GeneratedColumn<int>(
    'amount_minor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currencyMeta = const VerificationMeta(
    'currency',
  );
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
    'currency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _subjectFamilyMeta = const VerificationMeta(
    'subjectFamily',
  );
  @override
  late final GeneratedColumn<String> subjectFamily = GeneratedColumn<String>(
    'subject_family',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _originMeta = const VerificationMeta('origin');
  @override
  late final GeneratedColumn<String> origin = GeneratedColumn<String>(
    'origin',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _asOfMillisMeta = const VerificationMeta(
    'asOfMillis',
  );
  @override
  late final GeneratedColumn<int> asOfMillis = GeneratedColumn<int>(
    'as_of_millis',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timeBasisMeta = const VerificationMeta(
    'timeBasis',
  );
  @override
  late final GeneratedColumn<String> timeBasis = GeneratedColumn<String>(
    'time_basis',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdMillisMeta = const VerificationMeta(
    'createdMillis',
  );
  @override
  late final GeneratedColumn<int> createdMillis = GeneratedColumn<int>(
    'created_millis',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _financialRecordIdMeta = const VerificationMeta(
    'financialRecordId',
  );
  @override
  late final GeneratedColumn<int> financialRecordId = GeneratedColumn<int>(
    'financial_record_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES financial_records (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _rawMessageIdMeta = const VerificationMeta(
    'rawMessageId',
  );
  @override
  late final GeneratedColumn<int> rawMessageId = GeneratedColumn<int>(
    'raw_message_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES raw_messages (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _matchedClauseMeta = const VerificationMeta(
    'matchedClause',
  );
  @override
  late final GeneratedColumn<String> matchedClause = GeneratedColumn<String>(
    'matched_clause',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _extractionVersionMeta = const VerificationMeta(
    'extractionVersion',
  );
  @override
  late final GeneratedColumn<String> extractionVersion =
      GeneratedColumn<String>(
        'extraction_version',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<int> accountId = GeneratedColumn<int>(
    'account_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES accounts (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _associationOriginMeta = const VerificationMeta(
    'associationOrigin',
  );
  @override
  late final GeneratedColumn<String> associationOrigin =
      GeneratedColumn<String>(
        'association_origin',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _associatedMillisMeta = const VerificationMeta(
    'associatedMillis',
  );
  @override
  late final GeneratedColumn<int> associatedMillis = GeneratedColumn<int>(
    'associated_millis',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _revisionMeta = const VerificationMeta(
    'revision',
  );
  @override
  late final GeneratedColumn<int> revision = GeneratedColumn<int>(
    'revision',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    amountMinor,
    currency,
    kind,
    subjectFamily,
    origin,
    asOfMillis,
    timeBasis,
    createdMillis,
    financialRecordId,
    rawMessageId,
    matchedClause,
    extractionVersion,
    accountId,
    associationOrigin,
    associatedMillis,
    revision,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'balance_evidence';
  @override
  VerificationContext validateIntegrity(
    Insertable<StoredBalanceEvidence> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('amount_minor')) {
      context.handle(
        _amountMinorMeta,
        amountMinor.isAcceptableOrUnknown(
          data['amount_minor']!,
          _amountMinorMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_amountMinorMeta);
    }
    if (data.containsKey('currency')) {
      context.handle(
        _currencyMeta,
        currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta),
      );
    } else if (isInserting) {
      context.missing(_currencyMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('subject_family')) {
      context.handle(
        _subjectFamilyMeta,
        subjectFamily.isAcceptableOrUnknown(
          data['subject_family']!,
          _subjectFamilyMeta,
        ),
      );
    }
    if (data.containsKey('origin')) {
      context.handle(
        _originMeta,
        origin.isAcceptableOrUnknown(data['origin']!, _originMeta),
      );
    } else if (isInserting) {
      context.missing(_originMeta);
    }
    if (data.containsKey('as_of_millis')) {
      context.handle(
        _asOfMillisMeta,
        asOfMillis.isAcceptableOrUnknown(
          data['as_of_millis']!,
          _asOfMillisMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_asOfMillisMeta);
    }
    if (data.containsKey('time_basis')) {
      context.handle(
        _timeBasisMeta,
        timeBasis.isAcceptableOrUnknown(data['time_basis']!, _timeBasisMeta),
      );
    } else if (isInserting) {
      context.missing(_timeBasisMeta);
    }
    if (data.containsKey('created_millis')) {
      context.handle(
        _createdMillisMeta,
        createdMillis.isAcceptableOrUnknown(
          data['created_millis']!,
          _createdMillisMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdMillisMeta);
    }
    if (data.containsKey('financial_record_id')) {
      context.handle(
        _financialRecordIdMeta,
        financialRecordId.isAcceptableOrUnknown(
          data['financial_record_id']!,
          _financialRecordIdMeta,
        ),
      );
    }
    if (data.containsKey('raw_message_id')) {
      context.handle(
        _rawMessageIdMeta,
        rawMessageId.isAcceptableOrUnknown(
          data['raw_message_id']!,
          _rawMessageIdMeta,
        ),
      );
    }
    if (data.containsKey('matched_clause')) {
      context.handle(
        _matchedClauseMeta,
        matchedClause.isAcceptableOrUnknown(
          data['matched_clause']!,
          _matchedClauseMeta,
        ),
      );
    }
    if (data.containsKey('extraction_version')) {
      context.handle(
        _extractionVersionMeta,
        extractionVersion.isAcceptableOrUnknown(
          data['extraction_version']!,
          _extractionVersionMeta,
        ),
      );
    }
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    }
    if (data.containsKey('association_origin')) {
      context.handle(
        _associationOriginMeta,
        associationOrigin.isAcceptableOrUnknown(
          data['association_origin']!,
          _associationOriginMeta,
        ),
      );
    }
    if (data.containsKey('associated_millis')) {
      context.handle(
        _associatedMillisMeta,
        associatedMillis.isAcceptableOrUnknown(
          data['associated_millis']!,
          _associatedMillisMeta,
        ),
      );
    }
    if (data.containsKey('revision')) {
      context.handle(
        _revisionMeta,
        revision.isAcceptableOrUnknown(data['revision']!, _revisionMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StoredBalanceEvidence map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StoredBalanceEvidence(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      amountMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_minor'],
      )!,
      currency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      subjectFamily: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subject_family'],
      ),
      origin: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}origin'],
      )!,
      asOfMillis: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}as_of_millis'],
      )!,
      timeBasis: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}time_basis'],
      )!,
      createdMillis: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_millis'],
      )!,
      financialRecordId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}financial_record_id'],
      ),
      rawMessageId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}raw_message_id'],
      ),
      matchedClause: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}matched_clause'],
      ),
      extractionVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}extraction_version'],
      ),
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}account_id'],
      ),
      associationOrigin: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}association_origin'],
      ),
      associatedMillis: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}associated_millis'],
      ),
      revision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}revision'],
      )!,
    );
  }

  @override
  $BalanceEvidenceTable createAlias(String alias) {
    return $BalanceEvidenceTable(attachedDatabase, alias);
  }
}

class StoredBalanceEvidence extends DataClass
    implements Insertable<StoredBalanceEvidence> {
  final String id;
  final int amountMinor;
  final String currency;
  final String kind;
  final String? subjectFamily;
  final String origin;
  final int asOfMillis;
  final String timeBasis;
  final int createdMillis;
  final int? financialRecordId;
  final int? rawMessageId;
  final String? matchedClause;
  final String? extractionVersion;
  final int? accountId;
  final String? associationOrigin;
  final int? associatedMillis;
  final int revision;
  const StoredBalanceEvidence({
    required this.id,
    required this.amountMinor,
    required this.currency,
    required this.kind,
    this.subjectFamily,
    required this.origin,
    required this.asOfMillis,
    required this.timeBasis,
    required this.createdMillis,
    this.financialRecordId,
    this.rawMessageId,
    this.matchedClause,
    this.extractionVersion,
    this.accountId,
    this.associationOrigin,
    this.associatedMillis,
    required this.revision,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['amount_minor'] = Variable<int>(amountMinor);
    map['currency'] = Variable<String>(currency);
    map['kind'] = Variable<String>(kind);
    if (!nullToAbsent || subjectFamily != null) {
      map['subject_family'] = Variable<String>(subjectFamily);
    }
    map['origin'] = Variable<String>(origin);
    map['as_of_millis'] = Variable<int>(asOfMillis);
    map['time_basis'] = Variable<String>(timeBasis);
    map['created_millis'] = Variable<int>(createdMillis);
    if (!nullToAbsent || financialRecordId != null) {
      map['financial_record_id'] = Variable<int>(financialRecordId);
    }
    if (!nullToAbsent || rawMessageId != null) {
      map['raw_message_id'] = Variable<int>(rawMessageId);
    }
    if (!nullToAbsent || matchedClause != null) {
      map['matched_clause'] = Variable<String>(matchedClause);
    }
    if (!nullToAbsent || extractionVersion != null) {
      map['extraction_version'] = Variable<String>(extractionVersion);
    }
    if (!nullToAbsent || accountId != null) {
      map['account_id'] = Variable<int>(accountId);
    }
    if (!nullToAbsent || associationOrigin != null) {
      map['association_origin'] = Variable<String>(associationOrigin);
    }
    if (!nullToAbsent || associatedMillis != null) {
      map['associated_millis'] = Variable<int>(associatedMillis);
    }
    map['revision'] = Variable<int>(revision);
    return map;
  }

  BalanceEvidenceCompanion toCompanion(bool nullToAbsent) {
    return BalanceEvidenceCompanion(
      id: Value(id),
      amountMinor: Value(amountMinor),
      currency: Value(currency),
      kind: Value(kind),
      subjectFamily: subjectFamily == null && nullToAbsent
          ? const Value.absent()
          : Value(subjectFamily),
      origin: Value(origin),
      asOfMillis: Value(asOfMillis),
      timeBasis: Value(timeBasis),
      createdMillis: Value(createdMillis),
      financialRecordId: financialRecordId == null && nullToAbsent
          ? const Value.absent()
          : Value(financialRecordId),
      rawMessageId: rawMessageId == null && nullToAbsent
          ? const Value.absent()
          : Value(rawMessageId),
      matchedClause: matchedClause == null && nullToAbsent
          ? const Value.absent()
          : Value(matchedClause),
      extractionVersion: extractionVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(extractionVersion),
      accountId: accountId == null && nullToAbsent
          ? const Value.absent()
          : Value(accountId),
      associationOrigin: associationOrigin == null && nullToAbsent
          ? const Value.absent()
          : Value(associationOrigin),
      associatedMillis: associatedMillis == null && nullToAbsent
          ? const Value.absent()
          : Value(associatedMillis),
      revision: Value(revision),
    );
  }

  factory StoredBalanceEvidence.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StoredBalanceEvidence(
      id: serializer.fromJson<String>(json['id']),
      amountMinor: serializer.fromJson<int>(json['amountMinor']),
      currency: serializer.fromJson<String>(json['currency']),
      kind: serializer.fromJson<String>(json['kind']),
      subjectFamily: serializer.fromJson<String?>(json['subjectFamily']),
      origin: serializer.fromJson<String>(json['origin']),
      asOfMillis: serializer.fromJson<int>(json['asOfMillis']),
      timeBasis: serializer.fromJson<String>(json['timeBasis']),
      createdMillis: serializer.fromJson<int>(json['createdMillis']),
      financialRecordId: serializer.fromJson<int?>(json['financialRecordId']),
      rawMessageId: serializer.fromJson<int?>(json['rawMessageId']),
      matchedClause: serializer.fromJson<String?>(json['matchedClause']),
      extractionVersion: serializer.fromJson<String?>(
        json['extractionVersion'],
      ),
      accountId: serializer.fromJson<int?>(json['accountId']),
      associationOrigin: serializer.fromJson<String?>(
        json['associationOrigin'],
      ),
      associatedMillis: serializer.fromJson<int?>(json['associatedMillis']),
      revision: serializer.fromJson<int>(json['revision']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'amountMinor': serializer.toJson<int>(amountMinor),
      'currency': serializer.toJson<String>(currency),
      'kind': serializer.toJson<String>(kind),
      'subjectFamily': serializer.toJson<String?>(subjectFamily),
      'origin': serializer.toJson<String>(origin),
      'asOfMillis': serializer.toJson<int>(asOfMillis),
      'timeBasis': serializer.toJson<String>(timeBasis),
      'createdMillis': serializer.toJson<int>(createdMillis),
      'financialRecordId': serializer.toJson<int?>(financialRecordId),
      'rawMessageId': serializer.toJson<int?>(rawMessageId),
      'matchedClause': serializer.toJson<String?>(matchedClause),
      'extractionVersion': serializer.toJson<String?>(extractionVersion),
      'accountId': serializer.toJson<int?>(accountId),
      'associationOrigin': serializer.toJson<String?>(associationOrigin),
      'associatedMillis': serializer.toJson<int?>(associatedMillis),
      'revision': serializer.toJson<int>(revision),
    };
  }

  StoredBalanceEvidence copyWith({
    String? id,
    int? amountMinor,
    String? currency,
    String? kind,
    Value<String?> subjectFamily = const Value.absent(),
    String? origin,
    int? asOfMillis,
    String? timeBasis,
    int? createdMillis,
    Value<int?> financialRecordId = const Value.absent(),
    Value<int?> rawMessageId = const Value.absent(),
    Value<String?> matchedClause = const Value.absent(),
    Value<String?> extractionVersion = const Value.absent(),
    Value<int?> accountId = const Value.absent(),
    Value<String?> associationOrigin = const Value.absent(),
    Value<int?> associatedMillis = const Value.absent(),
    int? revision,
  }) => StoredBalanceEvidence(
    id: id ?? this.id,
    amountMinor: amountMinor ?? this.amountMinor,
    currency: currency ?? this.currency,
    kind: kind ?? this.kind,
    subjectFamily: subjectFamily.present
        ? subjectFamily.value
        : this.subjectFamily,
    origin: origin ?? this.origin,
    asOfMillis: asOfMillis ?? this.asOfMillis,
    timeBasis: timeBasis ?? this.timeBasis,
    createdMillis: createdMillis ?? this.createdMillis,
    financialRecordId: financialRecordId.present
        ? financialRecordId.value
        : this.financialRecordId,
    rawMessageId: rawMessageId.present ? rawMessageId.value : this.rawMessageId,
    matchedClause: matchedClause.present
        ? matchedClause.value
        : this.matchedClause,
    extractionVersion: extractionVersion.present
        ? extractionVersion.value
        : this.extractionVersion,
    accountId: accountId.present ? accountId.value : this.accountId,
    associationOrigin: associationOrigin.present
        ? associationOrigin.value
        : this.associationOrigin,
    associatedMillis: associatedMillis.present
        ? associatedMillis.value
        : this.associatedMillis,
    revision: revision ?? this.revision,
  );
  StoredBalanceEvidence copyWithCompanion(BalanceEvidenceCompanion data) {
    return StoredBalanceEvidence(
      id: data.id.present ? data.id.value : this.id,
      amountMinor: data.amountMinor.present
          ? data.amountMinor.value
          : this.amountMinor,
      currency: data.currency.present ? data.currency.value : this.currency,
      kind: data.kind.present ? data.kind.value : this.kind,
      subjectFamily: data.subjectFamily.present
          ? data.subjectFamily.value
          : this.subjectFamily,
      origin: data.origin.present ? data.origin.value : this.origin,
      asOfMillis: data.asOfMillis.present
          ? data.asOfMillis.value
          : this.asOfMillis,
      timeBasis: data.timeBasis.present ? data.timeBasis.value : this.timeBasis,
      createdMillis: data.createdMillis.present
          ? data.createdMillis.value
          : this.createdMillis,
      financialRecordId: data.financialRecordId.present
          ? data.financialRecordId.value
          : this.financialRecordId,
      rawMessageId: data.rawMessageId.present
          ? data.rawMessageId.value
          : this.rawMessageId,
      matchedClause: data.matchedClause.present
          ? data.matchedClause.value
          : this.matchedClause,
      extractionVersion: data.extractionVersion.present
          ? data.extractionVersion.value
          : this.extractionVersion,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      associationOrigin: data.associationOrigin.present
          ? data.associationOrigin.value
          : this.associationOrigin,
      associatedMillis: data.associatedMillis.present
          ? data.associatedMillis.value
          : this.associatedMillis,
      revision: data.revision.present ? data.revision.value : this.revision,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StoredBalanceEvidence(')
          ..write('id: $id, ')
          ..write('amountMinor: $amountMinor, ')
          ..write('currency: $currency, ')
          ..write('kind: $kind, ')
          ..write('subjectFamily: $subjectFamily, ')
          ..write('origin: $origin, ')
          ..write('asOfMillis: $asOfMillis, ')
          ..write('timeBasis: $timeBasis, ')
          ..write('createdMillis: $createdMillis, ')
          ..write('financialRecordId: $financialRecordId, ')
          ..write('rawMessageId: $rawMessageId, ')
          ..write('matchedClause: $matchedClause, ')
          ..write('extractionVersion: $extractionVersion, ')
          ..write('accountId: $accountId, ')
          ..write('associationOrigin: $associationOrigin, ')
          ..write('associatedMillis: $associatedMillis, ')
          ..write('revision: $revision')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    amountMinor,
    currency,
    kind,
    subjectFamily,
    origin,
    asOfMillis,
    timeBasis,
    createdMillis,
    financialRecordId,
    rawMessageId,
    matchedClause,
    extractionVersion,
    accountId,
    associationOrigin,
    associatedMillis,
    revision,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StoredBalanceEvidence &&
          other.id == this.id &&
          other.amountMinor == this.amountMinor &&
          other.currency == this.currency &&
          other.kind == this.kind &&
          other.subjectFamily == this.subjectFamily &&
          other.origin == this.origin &&
          other.asOfMillis == this.asOfMillis &&
          other.timeBasis == this.timeBasis &&
          other.createdMillis == this.createdMillis &&
          other.financialRecordId == this.financialRecordId &&
          other.rawMessageId == this.rawMessageId &&
          other.matchedClause == this.matchedClause &&
          other.extractionVersion == this.extractionVersion &&
          other.accountId == this.accountId &&
          other.associationOrigin == this.associationOrigin &&
          other.associatedMillis == this.associatedMillis &&
          other.revision == this.revision);
}

class BalanceEvidenceCompanion extends UpdateCompanion<StoredBalanceEvidence> {
  final Value<String> id;
  final Value<int> amountMinor;
  final Value<String> currency;
  final Value<String> kind;
  final Value<String?> subjectFamily;
  final Value<String> origin;
  final Value<int> asOfMillis;
  final Value<String> timeBasis;
  final Value<int> createdMillis;
  final Value<int?> financialRecordId;
  final Value<int?> rawMessageId;
  final Value<String?> matchedClause;
  final Value<String?> extractionVersion;
  final Value<int?> accountId;
  final Value<String?> associationOrigin;
  final Value<int?> associatedMillis;
  final Value<int> revision;
  final Value<int> rowid;
  const BalanceEvidenceCompanion({
    this.id = const Value.absent(),
    this.amountMinor = const Value.absent(),
    this.currency = const Value.absent(),
    this.kind = const Value.absent(),
    this.subjectFamily = const Value.absent(),
    this.origin = const Value.absent(),
    this.asOfMillis = const Value.absent(),
    this.timeBasis = const Value.absent(),
    this.createdMillis = const Value.absent(),
    this.financialRecordId = const Value.absent(),
    this.rawMessageId = const Value.absent(),
    this.matchedClause = const Value.absent(),
    this.extractionVersion = const Value.absent(),
    this.accountId = const Value.absent(),
    this.associationOrigin = const Value.absent(),
    this.associatedMillis = const Value.absent(),
    this.revision = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BalanceEvidenceCompanion.insert({
    required String id,
    required int amountMinor,
    required String currency,
    required String kind,
    this.subjectFamily = const Value.absent(),
    required String origin,
    required int asOfMillis,
    required String timeBasis,
    required int createdMillis,
    this.financialRecordId = const Value.absent(),
    this.rawMessageId = const Value.absent(),
    this.matchedClause = const Value.absent(),
    this.extractionVersion = const Value.absent(),
    this.accountId = const Value.absent(),
    this.associationOrigin = const Value.absent(),
    this.associatedMillis = const Value.absent(),
    this.revision = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       amountMinor = Value(amountMinor),
       currency = Value(currency),
       kind = Value(kind),
       origin = Value(origin),
       asOfMillis = Value(asOfMillis),
       timeBasis = Value(timeBasis),
       createdMillis = Value(createdMillis);
  static Insertable<StoredBalanceEvidence> custom({
    Expression<String>? id,
    Expression<int>? amountMinor,
    Expression<String>? currency,
    Expression<String>? kind,
    Expression<String>? subjectFamily,
    Expression<String>? origin,
    Expression<int>? asOfMillis,
    Expression<String>? timeBasis,
    Expression<int>? createdMillis,
    Expression<int>? financialRecordId,
    Expression<int>? rawMessageId,
    Expression<String>? matchedClause,
    Expression<String>? extractionVersion,
    Expression<int>? accountId,
    Expression<String>? associationOrigin,
    Expression<int>? associatedMillis,
    Expression<int>? revision,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (amountMinor != null) 'amount_minor': amountMinor,
      if (currency != null) 'currency': currency,
      if (kind != null) 'kind': kind,
      if (subjectFamily != null) 'subject_family': subjectFamily,
      if (origin != null) 'origin': origin,
      if (asOfMillis != null) 'as_of_millis': asOfMillis,
      if (timeBasis != null) 'time_basis': timeBasis,
      if (createdMillis != null) 'created_millis': createdMillis,
      if (financialRecordId != null) 'financial_record_id': financialRecordId,
      if (rawMessageId != null) 'raw_message_id': rawMessageId,
      if (matchedClause != null) 'matched_clause': matchedClause,
      if (extractionVersion != null) 'extraction_version': extractionVersion,
      if (accountId != null) 'account_id': accountId,
      if (associationOrigin != null) 'association_origin': associationOrigin,
      if (associatedMillis != null) 'associated_millis': associatedMillis,
      if (revision != null) 'revision': revision,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BalanceEvidenceCompanion copyWith({
    Value<String>? id,
    Value<int>? amountMinor,
    Value<String>? currency,
    Value<String>? kind,
    Value<String?>? subjectFamily,
    Value<String>? origin,
    Value<int>? asOfMillis,
    Value<String>? timeBasis,
    Value<int>? createdMillis,
    Value<int?>? financialRecordId,
    Value<int?>? rawMessageId,
    Value<String?>? matchedClause,
    Value<String?>? extractionVersion,
    Value<int?>? accountId,
    Value<String?>? associationOrigin,
    Value<int?>? associatedMillis,
    Value<int>? revision,
    Value<int>? rowid,
  }) {
    return BalanceEvidenceCompanion(
      id: id ?? this.id,
      amountMinor: amountMinor ?? this.amountMinor,
      currency: currency ?? this.currency,
      kind: kind ?? this.kind,
      subjectFamily: subjectFamily ?? this.subjectFamily,
      origin: origin ?? this.origin,
      asOfMillis: asOfMillis ?? this.asOfMillis,
      timeBasis: timeBasis ?? this.timeBasis,
      createdMillis: createdMillis ?? this.createdMillis,
      financialRecordId: financialRecordId ?? this.financialRecordId,
      rawMessageId: rawMessageId ?? this.rawMessageId,
      matchedClause: matchedClause ?? this.matchedClause,
      extractionVersion: extractionVersion ?? this.extractionVersion,
      accountId: accountId ?? this.accountId,
      associationOrigin: associationOrigin ?? this.associationOrigin,
      associatedMillis: associatedMillis ?? this.associatedMillis,
      revision: revision ?? this.revision,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (amountMinor.present) {
      map['amount_minor'] = Variable<int>(amountMinor.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (subjectFamily.present) {
      map['subject_family'] = Variable<String>(subjectFamily.value);
    }
    if (origin.present) {
      map['origin'] = Variable<String>(origin.value);
    }
    if (asOfMillis.present) {
      map['as_of_millis'] = Variable<int>(asOfMillis.value);
    }
    if (timeBasis.present) {
      map['time_basis'] = Variable<String>(timeBasis.value);
    }
    if (createdMillis.present) {
      map['created_millis'] = Variable<int>(createdMillis.value);
    }
    if (financialRecordId.present) {
      map['financial_record_id'] = Variable<int>(financialRecordId.value);
    }
    if (rawMessageId.present) {
      map['raw_message_id'] = Variable<int>(rawMessageId.value);
    }
    if (matchedClause.present) {
      map['matched_clause'] = Variable<String>(matchedClause.value);
    }
    if (extractionVersion.present) {
      map['extraction_version'] = Variable<String>(extractionVersion.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<int>(accountId.value);
    }
    if (associationOrigin.present) {
      map['association_origin'] = Variable<String>(associationOrigin.value);
    }
    if (associatedMillis.present) {
      map['associated_millis'] = Variable<int>(associatedMillis.value);
    }
    if (revision.present) {
      map['revision'] = Variable<int>(revision.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BalanceEvidenceCompanion(')
          ..write('id: $id, ')
          ..write('amountMinor: $amountMinor, ')
          ..write('currency: $currency, ')
          ..write('kind: $kind, ')
          ..write('subjectFamily: $subjectFamily, ')
          ..write('origin: $origin, ')
          ..write('asOfMillis: $asOfMillis, ')
          ..write('timeBasis: $timeBasis, ')
          ..write('createdMillis: $createdMillis, ')
          ..write('financialRecordId: $financialRecordId, ')
          ..write('rawMessageId: $rawMessageId, ')
          ..write('matchedClause: $matchedClause, ')
          ..write('extractionVersion: $extractionVersion, ')
          ..write('accountId: $accountId, ')
          ..write('associationOrigin: $associationOrigin, ')
          ..write('associatedMillis: $associatedMillis, ')
          ..write('revision: $revision, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CategoryRulesTable extends CategoryRules
    with TableInfo<$CategoryRulesTable, StoredCategoryRule> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoryRulesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _identityKeyMeta = const VerificationMeta(
    'identityKey',
  );
  @override
  late final GeneratedColumn<String> identityKey = GeneratedColumn<String>(
    'identity_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (kind IN (\'income\', \'expense\'))',
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES transaction_categories (id) ON DELETE CASCADE',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [id, identityKey, kind, categoryId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'category_rules';
  @override
  VerificationContext validateIntegrity(
    Insertable<StoredCategoryRule> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('identity_key')) {
      context.handle(
        _identityKeyMeta,
        identityKey.isAcceptableOrUnknown(
          data['identity_key']!,
          _identityKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_identityKeyMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {identityKey, kind},
  ];
  @override
  StoredCategoryRule map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StoredCategoryRule(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      identityKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}identity_key'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      )!,
    );
  }

  @override
  $CategoryRulesTable createAlias(String alias) {
    return $CategoryRulesTable(attachedDatabase, alias);
  }
}

class StoredCategoryRule extends DataClass
    implements Insertable<StoredCategoryRule> {
  final int id;
  final String identityKey;
  final String kind;
  final String categoryId;
  const StoredCategoryRule({
    required this.id,
    required this.identityKey,
    required this.kind,
    required this.categoryId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['identity_key'] = Variable<String>(identityKey);
    map['kind'] = Variable<String>(kind);
    map['category_id'] = Variable<String>(categoryId);
    return map;
  }

  CategoryRulesCompanion toCompanion(bool nullToAbsent) {
    return CategoryRulesCompanion(
      id: Value(id),
      identityKey: Value(identityKey),
      kind: Value(kind),
      categoryId: Value(categoryId),
    );
  }

  factory StoredCategoryRule.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StoredCategoryRule(
      id: serializer.fromJson<int>(json['id']),
      identityKey: serializer.fromJson<String>(json['identityKey']),
      kind: serializer.fromJson<String>(json['kind']),
      categoryId: serializer.fromJson<String>(json['categoryId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'identityKey': serializer.toJson<String>(identityKey),
      'kind': serializer.toJson<String>(kind),
      'categoryId': serializer.toJson<String>(categoryId),
    };
  }

  StoredCategoryRule copyWith({
    int? id,
    String? identityKey,
    String? kind,
    String? categoryId,
  }) => StoredCategoryRule(
    id: id ?? this.id,
    identityKey: identityKey ?? this.identityKey,
    kind: kind ?? this.kind,
    categoryId: categoryId ?? this.categoryId,
  );
  StoredCategoryRule copyWithCompanion(CategoryRulesCompanion data) {
    return StoredCategoryRule(
      id: data.id.present ? data.id.value : this.id,
      identityKey: data.identityKey.present
          ? data.identityKey.value
          : this.identityKey,
      kind: data.kind.present ? data.kind.value : this.kind,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StoredCategoryRule(')
          ..write('id: $id, ')
          ..write('identityKey: $identityKey, ')
          ..write('kind: $kind, ')
          ..write('categoryId: $categoryId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, identityKey, kind, categoryId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StoredCategoryRule &&
          other.id == this.id &&
          other.identityKey == this.identityKey &&
          other.kind == this.kind &&
          other.categoryId == this.categoryId);
}

class CategoryRulesCompanion extends UpdateCompanion<StoredCategoryRule> {
  final Value<int> id;
  final Value<String> identityKey;
  final Value<String> kind;
  final Value<String> categoryId;
  const CategoryRulesCompanion({
    this.id = const Value.absent(),
    this.identityKey = const Value.absent(),
    this.kind = const Value.absent(),
    this.categoryId = const Value.absent(),
  });
  CategoryRulesCompanion.insert({
    this.id = const Value.absent(),
    required String identityKey,
    required String kind,
    required String categoryId,
  }) : identityKey = Value(identityKey),
       kind = Value(kind),
       categoryId = Value(categoryId);
  static Insertable<StoredCategoryRule> custom({
    Expression<int>? id,
    Expression<String>? identityKey,
    Expression<String>? kind,
    Expression<String>? categoryId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (identityKey != null) 'identity_key': identityKey,
      if (kind != null) 'kind': kind,
      if (categoryId != null) 'category_id': categoryId,
    });
  }

  CategoryRulesCompanion copyWith({
    Value<int>? id,
    Value<String>? identityKey,
    Value<String>? kind,
    Value<String>? categoryId,
  }) {
    return CategoryRulesCompanion(
      id: id ?? this.id,
      identityKey: identityKey ?? this.identityKey,
      kind: kind ?? this.kind,
      categoryId: categoryId ?? this.categoryId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (identityKey.present) {
      map['identity_key'] = Variable<String>(identityKey.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoryRulesCompanion(')
          ..write('id: $id, ')
          ..write('identityKey: $identityKey, ')
          ..write('kind: $kind, ')
          ..write('categoryId: $categoryId')
          ..write(')'))
        .toString();
  }
}

class $RecordCategoryAssignmentsTable extends RecordCategoryAssignments
    with TableInfo<$RecordCategoryAssignmentsTable, StoredCategoryAssignment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecordCategoryAssignmentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _financialRecordIdMeta = const VerificationMeta(
    'financialRecordId',
  );
  @override
  late final GeneratedColumn<int> financialRecordId = GeneratedColumn<int>(
    'financial_record_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES financial_records (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES transaction_categories (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _originMeta = const VerificationMeta('origin');
  @override
  late final GeneratedColumn<String> origin = GeneratedColumn<String>(
    'origin',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (origin IN (\'manual\', \'ruleDerived\', \'manualUncategorized\'))',
  );
  static const VerificationMeta _ruleIdMeta = const VerificationMeta('ruleId');
  @override
  late final GeneratedColumn<int> ruleId = GeneratedColumn<int>(
    'rule_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES category_rules (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _assignedAtMeta = const VerificationMeta(
    'assignedAt',
  );
  @override
  late final GeneratedColumn<DateTime> assignedAt = GeneratedColumn<DateTime>(
    'assigned_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    financialRecordId,
    categoryId,
    origin,
    ruleId,
    assignedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'record_category_assignments';
  @override
  VerificationContext validateIntegrity(
    Insertable<StoredCategoryAssignment> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('financial_record_id')) {
      context.handle(
        _financialRecordIdMeta,
        financialRecordId.isAcceptableOrUnknown(
          data['financial_record_id']!,
          _financialRecordIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_financialRecordIdMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    }
    if (data.containsKey('origin')) {
      context.handle(
        _originMeta,
        origin.isAcceptableOrUnknown(data['origin']!, _originMeta),
      );
    } else if (isInserting) {
      context.missing(_originMeta);
    }
    if (data.containsKey('rule_id')) {
      context.handle(
        _ruleIdMeta,
        ruleId.isAcceptableOrUnknown(data['rule_id']!, _ruleIdMeta),
      );
    }
    if (data.containsKey('assigned_at')) {
      context.handle(
        _assignedAtMeta,
        assignedAt.isAcceptableOrUnknown(data['assigned_at']!, _assignedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {financialRecordId};
  @override
  StoredCategoryAssignment map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StoredCategoryAssignment(
      financialRecordId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}financial_record_id'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      ),
      origin: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}origin'],
      )!,
      ruleId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rule_id'],
      ),
      assignedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}assigned_at'],
      )!,
    );
  }

  @override
  $RecordCategoryAssignmentsTable createAlias(String alias) {
    return $RecordCategoryAssignmentsTable(attachedDatabase, alias);
  }

  @override
  bool get withoutRowId => true;
}

class StoredCategoryAssignment extends DataClass
    implements Insertable<StoredCategoryAssignment> {
  final int financialRecordId;
  final String? categoryId;
  final String origin;
  final int? ruleId;
  final DateTime assignedAt;
  const StoredCategoryAssignment({
    required this.financialRecordId,
    this.categoryId,
    required this.origin,
    this.ruleId,
    required this.assignedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['financial_record_id'] = Variable<int>(financialRecordId);
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<String>(categoryId);
    }
    map['origin'] = Variable<String>(origin);
    if (!nullToAbsent || ruleId != null) {
      map['rule_id'] = Variable<int>(ruleId);
    }
    map['assigned_at'] = Variable<DateTime>(assignedAt);
    return map;
  }

  RecordCategoryAssignmentsCompanion toCompanion(bool nullToAbsent) {
    return RecordCategoryAssignmentsCompanion(
      financialRecordId: Value(financialRecordId),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      origin: Value(origin),
      ruleId: ruleId == null && nullToAbsent
          ? const Value.absent()
          : Value(ruleId),
      assignedAt: Value(assignedAt),
    );
  }

  factory StoredCategoryAssignment.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StoredCategoryAssignment(
      financialRecordId: serializer.fromJson<int>(json['financialRecordId']),
      categoryId: serializer.fromJson<String?>(json['categoryId']),
      origin: serializer.fromJson<String>(json['origin']),
      ruleId: serializer.fromJson<int?>(json['ruleId']),
      assignedAt: serializer.fromJson<DateTime>(json['assignedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'financialRecordId': serializer.toJson<int>(financialRecordId),
      'categoryId': serializer.toJson<String?>(categoryId),
      'origin': serializer.toJson<String>(origin),
      'ruleId': serializer.toJson<int?>(ruleId),
      'assignedAt': serializer.toJson<DateTime>(assignedAt),
    };
  }

  StoredCategoryAssignment copyWith({
    int? financialRecordId,
    Value<String?> categoryId = const Value.absent(),
    String? origin,
    Value<int?> ruleId = const Value.absent(),
    DateTime? assignedAt,
  }) => StoredCategoryAssignment(
    financialRecordId: financialRecordId ?? this.financialRecordId,
    categoryId: categoryId.present ? categoryId.value : this.categoryId,
    origin: origin ?? this.origin,
    ruleId: ruleId.present ? ruleId.value : this.ruleId,
    assignedAt: assignedAt ?? this.assignedAt,
  );
  StoredCategoryAssignment copyWithCompanion(
    RecordCategoryAssignmentsCompanion data,
  ) {
    return StoredCategoryAssignment(
      financialRecordId: data.financialRecordId.present
          ? data.financialRecordId.value
          : this.financialRecordId,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      origin: data.origin.present ? data.origin.value : this.origin,
      ruleId: data.ruleId.present ? data.ruleId.value : this.ruleId,
      assignedAt: data.assignedAt.present
          ? data.assignedAt.value
          : this.assignedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StoredCategoryAssignment(')
          ..write('financialRecordId: $financialRecordId, ')
          ..write('categoryId: $categoryId, ')
          ..write('origin: $origin, ')
          ..write('ruleId: $ruleId, ')
          ..write('assignedAt: $assignedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(financialRecordId, categoryId, origin, ruleId, assignedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StoredCategoryAssignment &&
          other.financialRecordId == this.financialRecordId &&
          other.categoryId == this.categoryId &&
          other.origin == this.origin &&
          other.ruleId == this.ruleId &&
          other.assignedAt == this.assignedAt);
}

class RecordCategoryAssignmentsCompanion
    extends UpdateCompanion<StoredCategoryAssignment> {
  final Value<int> financialRecordId;
  final Value<String?> categoryId;
  final Value<String> origin;
  final Value<int?> ruleId;
  final Value<DateTime> assignedAt;
  const RecordCategoryAssignmentsCompanion({
    this.financialRecordId = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.origin = const Value.absent(),
    this.ruleId = const Value.absent(),
    this.assignedAt = const Value.absent(),
  });
  RecordCategoryAssignmentsCompanion.insert({
    required int financialRecordId,
    this.categoryId = const Value.absent(),
    required String origin,
    this.ruleId = const Value.absent(),
    this.assignedAt = const Value.absent(),
  }) : financialRecordId = Value(financialRecordId),
       origin = Value(origin);
  static Insertable<StoredCategoryAssignment> custom({
    Expression<int>? financialRecordId,
    Expression<String>? categoryId,
    Expression<String>? origin,
    Expression<int>? ruleId,
    Expression<DateTime>? assignedAt,
  }) {
    return RawValuesInsertable({
      if (financialRecordId != null) 'financial_record_id': financialRecordId,
      if (categoryId != null) 'category_id': categoryId,
      if (origin != null) 'origin': origin,
      if (ruleId != null) 'rule_id': ruleId,
      if (assignedAt != null) 'assigned_at': assignedAt,
    });
  }

  RecordCategoryAssignmentsCompanion copyWith({
    Value<int>? financialRecordId,
    Value<String?>? categoryId,
    Value<String>? origin,
    Value<int?>? ruleId,
    Value<DateTime>? assignedAt,
  }) {
    return RecordCategoryAssignmentsCompanion(
      financialRecordId: financialRecordId ?? this.financialRecordId,
      categoryId: categoryId ?? this.categoryId,
      origin: origin ?? this.origin,
      ruleId: ruleId ?? this.ruleId,
      assignedAt: assignedAt ?? this.assignedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (financialRecordId.present) {
      map['financial_record_id'] = Variable<int>(financialRecordId.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (origin.present) {
      map['origin'] = Variable<String>(origin.value);
    }
    if (ruleId.present) {
      map['rule_id'] = Variable<int>(ruleId.value);
    }
    if (assignedAt.present) {
      map['assigned_at'] = Variable<DateTime>(assignedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecordCategoryAssignmentsCompanion(')
          ..write('financialRecordId: $financialRecordId, ')
          ..write('categoryId: $categoryId, ')
          ..write('origin: $origin, ')
          ..write('ruleId: $ruleId, ')
          ..write('assignedAt: $assignedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $AccountsTable accounts = $AccountsTable(this);
  late final $TransactionCategoriesTable transactionCategories =
      $TransactionCategoriesTable(this);
  late final $BudgetsTable budgets = $BudgetsTable(this);
  late final $FinancialRecordsTable financialRecords = $FinancialRecordsTable(
    this,
  );
  late final $RawMessagesTable rawMessages = $RawMessagesTable(this);
  late final $BalanceEvidenceTable balanceEvidence = $BalanceEvidenceTable(
    this,
  );
  late final $CategoryRulesTable categoryRules = $CategoryRulesTable(this);
  late final $RecordCategoryAssignmentsTable recordCategoryAssignments =
      $RecordCategoryAssignmentsTable(this);
  late final Index balanceEvidenceAccountAsofIdx = Index(
    'balance_evidence_account_asof_idx',
    'CREATE INDEX balance_evidence_account_asof_idx ON balance_evidence (account_id, as_of_millis)',
  );
  late final Index financialRecordsReferenceIdx = Index(
    'financial_records_reference_idx',
    'CREATE INDEX financial_records_reference_idx ON financial_records (reference)',
  );
  late final Index rawMessagesSenderBodyIdx = Index(
    'raw_messages_sender_body_idx',
    'CREATE INDEX raw_messages_sender_body_idx ON raw_messages (sender, body)',
  );
  late final Index recordCategoryCategoryIdx = Index(
    'record_category_category_idx',
    'CREATE INDEX record_category_category_idx ON record_category_assignments (category_id)',
  );
  late final AccountsDao accountsDao = AccountsDao(this as AppDatabase);
  late final FinancialRecordsDao financialRecordsDao = FinancialRecordsDao(
    this as AppDatabase,
  );
  late final RawMessagesDao rawMessagesDao = RawMessagesDao(
    this as AppDatabase,
  );
  late final CategoriesDao categoriesDao = CategoriesDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    accounts,
    transactionCategories,
    budgets,
    financialRecords,
    rawMessages,
    balanceEvidence,
    categoryRules,
    recordCategoryAssignments,
    balanceEvidenceAccountAsofIdx,
    financialRecordsReferenceIdx,
    rawMessagesSenderBodyIdx,
    recordCategoryCategoryIdx,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'transaction_categories',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('budgets', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'financial_records',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('balance_evidence', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'raw_messages',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('balance_evidence', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'accounts',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('balance_evidence', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'transaction_categories',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('category_rules', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'financial_records',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [
        TableUpdate('record_category_assignments', kind: UpdateKind.delete),
      ],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'transaction_categories',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [
        TableUpdate('record_category_assignments', kind: UpdateKind.delete),
      ],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'category_rules',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [
        TableUpdate('record_category_assignments', kind: UpdateKind.update),
      ],
    ),
  ]);
}

typedef $$AccountsTableCreateCompanionBuilder =
    AccountsCompanion Function({
      Value<int> id,
      required String uuid,
      required String name,
      required String type,
      Value<String?> institution,
      Value<bool> isActive,
      Value<bool> isUserRegistered,
      Value<String?> identifiers,
      Value<DateTime> createdAt,
    });
typedef $$AccountsTableUpdateCompanionBuilder =
    AccountsCompanion Function({
      Value<int> id,
      Value<String> uuid,
      Value<String> name,
      Value<String> type,
      Value<String?> institution,
      Value<bool> isActive,
      Value<bool> isUserRegistered,
      Value<String?> identifiers,
      Value<DateTime> createdAt,
    });

final class $$AccountsTableReferences
    extends BaseReferences<_$AppDatabase, $AccountsTable, Account> {
  $$AccountsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$BalanceEvidenceTable, List<StoredBalanceEvidence>>
  _balanceEvidenceRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.balanceEvidence,
    aliasName: 'accounts__id__balance_evidence__account_id',
  );

  $$BalanceEvidenceTableProcessedTableManager get balanceEvidenceRefs {
    final manager = $$BalanceEvidenceTableTableManager(
      $_db,
      $_db.balanceEvidence,
    ).filter((f) => f.accountId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _balanceEvidenceRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$AccountsTableFilterComposer
    extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableFilterComposer({
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

  ColumnFilters<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get institution => $composableBuilder(
    column: $table.institution,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isUserRegistered => $composableBuilder(
    column: $table.isUserRegistered,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get identifiers => $composableBuilder(
    column: $table.identifiers,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> balanceEvidenceRefs(
    Expression<bool> Function($$BalanceEvidenceTableFilterComposer f) f,
  ) {
    final $$BalanceEvidenceTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.balanceEvidence,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BalanceEvidenceTableFilterComposer(
            $db: $db,
            $table: $db.balanceEvidence,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AccountsTableOrderingComposer
    extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableOrderingComposer({
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

  ColumnOrderings<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get institution => $composableBuilder(
    column: $table.institution,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isUserRegistered => $composableBuilder(
    column: $table.isUserRegistered,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get identifiers => $composableBuilder(
    column: $table.identifiers,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AccountsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get institution => $composableBuilder(
    column: $table.institution,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<bool> get isUserRegistered => $composableBuilder(
    column: $table.isUserRegistered,
    builder: (column) => column,
  );

  GeneratedColumn<String> get identifiers => $composableBuilder(
    column: $table.identifiers,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> balanceEvidenceRefs<T extends Object>(
    Expression<T> Function($$BalanceEvidenceTableAnnotationComposer a) f,
  ) {
    final $$BalanceEvidenceTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.balanceEvidence,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BalanceEvidenceTableAnnotationComposer(
            $db: $db,
            $table: $db.balanceEvidence,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AccountsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AccountsTable,
          Account,
          $$AccountsTableFilterComposer,
          $$AccountsTableOrderingComposer,
          $$AccountsTableAnnotationComposer,
          $$AccountsTableCreateCompanionBuilder,
          $$AccountsTableUpdateCompanionBuilder,
          (Account, $$AccountsTableReferences),
          Account,
          PrefetchHooks Function({bool balanceEvidenceRefs})
        > {
  $$AccountsTableTableManager(_$AppDatabase db, $AccountsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AccountsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AccountsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AccountsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> uuid = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String?> institution = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<bool> isUserRegistered = const Value.absent(),
                Value<String?> identifiers = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => AccountsCompanion(
                id: id,
                uuid: uuid,
                name: name,
                type: type,
                institution: institution,
                isActive: isActive,
                isUserRegistered: isUserRegistered,
                identifiers: identifiers,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String uuid,
                required String name,
                required String type,
                Value<String?> institution = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<bool> isUserRegistered = const Value.absent(),
                Value<String?> identifiers = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => AccountsCompanion.insert(
                id: id,
                uuid: uuid,
                name: name,
                type: type,
                institution: institution,
                isActive: isActive,
                isUserRegistered: isUserRegistered,
                identifiers: identifiers,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$AccountsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({balanceEvidenceRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (balanceEvidenceRefs) db.balanceEvidence,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (balanceEvidenceRefs)
                    await $_getPrefetchedData<
                      Account,
                      $AccountsTable,
                      StoredBalanceEvidence
                    >(
                      currentTable: table,
                      referencedTable: $$AccountsTableReferences
                          ._balanceEvidenceRefsTable(db),
                      managerFromTypedResult: (p0) => $$AccountsTableReferences(
                        db,
                        table,
                        p0,
                      ).balanceEvidenceRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.accountId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$AccountsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AccountsTable,
      Account,
      $$AccountsTableFilterComposer,
      $$AccountsTableOrderingComposer,
      $$AccountsTableAnnotationComposer,
      $$AccountsTableCreateCompanionBuilder,
      $$AccountsTableUpdateCompanionBuilder,
      (Account, $$AccountsTableReferences),
      Account,
      PrefetchHooks Function({bool balanceEvidenceRefs})
    >;
typedef $$TransactionCategoriesTableCreateCompanionBuilder =
    TransactionCategoriesCompanion Function({
      required String id,
      required String displayName,
      required String kind,
      Value<bool> isBuiltIn,
      Value<bool> isHidden,
      Value<int> rowid,
    });
typedef $$TransactionCategoriesTableUpdateCompanionBuilder =
    TransactionCategoriesCompanion Function({
      Value<String> id,
      Value<String> displayName,
      Value<String> kind,
      Value<bool> isBuiltIn,
      Value<bool> isHidden,
      Value<int> rowid,
    });

final class $$TransactionCategoriesTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $TransactionCategoriesTable,
          StoredCategory
        > {
  $$TransactionCategoriesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$BudgetsTable, List<StoredBudget>>
  _budgetsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.budgets,
    aliasName: 'transaction_categories__id__budgets__category_id',
  );

  $$BudgetsTableProcessedTableManager get budgetsRefs {
    final manager = $$BudgetsTableTableManager(
      $_db,
      $_db.budgets,
    ).filter((f) => f.categoryId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_budgetsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$CategoryRulesTable, List<StoredCategoryRule>>
  _categoryRulesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.categoryRules,
    aliasName: 'transaction_categories__id__category_rules__category_id',
  );

  $$CategoryRulesTableProcessedTableManager get categoryRulesRefs {
    final manager = $$CategoryRulesTableTableManager(
      $_db,
      $_db.categoryRules,
    ).filter((f) => f.categoryId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_categoryRulesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $RecordCategoryAssignmentsTable,
    List<StoredCategoryAssignment>
  >
  _recordCategoryAssignmentsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.recordCategoryAssignments,
    aliasName:
        'transaction_categories__id__record_category_assignments__category_id',
  );

  $$RecordCategoryAssignmentsTableProcessedTableManager
  get recordCategoryAssignmentsRefs {
    final manager = $$RecordCategoryAssignmentsTableTableManager(
      $_db,
      $_db.recordCategoryAssignments,
    ).filter((f) => f.categoryId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _recordCategoryAssignmentsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TransactionCategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $TransactionCategoriesTable> {
  $$TransactionCategoriesTableFilterComposer({
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

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isBuiltIn => $composableBuilder(
    column: $table.isBuiltIn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isHidden => $composableBuilder(
    column: $table.isHidden,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> budgetsRefs(
    Expression<bool> Function($$BudgetsTableFilterComposer f) f,
  ) {
    final $$BudgetsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.budgets,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BudgetsTableFilterComposer(
            $db: $db,
            $table: $db.budgets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> categoryRulesRefs(
    Expression<bool> Function($$CategoryRulesTableFilterComposer f) f,
  ) {
    final $$CategoryRulesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.categoryRules,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoryRulesTableFilterComposer(
            $db: $db,
            $table: $db.categoryRules,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> recordCategoryAssignmentsRefs(
    Expression<bool> Function($$RecordCategoryAssignmentsTableFilterComposer f)
    f,
  ) {
    final $$RecordCategoryAssignmentsTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.recordCategoryAssignments,
          getReferencedColumn: (t) => t.categoryId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$RecordCategoryAssignmentsTableFilterComposer(
                $db: $db,
                $table: $db.recordCategoryAssignments,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$TransactionCategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $TransactionCategoriesTable> {
  $$TransactionCategoriesTableOrderingComposer({
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

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isBuiltIn => $composableBuilder(
    column: $table.isBuiltIn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isHidden => $composableBuilder(
    column: $table.isHidden,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TransactionCategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $TransactionCategoriesTable> {
  $$TransactionCategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<bool> get isBuiltIn =>
      $composableBuilder(column: $table.isBuiltIn, builder: (column) => column);

  GeneratedColumn<bool> get isHidden =>
      $composableBuilder(column: $table.isHidden, builder: (column) => column);

  Expression<T> budgetsRefs<T extends Object>(
    Expression<T> Function($$BudgetsTableAnnotationComposer a) f,
  ) {
    final $$BudgetsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.budgets,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BudgetsTableAnnotationComposer(
            $db: $db,
            $table: $db.budgets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> categoryRulesRefs<T extends Object>(
    Expression<T> Function($$CategoryRulesTableAnnotationComposer a) f,
  ) {
    final $$CategoryRulesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.categoryRules,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoryRulesTableAnnotationComposer(
            $db: $db,
            $table: $db.categoryRules,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> recordCategoryAssignmentsRefs<T extends Object>(
    Expression<T> Function($$RecordCategoryAssignmentsTableAnnotationComposer a)
    f,
  ) {
    final $$RecordCategoryAssignmentsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.recordCategoryAssignments,
          getReferencedColumn: (t) => t.categoryId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$RecordCategoryAssignmentsTableAnnotationComposer(
                $db: $db,
                $table: $db.recordCategoryAssignments,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$TransactionCategoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TransactionCategoriesTable,
          StoredCategory,
          $$TransactionCategoriesTableFilterComposer,
          $$TransactionCategoriesTableOrderingComposer,
          $$TransactionCategoriesTableAnnotationComposer,
          $$TransactionCategoriesTableCreateCompanionBuilder,
          $$TransactionCategoriesTableUpdateCompanionBuilder,
          (StoredCategory, $$TransactionCategoriesTableReferences),
          StoredCategory,
          PrefetchHooks Function({
            bool budgetsRefs,
            bool categoryRulesRefs,
            bool recordCategoryAssignmentsRefs,
          })
        > {
  $$TransactionCategoriesTableTableManager(
    _$AppDatabase db,
    $TransactionCategoriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TransactionCategoriesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$TransactionCategoriesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$TransactionCategoriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<bool> isBuiltIn = const Value.absent(),
                Value<bool> isHidden = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TransactionCategoriesCompanion(
                id: id,
                displayName: displayName,
                kind: kind,
                isBuiltIn: isBuiltIn,
                isHidden: isHidden,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String displayName,
                required String kind,
                Value<bool> isBuiltIn = const Value.absent(),
                Value<bool> isHidden = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TransactionCategoriesCompanion.insert(
                id: id,
                displayName: displayName,
                kind: kind,
                isBuiltIn: isBuiltIn,
                isHidden: isHidden,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$TransactionCategoriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                budgetsRefs = false,
                categoryRulesRefs = false,
                recordCategoryAssignmentsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (budgetsRefs) db.budgets,
                    if (categoryRulesRefs) db.categoryRules,
                    if (recordCategoryAssignmentsRefs)
                      db.recordCategoryAssignments,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (budgetsRefs)
                        await $_getPrefetchedData<
                          StoredCategory,
                          $TransactionCategoriesTable,
                          StoredBudget
                        >(
                          currentTable: table,
                          referencedTable:
                              $$TransactionCategoriesTableReferences
                                  ._budgetsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TransactionCategoriesTableReferences(
                                db,
                                table,
                                p0,
                              ).budgetsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.categoryId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (categoryRulesRefs)
                        await $_getPrefetchedData<
                          StoredCategory,
                          $TransactionCategoriesTable,
                          StoredCategoryRule
                        >(
                          currentTable: table,
                          referencedTable:
                              $$TransactionCategoriesTableReferences
                                  ._categoryRulesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TransactionCategoriesTableReferences(
                                db,
                                table,
                                p0,
                              ).categoryRulesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.categoryId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (recordCategoryAssignmentsRefs)
                        await $_getPrefetchedData<
                          StoredCategory,
                          $TransactionCategoriesTable,
                          StoredCategoryAssignment
                        >(
                          currentTable: table,
                          referencedTable:
                              $$TransactionCategoriesTableReferences
                                  ._recordCategoryAssignmentsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TransactionCategoriesTableReferences(
                                db,
                                table,
                                p0,
                              ).recordCategoryAssignmentsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.categoryId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$TransactionCategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TransactionCategoriesTable,
      StoredCategory,
      $$TransactionCategoriesTableFilterComposer,
      $$TransactionCategoriesTableOrderingComposer,
      $$TransactionCategoriesTableAnnotationComposer,
      $$TransactionCategoriesTableCreateCompanionBuilder,
      $$TransactionCategoriesTableUpdateCompanionBuilder,
      (StoredCategory, $$TransactionCategoriesTableReferences),
      StoredCategory,
      PrefetchHooks Function({
        bool budgetsRefs,
        bool categoryRulesRefs,
        bool recordCategoryAssignmentsRefs,
      })
    >;
typedef $$BudgetsTableCreateCompanionBuilder =
    BudgetsCompanion Function({
      required String id,
      required String scope,
      Value<String?> categoryId,
      required int amountMinor,
      Value<bool> isActive,
      Value<int> rowid,
    });
typedef $$BudgetsTableUpdateCompanionBuilder =
    BudgetsCompanion Function({
      Value<String> id,
      Value<String> scope,
      Value<String?> categoryId,
      Value<int> amountMinor,
      Value<bool> isActive,
      Value<int> rowid,
    });

final class $$BudgetsTableReferences
    extends BaseReferences<_$AppDatabase, $BudgetsTable, StoredBudget> {
  $$BudgetsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TransactionCategoriesTable _categoryIdTable(_$AppDatabase db) => db
      .transactionCategories
      .createAlias('budgets__category_id__transaction_categories__id');

  $$TransactionCategoriesTableProcessedTableManager? get categoryId {
    final $_column = $_itemColumn<String>('category_id');
    if ($_column == null) return null;
    final manager = $$TransactionCategoriesTableTableManager(
      $_db,
      $_db.transactionCategories,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_categoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$BudgetsTableFilterComposer
    extends Composer<_$AppDatabase, $BudgetsTable> {
  $$BudgetsTableFilterComposer({
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

  ColumnFilters<String> get scope => $composableBuilder(
    column: $table.scope,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  $$TransactionCategoriesTableFilterComposer get categoryId {
    final $$TransactionCategoriesTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.categoryId,
          referencedTable: $db.transactionCategories,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$TransactionCategoriesTableFilterComposer(
                $db: $db,
                $table: $db.transactionCategories,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$BudgetsTableOrderingComposer
    extends Composer<_$AppDatabase, $BudgetsTable> {
  $$BudgetsTableOrderingComposer({
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

  ColumnOrderings<String> get scope => $composableBuilder(
    column: $table.scope,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  $$TransactionCategoriesTableOrderingComposer get categoryId {
    final $$TransactionCategoriesTableOrderingComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.categoryId,
          referencedTable: $db.transactionCategories,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$TransactionCategoriesTableOrderingComposer(
                $db: $db,
                $table: $db.transactionCategories,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$BudgetsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BudgetsTable> {
  $$BudgetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get scope =>
      $composableBuilder(column: $table.scope, builder: (column) => column);

  GeneratedColumn<int> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  $$TransactionCategoriesTableAnnotationComposer get categoryId {
    final $$TransactionCategoriesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.categoryId,
          referencedTable: $db.transactionCategories,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$TransactionCategoriesTableAnnotationComposer(
                $db: $db,
                $table: $db.transactionCategories,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$BudgetsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BudgetsTable,
          StoredBudget,
          $$BudgetsTableFilterComposer,
          $$BudgetsTableOrderingComposer,
          $$BudgetsTableAnnotationComposer,
          $$BudgetsTableCreateCompanionBuilder,
          $$BudgetsTableUpdateCompanionBuilder,
          (StoredBudget, $$BudgetsTableReferences),
          StoredBudget,
          PrefetchHooks Function({bool categoryId})
        > {
  $$BudgetsTableTableManager(_$AppDatabase db, $BudgetsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BudgetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BudgetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BudgetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> scope = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                Value<int> amountMinor = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BudgetsCompanion(
                id: id,
                scope: scope,
                categoryId: categoryId,
                amountMinor: amountMinor,
                isActive: isActive,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String scope,
                Value<String?> categoryId = const Value.absent(),
                required int amountMinor,
                Value<bool> isActive = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BudgetsCompanion.insert(
                id: id,
                scope: scope,
                categoryId: categoryId,
                amountMinor: amountMinor,
                isActive: isActive,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$BudgetsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({categoryId = false}) {
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
                    if (categoryId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.categoryId,
                                referencedTable: $$BudgetsTableReferences
                                    ._categoryIdTable(db),
                                referencedColumn: $$BudgetsTableReferences
                                    ._categoryIdTable(db)
                                    .id,
                              )
                              as T;
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

typedef $$BudgetsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BudgetsTable,
      StoredBudget,
      $$BudgetsTableFilterComposer,
      $$BudgetsTableOrderingComposer,
      $$BudgetsTableAnnotationComposer,
      $$BudgetsTableCreateCompanionBuilder,
      $$BudgetsTableUpdateCompanionBuilder,
      (StoredBudget, $$BudgetsTableReferences),
      StoredBudget,
      PrefetchHooks Function({bool categoryId})
    >;
typedef $$FinancialRecordsTableCreateCompanionBuilder =
    FinancialRecordsCompanion Function({
      Value<int> id,
      Value<int?> reversesRecordId,
      required String reference,
      Value<String?> sourceMessageId,
      Value<DateTime?> transactionDate,
      required DateTime receivedAt,
      required double amount,
      Value<double?> balance,
      Value<double?> transactionCost,
      required String type,
      required String subtype,
      Value<String?> interpretedType,
      Value<String?> interpretedSubtype,
      Value<int?> interpretationMappingId,
      required String status,
      required String title,
      required String rawMessage,
      Value<int?> sourceAccountId,
      Value<int?> destinationAccountId,
      Value<String?> partyName,
      Value<String?> partyType,
      Value<String?> partyPhone,
      Value<String?> partyAccount,
      Value<String?> partyIdentifier,
      Value<DateTime> createdAt,
    });
typedef $$FinancialRecordsTableUpdateCompanionBuilder =
    FinancialRecordsCompanion Function({
      Value<int> id,
      Value<int?> reversesRecordId,
      Value<String> reference,
      Value<String?> sourceMessageId,
      Value<DateTime?> transactionDate,
      Value<DateTime> receivedAt,
      Value<double> amount,
      Value<double?> balance,
      Value<double?> transactionCost,
      Value<String> type,
      Value<String> subtype,
      Value<String?> interpretedType,
      Value<String?> interpretedSubtype,
      Value<int?> interpretationMappingId,
      Value<String> status,
      Value<String> title,
      Value<String> rawMessage,
      Value<int?> sourceAccountId,
      Value<int?> destinationAccountId,
      Value<String?> partyName,
      Value<String?> partyType,
      Value<String?> partyPhone,
      Value<String?> partyAccount,
      Value<String?> partyIdentifier,
      Value<DateTime> createdAt,
    });

final class $$FinancialRecordsTableReferences
    extends
        BaseReferences<_$AppDatabase, $FinancialRecordsTable, FinancialRecord> {
  $$FinancialRecordsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $FinancialRecordsTable _reversesRecordIdTable(_$AppDatabase db) =>
      db.financialRecords.createAlias(
        'financial_records__reverses_record_id__financial_records__id',
      );

  $$FinancialRecordsTableProcessedTableManager? get reversesRecordId {
    final $_column = $_itemColumn<int>('reverses_record_id');
    if ($_column == null) return null;
    final manager = $$FinancialRecordsTableTableManager(
      $_db,
      $_db.financialRecords,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_reversesRecordIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$BalanceEvidenceTable, List<StoredBalanceEvidence>>
  _balanceEvidenceRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.balanceEvidence,
    aliasName: 'financial_records__id__balance_evidence__financial_record_id',
  );

  $$BalanceEvidenceTableProcessedTableManager get balanceEvidenceRefs {
    final manager = $$BalanceEvidenceTableTableManager(
      $_db,
      $_db.balanceEvidence,
    ).filter((f) => f.financialRecordId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _balanceEvidenceRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $RecordCategoryAssignmentsTable,
    List<StoredCategoryAssignment>
  >
  _recordCategoryAssignmentsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.recordCategoryAssignments,
    aliasName:
        'financial_records__id__record_category_assignments__financial_record_id',
  );

  $$RecordCategoryAssignmentsTableProcessedTableManager
  get recordCategoryAssignmentsRefs {
    final manager = $$RecordCategoryAssignmentsTableTableManager(
      $_db,
      $_db.recordCategoryAssignments,
    ).filter((f) => f.financialRecordId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _recordCategoryAssignmentsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$FinancialRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $FinancialRecordsTable> {
  $$FinancialRecordsTableFilterComposer({
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

  ColumnFilters<String> get reference => $composableBuilder(
    column: $table.reference,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceMessageId => $composableBuilder(
    column: $table.sourceMessageId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get transactionDate => $composableBuilder(
    column: $table.transactionDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get receivedAt => $composableBuilder(
    column: $table.receivedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get balance => $composableBuilder(
    column: $table.balance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get transactionCost => $composableBuilder(
    column: $table.transactionCost,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subtype => $composableBuilder(
    column: $table.subtype,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get interpretedType => $composableBuilder(
    column: $table.interpretedType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get interpretedSubtype => $composableBuilder(
    column: $table.interpretedSubtype,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get interpretationMappingId => $composableBuilder(
    column: $table.interpretationMappingId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rawMessage => $composableBuilder(
    column: $table.rawMessage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sourceAccountId => $composableBuilder(
    column: $table.sourceAccountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get destinationAccountId => $composableBuilder(
    column: $table.destinationAccountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get partyName => $composableBuilder(
    column: $table.partyName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get partyType => $composableBuilder(
    column: $table.partyType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get partyPhone => $composableBuilder(
    column: $table.partyPhone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get partyAccount => $composableBuilder(
    column: $table.partyAccount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get partyIdentifier => $composableBuilder(
    column: $table.partyIdentifier,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$FinancialRecordsTableFilterComposer get reversesRecordId {
    final $$FinancialRecordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.reversesRecordId,
      referencedTable: $db.financialRecords,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FinancialRecordsTableFilterComposer(
            $db: $db,
            $table: $db.financialRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> balanceEvidenceRefs(
    Expression<bool> Function($$BalanceEvidenceTableFilterComposer f) f,
  ) {
    final $$BalanceEvidenceTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.balanceEvidence,
      getReferencedColumn: (t) => t.financialRecordId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BalanceEvidenceTableFilterComposer(
            $db: $db,
            $table: $db.balanceEvidence,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> recordCategoryAssignmentsRefs(
    Expression<bool> Function($$RecordCategoryAssignmentsTableFilterComposer f)
    f,
  ) {
    final $$RecordCategoryAssignmentsTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.recordCategoryAssignments,
          getReferencedColumn: (t) => t.financialRecordId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$RecordCategoryAssignmentsTableFilterComposer(
                $db: $db,
                $table: $db.recordCategoryAssignments,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$FinancialRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $FinancialRecordsTable> {
  $$FinancialRecordsTableOrderingComposer({
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

  ColumnOrderings<String> get reference => $composableBuilder(
    column: $table.reference,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceMessageId => $composableBuilder(
    column: $table.sourceMessageId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get transactionDate => $composableBuilder(
    column: $table.transactionDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get receivedAt => $composableBuilder(
    column: $table.receivedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get balance => $composableBuilder(
    column: $table.balance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get transactionCost => $composableBuilder(
    column: $table.transactionCost,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subtype => $composableBuilder(
    column: $table.subtype,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get interpretedType => $composableBuilder(
    column: $table.interpretedType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get interpretedSubtype => $composableBuilder(
    column: $table.interpretedSubtype,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get interpretationMappingId => $composableBuilder(
    column: $table.interpretationMappingId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rawMessage => $composableBuilder(
    column: $table.rawMessage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sourceAccountId => $composableBuilder(
    column: $table.sourceAccountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get destinationAccountId => $composableBuilder(
    column: $table.destinationAccountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get partyName => $composableBuilder(
    column: $table.partyName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get partyType => $composableBuilder(
    column: $table.partyType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get partyPhone => $composableBuilder(
    column: $table.partyPhone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get partyAccount => $composableBuilder(
    column: $table.partyAccount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get partyIdentifier => $composableBuilder(
    column: $table.partyIdentifier,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$FinancialRecordsTableOrderingComposer get reversesRecordId {
    final $$FinancialRecordsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.reversesRecordId,
      referencedTable: $db.financialRecords,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FinancialRecordsTableOrderingComposer(
            $db: $db,
            $table: $db.financialRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FinancialRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FinancialRecordsTable> {
  $$FinancialRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get reference =>
      $composableBuilder(column: $table.reference, builder: (column) => column);

  GeneratedColumn<String> get sourceMessageId => $composableBuilder(
    column: $table.sourceMessageId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get transactionDate => $composableBuilder(
    column: $table.transactionDate,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get receivedAt => $composableBuilder(
    column: $table.receivedAt,
    builder: (column) => column,
  );

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<double> get balance =>
      $composableBuilder(column: $table.balance, builder: (column) => column);

  GeneratedColumn<double> get transactionCost => $composableBuilder(
    column: $table.transactionCost,
    builder: (column) => column,
  );

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get subtype =>
      $composableBuilder(column: $table.subtype, builder: (column) => column);

  GeneratedColumn<String> get interpretedType => $composableBuilder(
    column: $table.interpretedType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get interpretedSubtype => $composableBuilder(
    column: $table.interpretedSubtype,
    builder: (column) => column,
  );

  GeneratedColumn<int> get interpretationMappingId => $composableBuilder(
    column: $table.interpretationMappingId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get rawMessage => $composableBuilder(
    column: $table.rawMessage,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sourceAccountId => $composableBuilder(
    column: $table.sourceAccountId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get destinationAccountId => $composableBuilder(
    column: $table.destinationAccountId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get partyName =>
      $composableBuilder(column: $table.partyName, builder: (column) => column);

  GeneratedColumn<String> get partyType =>
      $composableBuilder(column: $table.partyType, builder: (column) => column);

  GeneratedColumn<String> get partyPhone => $composableBuilder(
    column: $table.partyPhone,
    builder: (column) => column,
  );

  GeneratedColumn<String> get partyAccount => $composableBuilder(
    column: $table.partyAccount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get partyIdentifier => $composableBuilder(
    column: $table.partyIdentifier,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$FinancialRecordsTableAnnotationComposer get reversesRecordId {
    final $$FinancialRecordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.reversesRecordId,
      referencedTable: $db.financialRecords,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FinancialRecordsTableAnnotationComposer(
            $db: $db,
            $table: $db.financialRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> balanceEvidenceRefs<T extends Object>(
    Expression<T> Function($$BalanceEvidenceTableAnnotationComposer a) f,
  ) {
    final $$BalanceEvidenceTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.balanceEvidence,
      getReferencedColumn: (t) => t.financialRecordId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BalanceEvidenceTableAnnotationComposer(
            $db: $db,
            $table: $db.balanceEvidence,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> recordCategoryAssignmentsRefs<T extends Object>(
    Expression<T> Function($$RecordCategoryAssignmentsTableAnnotationComposer a)
    f,
  ) {
    final $$RecordCategoryAssignmentsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.recordCategoryAssignments,
          getReferencedColumn: (t) => t.financialRecordId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$RecordCategoryAssignmentsTableAnnotationComposer(
                $db: $db,
                $table: $db.recordCategoryAssignments,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$FinancialRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FinancialRecordsTable,
          FinancialRecord,
          $$FinancialRecordsTableFilterComposer,
          $$FinancialRecordsTableOrderingComposer,
          $$FinancialRecordsTableAnnotationComposer,
          $$FinancialRecordsTableCreateCompanionBuilder,
          $$FinancialRecordsTableUpdateCompanionBuilder,
          (FinancialRecord, $$FinancialRecordsTableReferences),
          FinancialRecord,
          PrefetchHooks Function({
            bool reversesRecordId,
            bool balanceEvidenceRefs,
            bool recordCategoryAssignmentsRefs,
          })
        > {
  $$FinancialRecordsTableTableManager(
    _$AppDatabase db,
    $FinancialRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FinancialRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FinancialRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FinancialRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> reversesRecordId = const Value.absent(),
                Value<String> reference = const Value.absent(),
                Value<String?> sourceMessageId = const Value.absent(),
                Value<DateTime?> transactionDate = const Value.absent(),
                Value<DateTime> receivedAt = const Value.absent(),
                Value<double> amount = const Value.absent(),
                Value<double?> balance = const Value.absent(),
                Value<double?> transactionCost = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> subtype = const Value.absent(),
                Value<String?> interpretedType = const Value.absent(),
                Value<String?> interpretedSubtype = const Value.absent(),
                Value<int?> interpretationMappingId = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> rawMessage = const Value.absent(),
                Value<int?> sourceAccountId = const Value.absent(),
                Value<int?> destinationAccountId = const Value.absent(),
                Value<String?> partyName = const Value.absent(),
                Value<String?> partyType = const Value.absent(),
                Value<String?> partyPhone = const Value.absent(),
                Value<String?> partyAccount = const Value.absent(),
                Value<String?> partyIdentifier = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => FinancialRecordsCompanion(
                id: id,
                reversesRecordId: reversesRecordId,
                reference: reference,
                sourceMessageId: sourceMessageId,
                transactionDate: transactionDate,
                receivedAt: receivedAt,
                amount: amount,
                balance: balance,
                transactionCost: transactionCost,
                type: type,
                subtype: subtype,
                interpretedType: interpretedType,
                interpretedSubtype: interpretedSubtype,
                interpretationMappingId: interpretationMappingId,
                status: status,
                title: title,
                rawMessage: rawMessage,
                sourceAccountId: sourceAccountId,
                destinationAccountId: destinationAccountId,
                partyName: partyName,
                partyType: partyType,
                partyPhone: partyPhone,
                partyAccount: partyAccount,
                partyIdentifier: partyIdentifier,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> reversesRecordId = const Value.absent(),
                required String reference,
                Value<String?> sourceMessageId = const Value.absent(),
                Value<DateTime?> transactionDate = const Value.absent(),
                required DateTime receivedAt,
                required double amount,
                Value<double?> balance = const Value.absent(),
                Value<double?> transactionCost = const Value.absent(),
                required String type,
                required String subtype,
                Value<String?> interpretedType = const Value.absent(),
                Value<String?> interpretedSubtype = const Value.absent(),
                Value<int?> interpretationMappingId = const Value.absent(),
                required String status,
                required String title,
                required String rawMessage,
                Value<int?> sourceAccountId = const Value.absent(),
                Value<int?> destinationAccountId = const Value.absent(),
                Value<String?> partyName = const Value.absent(),
                Value<String?> partyType = const Value.absent(),
                Value<String?> partyPhone = const Value.absent(),
                Value<String?> partyAccount = const Value.absent(),
                Value<String?> partyIdentifier = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => FinancialRecordsCompanion.insert(
                id: id,
                reversesRecordId: reversesRecordId,
                reference: reference,
                sourceMessageId: sourceMessageId,
                transactionDate: transactionDate,
                receivedAt: receivedAt,
                amount: amount,
                balance: balance,
                transactionCost: transactionCost,
                type: type,
                subtype: subtype,
                interpretedType: interpretedType,
                interpretedSubtype: interpretedSubtype,
                interpretationMappingId: interpretationMappingId,
                status: status,
                title: title,
                rawMessage: rawMessage,
                sourceAccountId: sourceAccountId,
                destinationAccountId: destinationAccountId,
                partyName: partyName,
                partyType: partyType,
                partyPhone: partyPhone,
                partyAccount: partyAccount,
                partyIdentifier: partyIdentifier,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$FinancialRecordsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                reversesRecordId = false,
                balanceEvidenceRefs = false,
                recordCategoryAssignmentsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (balanceEvidenceRefs) db.balanceEvidence,
                    if (recordCategoryAssignmentsRefs)
                      db.recordCategoryAssignments,
                  ],
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
                        if (reversesRecordId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.reversesRecordId,
                                    referencedTable:
                                        $$FinancialRecordsTableReferences
                                            ._reversesRecordIdTable(db),
                                    referencedColumn:
                                        $$FinancialRecordsTableReferences
                                            ._reversesRecordIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (balanceEvidenceRefs)
                        await $_getPrefetchedData<
                          FinancialRecord,
                          $FinancialRecordsTable,
                          StoredBalanceEvidence
                        >(
                          currentTable: table,
                          referencedTable: $$FinancialRecordsTableReferences
                              ._balanceEvidenceRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$FinancialRecordsTableReferences(
                                db,
                                table,
                                p0,
                              ).balanceEvidenceRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.financialRecordId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (recordCategoryAssignmentsRefs)
                        await $_getPrefetchedData<
                          FinancialRecord,
                          $FinancialRecordsTable,
                          StoredCategoryAssignment
                        >(
                          currentTable: table,
                          referencedTable: $$FinancialRecordsTableReferences
                              ._recordCategoryAssignmentsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$FinancialRecordsTableReferences(
                                db,
                                table,
                                p0,
                              ).recordCategoryAssignmentsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.financialRecordId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$FinancialRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FinancialRecordsTable,
      FinancialRecord,
      $$FinancialRecordsTableFilterComposer,
      $$FinancialRecordsTableOrderingComposer,
      $$FinancialRecordsTableAnnotationComposer,
      $$FinancialRecordsTableCreateCompanionBuilder,
      $$FinancialRecordsTableUpdateCompanionBuilder,
      (FinancialRecord, $$FinancialRecordsTableReferences),
      FinancialRecord,
      PrefetchHooks Function({
        bool reversesRecordId,
        bool balanceEvidenceRefs,
        bool recordCategoryAssignmentsRefs,
      })
    >;
typedef $$RawMessagesTableCreateCompanionBuilder =
    RawMessagesCompanion Function({
      Value<int> id,
      required String sourceId,
      required String sender,
      required String body,
      required DateTime receivedAt,
      Value<DateTime> createdAt,
    });
typedef $$RawMessagesTableUpdateCompanionBuilder =
    RawMessagesCompanion Function({
      Value<int> id,
      Value<String> sourceId,
      Value<String> sender,
      Value<String> body,
      Value<DateTime> receivedAt,
      Value<DateTime> createdAt,
    });

final class $$RawMessagesTableReferences
    extends BaseReferences<_$AppDatabase, $RawMessagesTable, RawMessage> {
  $$RawMessagesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$BalanceEvidenceTable, List<StoredBalanceEvidence>>
  _balanceEvidenceRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.balanceEvidence,
    aliasName: 'raw_messages__id__balance_evidence__raw_message_id',
  );

  $$BalanceEvidenceTableProcessedTableManager get balanceEvidenceRefs {
    final manager = $$BalanceEvidenceTableTableManager(
      $_db,
      $_db.balanceEvidence,
    ).filter((f) => f.rawMessageId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _balanceEvidenceRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$RawMessagesTableFilterComposer
    extends Composer<_$AppDatabase, $RawMessagesTable> {
  $$RawMessagesTableFilterComposer({
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

  ColumnFilters<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sender => $composableBuilder(
    column: $table.sender,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get receivedAt => $composableBuilder(
    column: $table.receivedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> balanceEvidenceRefs(
    Expression<bool> Function($$BalanceEvidenceTableFilterComposer f) f,
  ) {
    final $$BalanceEvidenceTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.balanceEvidence,
      getReferencedColumn: (t) => t.rawMessageId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BalanceEvidenceTableFilterComposer(
            $db: $db,
            $table: $db.balanceEvidence,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RawMessagesTableOrderingComposer
    extends Composer<_$AppDatabase, $RawMessagesTable> {
  $$RawMessagesTableOrderingComposer({
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

  ColumnOrderings<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sender => $composableBuilder(
    column: $table.sender,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get receivedAt => $composableBuilder(
    column: $table.receivedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RawMessagesTableAnnotationComposer
    extends Composer<_$AppDatabase, $RawMessagesTable> {
  $$RawMessagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sourceId =>
      $composableBuilder(column: $table.sourceId, builder: (column) => column);

  GeneratedColumn<String> get sender =>
      $composableBuilder(column: $table.sender, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<DateTime> get receivedAt => $composableBuilder(
    column: $table.receivedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> balanceEvidenceRefs<T extends Object>(
    Expression<T> Function($$BalanceEvidenceTableAnnotationComposer a) f,
  ) {
    final $$BalanceEvidenceTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.balanceEvidence,
      getReferencedColumn: (t) => t.rawMessageId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BalanceEvidenceTableAnnotationComposer(
            $db: $db,
            $table: $db.balanceEvidence,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RawMessagesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RawMessagesTable,
          RawMessage,
          $$RawMessagesTableFilterComposer,
          $$RawMessagesTableOrderingComposer,
          $$RawMessagesTableAnnotationComposer,
          $$RawMessagesTableCreateCompanionBuilder,
          $$RawMessagesTableUpdateCompanionBuilder,
          (RawMessage, $$RawMessagesTableReferences),
          RawMessage,
          PrefetchHooks Function({bool balanceEvidenceRefs})
        > {
  $$RawMessagesTableTableManager(_$AppDatabase db, $RawMessagesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RawMessagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RawMessagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RawMessagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> sourceId = const Value.absent(),
                Value<String> sender = const Value.absent(),
                Value<String> body = const Value.absent(),
                Value<DateTime> receivedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => RawMessagesCompanion(
                id: id,
                sourceId: sourceId,
                sender: sender,
                body: body,
                receivedAt: receivedAt,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String sourceId,
                required String sender,
                required String body,
                required DateTime receivedAt,
                Value<DateTime> createdAt = const Value.absent(),
              }) => RawMessagesCompanion.insert(
                id: id,
                sourceId: sourceId,
                sender: sender,
                body: body,
                receivedAt: receivedAt,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$RawMessagesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({balanceEvidenceRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (balanceEvidenceRefs) db.balanceEvidence,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (balanceEvidenceRefs)
                    await $_getPrefetchedData<
                      RawMessage,
                      $RawMessagesTable,
                      StoredBalanceEvidence
                    >(
                      currentTable: table,
                      referencedTable: $$RawMessagesTableReferences
                          ._balanceEvidenceRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$RawMessagesTableReferences(
                            db,
                            table,
                            p0,
                          ).balanceEvidenceRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.rawMessageId == item.id,
                          ),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$RawMessagesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RawMessagesTable,
      RawMessage,
      $$RawMessagesTableFilterComposer,
      $$RawMessagesTableOrderingComposer,
      $$RawMessagesTableAnnotationComposer,
      $$RawMessagesTableCreateCompanionBuilder,
      $$RawMessagesTableUpdateCompanionBuilder,
      (RawMessage, $$RawMessagesTableReferences),
      RawMessage,
      PrefetchHooks Function({bool balanceEvidenceRefs})
    >;
typedef $$BalanceEvidenceTableCreateCompanionBuilder =
    BalanceEvidenceCompanion Function({
      required String id,
      required int amountMinor,
      required String currency,
      required String kind,
      Value<String?> subjectFamily,
      required String origin,
      required int asOfMillis,
      required String timeBasis,
      required int createdMillis,
      Value<int?> financialRecordId,
      Value<int?> rawMessageId,
      Value<String?> matchedClause,
      Value<String?> extractionVersion,
      Value<int?> accountId,
      Value<String?> associationOrigin,
      Value<int?> associatedMillis,
      Value<int> revision,
      Value<int> rowid,
    });
typedef $$BalanceEvidenceTableUpdateCompanionBuilder =
    BalanceEvidenceCompanion Function({
      Value<String> id,
      Value<int> amountMinor,
      Value<String> currency,
      Value<String> kind,
      Value<String?> subjectFamily,
      Value<String> origin,
      Value<int> asOfMillis,
      Value<String> timeBasis,
      Value<int> createdMillis,
      Value<int?> financialRecordId,
      Value<int?> rawMessageId,
      Value<String?> matchedClause,
      Value<String?> extractionVersion,
      Value<int?> accountId,
      Value<String?> associationOrigin,
      Value<int?> associatedMillis,
      Value<int> revision,
      Value<int> rowid,
    });

final class $$BalanceEvidenceTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $BalanceEvidenceTable,
          StoredBalanceEvidence
        > {
  $$BalanceEvidenceTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $FinancialRecordsTable _financialRecordIdTable(_$AppDatabase db) =>
      db.financialRecords.createAlias(
        'balance_evidence__financial_record_id__financial_records__id',
      );

  $$FinancialRecordsTableProcessedTableManager? get financialRecordId {
    final $_column = $_itemColumn<int>('financial_record_id');
    if ($_column == null) return null;
    final manager = $$FinancialRecordsTableTableManager(
      $_db,
      $_db.financialRecords,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_financialRecordIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $RawMessagesTable _rawMessageIdTable(_$AppDatabase db) => db
      .rawMessages
      .createAlias('balance_evidence__raw_message_id__raw_messages__id');

  $$RawMessagesTableProcessedTableManager? get rawMessageId {
    final $_column = $_itemColumn<int>('raw_message_id');
    if ($_column == null) return null;
    final manager = $$RawMessagesTableTableManager(
      $_db,
      $_db.rawMessages,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_rawMessageIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $AccountsTable _accountIdTable(_$AppDatabase db) =>
      db.accounts.createAlias('balance_evidence__account_id__accounts__id');

  $$AccountsTableProcessedTableManager? get accountId {
    final $_column = $_itemColumn<int>('account_id');
    if ($_column == null) return null;
    final manager = $$AccountsTableTableManager(
      $_db,
      $_db.accounts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_accountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$BalanceEvidenceTableFilterComposer
    extends Composer<_$AppDatabase, $BalanceEvidenceTable> {
  $$BalanceEvidenceTableFilterComposer({
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

  ColumnFilters<int> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subjectFamily => $composableBuilder(
    column: $table.subjectFamily,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get origin => $composableBuilder(
    column: $table.origin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get asOfMillis => $composableBuilder(
    column: $table.asOfMillis,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get timeBasis => $composableBuilder(
    column: $table.timeBasis,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdMillis => $composableBuilder(
    column: $table.createdMillis,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get matchedClause => $composableBuilder(
    column: $table.matchedClause,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get extractionVersion => $composableBuilder(
    column: $table.extractionVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get associationOrigin => $composableBuilder(
    column: $table.associationOrigin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get associatedMillis => $composableBuilder(
    column: $table.associatedMillis,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnFilters(column),
  );

  $$FinancialRecordsTableFilterComposer get financialRecordId {
    final $$FinancialRecordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.financialRecordId,
      referencedTable: $db.financialRecords,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FinancialRecordsTableFilterComposer(
            $db: $db,
            $table: $db.financialRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$RawMessagesTableFilterComposer get rawMessageId {
    final $$RawMessagesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.rawMessageId,
      referencedTable: $db.rawMessages,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RawMessagesTableFilterComposer(
            $db: $db,
            $table: $db.rawMessages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AccountsTableFilterComposer get accountId {
    final $$AccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableFilterComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BalanceEvidenceTableOrderingComposer
    extends Composer<_$AppDatabase, $BalanceEvidenceTable> {
  $$BalanceEvidenceTableOrderingComposer({
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

  ColumnOrderings<int> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subjectFamily => $composableBuilder(
    column: $table.subjectFamily,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get origin => $composableBuilder(
    column: $table.origin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get asOfMillis => $composableBuilder(
    column: $table.asOfMillis,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get timeBasis => $composableBuilder(
    column: $table.timeBasis,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdMillis => $composableBuilder(
    column: $table.createdMillis,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get matchedClause => $composableBuilder(
    column: $table.matchedClause,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get extractionVersion => $composableBuilder(
    column: $table.extractionVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get associationOrigin => $composableBuilder(
    column: $table.associationOrigin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get associatedMillis => $composableBuilder(
    column: $table.associatedMillis,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnOrderings(column),
  );

  $$FinancialRecordsTableOrderingComposer get financialRecordId {
    final $$FinancialRecordsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.financialRecordId,
      referencedTable: $db.financialRecords,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FinancialRecordsTableOrderingComposer(
            $db: $db,
            $table: $db.financialRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$RawMessagesTableOrderingComposer get rawMessageId {
    final $$RawMessagesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.rawMessageId,
      referencedTable: $db.rawMessages,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RawMessagesTableOrderingComposer(
            $db: $db,
            $table: $db.rawMessages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AccountsTableOrderingComposer get accountId {
    final $$AccountsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableOrderingComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BalanceEvidenceTableAnnotationComposer
    extends Composer<_$AppDatabase, $BalanceEvidenceTable> {
  $$BalanceEvidenceTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => column,
  );

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get subjectFamily => $composableBuilder(
    column: $table.subjectFamily,
    builder: (column) => column,
  );

  GeneratedColumn<String> get origin =>
      $composableBuilder(column: $table.origin, builder: (column) => column);

  GeneratedColumn<int> get asOfMillis => $composableBuilder(
    column: $table.asOfMillis,
    builder: (column) => column,
  );

  GeneratedColumn<String> get timeBasis =>
      $composableBuilder(column: $table.timeBasis, builder: (column) => column);

  GeneratedColumn<int> get createdMillis => $composableBuilder(
    column: $table.createdMillis,
    builder: (column) => column,
  );

  GeneratedColumn<String> get matchedClause => $composableBuilder(
    column: $table.matchedClause,
    builder: (column) => column,
  );

  GeneratedColumn<String> get extractionVersion => $composableBuilder(
    column: $table.extractionVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get associationOrigin => $composableBuilder(
    column: $table.associationOrigin,
    builder: (column) => column,
  );

  GeneratedColumn<int> get associatedMillis => $composableBuilder(
    column: $table.associatedMillis,
    builder: (column) => column,
  );

  GeneratedColumn<int> get revision =>
      $composableBuilder(column: $table.revision, builder: (column) => column);

  $$FinancialRecordsTableAnnotationComposer get financialRecordId {
    final $$FinancialRecordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.financialRecordId,
      referencedTable: $db.financialRecords,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FinancialRecordsTableAnnotationComposer(
            $db: $db,
            $table: $db.financialRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$RawMessagesTableAnnotationComposer get rawMessageId {
    final $$RawMessagesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.rawMessageId,
      referencedTable: $db.rawMessages,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RawMessagesTableAnnotationComposer(
            $db: $db,
            $table: $db.rawMessages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AccountsTableAnnotationComposer get accountId {
    final $$AccountsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableAnnotationComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BalanceEvidenceTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BalanceEvidenceTable,
          StoredBalanceEvidence,
          $$BalanceEvidenceTableFilterComposer,
          $$BalanceEvidenceTableOrderingComposer,
          $$BalanceEvidenceTableAnnotationComposer,
          $$BalanceEvidenceTableCreateCompanionBuilder,
          $$BalanceEvidenceTableUpdateCompanionBuilder,
          (StoredBalanceEvidence, $$BalanceEvidenceTableReferences),
          StoredBalanceEvidence,
          PrefetchHooks Function({
            bool financialRecordId,
            bool rawMessageId,
            bool accountId,
          })
        > {
  $$BalanceEvidenceTableTableManager(
    _$AppDatabase db,
    $BalanceEvidenceTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BalanceEvidenceTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BalanceEvidenceTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BalanceEvidenceTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> amountMinor = const Value.absent(),
                Value<String> currency = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String?> subjectFamily = const Value.absent(),
                Value<String> origin = const Value.absent(),
                Value<int> asOfMillis = const Value.absent(),
                Value<String> timeBasis = const Value.absent(),
                Value<int> createdMillis = const Value.absent(),
                Value<int?> financialRecordId = const Value.absent(),
                Value<int?> rawMessageId = const Value.absent(),
                Value<String?> matchedClause = const Value.absent(),
                Value<String?> extractionVersion = const Value.absent(),
                Value<int?> accountId = const Value.absent(),
                Value<String?> associationOrigin = const Value.absent(),
                Value<int?> associatedMillis = const Value.absent(),
                Value<int> revision = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BalanceEvidenceCompanion(
                id: id,
                amountMinor: amountMinor,
                currency: currency,
                kind: kind,
                subjectFamily: subjectFamily,
                origin: origin,
                asOfMillis: asOfMillis,
                timeBasis: timeBasis,
                createdMillis: createdMillis,
                financialRecordId: financialRecordId,
                rawMessageId: rawMessageId,
                matchedClause: matchedClause,
                extractionVersion: extractionVersion,
                accountId: accountId,
                associationOrigin: associationOrigin,
                associatedMillis: associatedMillis,
                revision: revision,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int amountMinor,
                required String currency,
                required String kind,
                Value<String?> subjectFamily = const Value.absent(),
                required String origin,
                required int asOfMillis,
                required String timeBasis,
                required int createdMillis,
                Value<int?> financialRecordId = const Value.absent(),
                Value<int?> rawMessageId = const Value.absent(),
                Value<String?> matchedClause = const Value.absent(),
                Value<String?> extractionVersion = const Value.absent(),
                Value<int?> accountId = const Value.absent(),
                Value<String?> associationOrigin = const Value.absent(),
                Value<int?> associatedMillis = const Value.absent(),
                Value<int> revision = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BalanceEvidenceCompanion.insert(
                id: id,
                amountMinor: amountMinor,
                currency: currency,
                kind: kind,
                subjectFamily: subjectFamily,
                origin: origin,
                asOfMillis: asOfMillis,
                timeBasis: timeBasis,
                createdMillis: createdMillis,
                financialRecordId: financialRecordId,
                rawMessageId: rawMessageId,
                matchedClause: matchedClause,
                extractionVersion: extractionVersion,
                accountId: accountId,
                associationOrigin: associationOrigin,
                associatedMillis: associatedMillis,
                revision: revision,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$BalanceEvidenceTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                financialRecordId = false,
                rawMessageId = false,
                accountId = false,
              }) {
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
                        if (financialRecordId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.financialRecordId,
                                    referencedTable:
                                        $$BalanceEvidenceTableReferences
                                            ._financialRecordIdTable(db),
                                    referencedColumn:
                                        $$BalanceEvidenceTableReferences
                                            ._financialRecordIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (rawMessageId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.rawMessageId,
                                    referencedTable:
                                        $$BalanceEvidenceTableReferences
                                            ._rawMessageIdTable(db),
                                    referencedColumn:
                                        $$BalanceEvidenceTableReferences
                                            ._rawMessageIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (accountId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.accountId,
                                    referencedTable:
                                        $$BalanceEvidenceTableReferences
                                            ._accountIdTable(db),
                                    referencedColumn:
                                        $$BalanceEvidenceTableReferences
                                            ._accountIdTable(db)
                                            .id,
                                  )
                                  as T;
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

typedef $$BalanceEvidenceTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BalanceEvidenceTable,
      StoredBalanceEvidence,
      $$BalanceEvidenceTableFilterComposer,
      $$BalanceEvidenceTableOrderingComposer,
      $$BalanceEvidenceTableAnnotationComposer,
      $$BalanceEvidenceTableCreateCompanionBuilder,
      $$BalanceEvidenceTableUpdateCompanionBuilder,
      (StoredBalanceEvidence, $$BalanceEvidenceTableReferences),
      StoredBalanceEvidence,
      PrefetchHooks Function({
        bool financialRecordId,
        bool rawMessageId,
        bool accountId,
      })
    >;
typedef $$CategoryRulesTableCreateCompanionBuilder =
    CategoryRulesCompanion Function({
      Value<int> id,
      required String identityKey,
      required String kind,
      required String categoryId,
    });
typedef $$CategoryRulesTableUpdateCompanionBuilder =
    CategoryRulesCompanion Function({
      Value<int> id,
      Value<String> identityKey,
      Value<String> kind,
      Value<String> categoryId,
    });

final class $$CategoryRulesTableReferences
    extends
        BaseReferences<_$AppDatabase, $CategoryRulesTable, StoredCategoryRule> {
  $$CategoryRulesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $TransactionCategoriesTable _categoryIdTable(_$AppDatabase db) => db
      .transactionCategories
      .createAlias('category_rules__category_id__transaction_categories__id');

  $$TransactionCategoriesTableProcessedTableManager get categoryId {
    final $_column = $_itemColumn<String>('category_id')!;

    final manager = $$TransactionCategoriesTableTableManager(
      $_db,
      $_db.transactionCategories,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_categoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<
    $RecordCategoryAssignmentsTable,
    List<StoredCategoryAssignment>
  >
  _recordCategoryAssignmentsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.recordCategoryAssignments,
        aliasName: 'category_rules__id__record_category_assignments__rule_id',
      );

  $$RecordCategoryAssignmentsTableProcessedTableManager
  get recordCategoryAssignmentsRefs {
    final manager = $$RecordCategoryAssignmentsTableTableManager(
      $_db,
      $_db.recordCategoryAssignments,
    ).filter((f) => f.ruleId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _recordCategoryAssignmentsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CategoryRulesTableFilterComposer
    extends Composer<_$AppDatabase, $CategoryRulesTable> {
  $$CategoryRulesTableFilterComposer({
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

  ColumnFilters<String> get identityKey => $composableBuilder(
    column: $table.identityKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  $$TransactionCategoriesTableFilterComposer get categoryId {
    final $$TransactionCategoriesTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.categoryId,
          referencedTable: $db.transactionCategories,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$TransactionCategoriesTableFilterComposer(
                $db: $db,
                $table: $db.transactionCategories,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }

  Expression<bool> recordCategoryAssignmentsRefs(
    Expression<bool> Function($$RecordCategoryAssignmentsTableFilterComposer f)
    f,
  ) {
    final $$RecordCategoryAssignmentsTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.recordCategoryAssignments,
          getReferencedColumn: (t) => t.ruleId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$RecordCategoryAssignmentsTableFilterComposer(
                $db: $db,
                $table: $db.recordCategoryAssignments,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$CategoryRulesTableOrderingComposer
    extends Composer<_$AppDatabase, $CategoryRulesTable> {
  $$CategoryRulesTableOrderingComposer({
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

  ColumnOrderings<String> get identityKey => $composableBuilder(
    column: $table.identityKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  $$TransactionCategoriesTableOrderingComposer get categoryId {
    final $$TransactionCategoriesTableOrderingComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.categoryId,
          referencedTable: $db.transactionCategories,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$TransactionCategoriesTableOrderingComposer(
                $db: $db,
                $table: $db.transactionCategories,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$CategoryRulesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CategoryRulesTable> {
  $$CategoryRulesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get identityKey => $composableBuilder(
    column: $table.identityKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  $$TransactionCategoriesTableAnnotationComposer get categoryId {
    final $$TransactionCategoriesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.categoryId,
          referencedTable: $db.transactionCategories,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$TransactionCategoriesTableAnnotationComposer(
                $db: $db,
                $table: $db.transactionCategories,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }

  Expression<T> recordCategoryAssignmentsRefs<T extends Object>(
    Expression<T> Function($$RecordCategoryAssignmentsTableAnnotationComposer a)
    f,
  ) {
    final $$RecordCategoryAssignmentsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.recordCategoryAssignments,
          getReferencedColumn: (t) => t.ruleId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$RecordCategoryAssignmentsTableAnnotationComposer(
                $db: $db,
                $table: $db.recordCategoryAssignments,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$CategoryRulesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CategoryRulesTable,
          StoredCategoryRule,
          $$CategoryRulesTableFilterComposer,
          $$CategoryRulesTableOrderingComposer,
          $$CategoryRulesTableAnnotationComposer,
          $$CategoryRulesTableCreateCompanionBuilder,
          $$CategoryRulesTableUpdateCompanionBuilder,
          (StoredCategoryRule, $$CategoryRulesTableReferences),
          StoredCategoryRule,
          PrefetchHooks Function({
            bool categoryId,
            bool recordCategoryAssignmentsRefs,
          })
        > {
  $$CategoryRulesTableTableManager(_$AppDatabase db, $CategoryRulesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategoryRulesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CategoryRulesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CategoryRulesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> identityKey = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> categoryId = const Value.absent(),
              }) => CategoryRulesCompanion(
                id: id,
                identityKey: identityKey,
                kind: kind,
                categoryId: categoryId,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String identityKey,
                required String kind,
                required String categoryId,
              }) => CategoryRulesCompanion.insert(
                id: id,
                identityKey: identityKey,
                kind: kind,
                categoryId: categoryId,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CategoryRulesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({categoryId = false, recordCategoryAssignmentsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (recordCategoryAssignmentsRefs)
                      db.recordCategoryAssignments,
                  ],
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
                        if (categoryId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.categoryId,
                                    referencedTable:
                                        $$CategoryRulesTableReferences
                                            ._categoryIdTable(db),
                                    referencedColumn:
                                        $$CategoryRulesTableReferences
                                            ._categoryIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (recordCategoryAssignmentsRefs)
                        await $_getPrefetchedData<
                          StoredCategoryRule,
                          $CategoryRulesTable,
                          StoredCategoryAssignment
                        >(
                          currentTable: table,
                          referencedTable: $$CategoryRulesTableReferences
                              ._recordCategoryAssignmentsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CategoryRulesTableReferences(
                                db,
                                table,
                                p0,
                              ).recordCategoryAssignmentsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.ruleId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$CategoryRulesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CategoryRulesTable,
      StoredCategoryRule,
      $$CategoryRulesTableFilterComposer,
      $$CategoryRulesTableOrderingComposer,
      $$CategoryRulesTableAnnotationComposer,
      $$CategoryRulesTableCreateCompanionBuilder,
      $$CategoryRulesTableUpdateCompanionBuilder,
      (StoredCategoryRule, $$CategoryRulesTableReferences),
      StoredCategoryRule,
      PrefetchHooks Function({
        bool categoryId,
        bool recordCategoryAssignmentsRefs,
      })
    >;
typedef $$RecordCategoryAssignmentsTableCreateCompanionBuilder =
    RecordCategoryAssignmentsCompanion Function({
      required int financialRecordId,
      Value<String?> categoryId,
      required String origin,
      Value<int?> ruleId,
      Value<DateTime> assignedAt,
    });
typedef $$RecordCategoryAssignmentsTableUpdateCompanionBuilder =
    RecordCategoryAssignmentsCompanion Function({
      Value<int> financialRecordId,
      Value<String?> categoryId,
      Value<String> origin,
      Value<int?> ruleId,
      Value<DateTime> assignedAt,
    });

final class $$RecordCategoryAssignmentsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $RecordCategoryAssignmentsTable,
          StoredCategoryAssignment
        > {
  $$RecordCategoryAssignmentsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $FinancialRecordsTable _financialRecordIdTable(
    _$AppDatabase db,
  ) => db.financialRecords.createAlias(
    'record_category_assignments__financial_record_id__financial_records__id',
  );

  $$FinancialRecordsTableProcessedTableManager get financialRecordId {
    final $_column = $_itemColumn<int>('financial_record_id')!;

    final manager = $$FinancialRecordsTableTableManager(
      $_db,
      $_db.financialRecords,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_financialRecordIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $TransactionCategoriesTable _categoryIdTable(_$AppDatabase db) =>
      db.transactionCategories.createAlias(
        'record_category_assignments__category_id__transaction_categories__id',
      );

  $$TransactionCategoriesTableProcessedTableManager? get categoryId {
    final $_column = $_itemColumn<String>('category_id');
    if ($_column == null) return null;
    final manager = $$TransactionCategoriesTableTableManager(
      $_db,
      $_db.transactionCategories,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_categoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $CategoryRulesTable _ruleIdTable(_$AppDatabase db) => db.categoryRules
      .createAlias('record_category_assignments__rule_id__category_rules__id');

  $$CategoryRulesTableProcessedTableManager? get ruleId {
    final $_column = $_itemColumn<int>('rule_id');
    if ($_column == null) return null;
    final manager = $$CategoryRulesTableTableManager(
      $_db,
      $_db.categoryRules,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_ruleIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$RecordCategoryAssignmentsTableFilterComposer
    extends Composer<_$AppDatabase, $RecordCategoryAssignmentsTable> {
  $$RecordCategoryAssignmentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get origin => $composableBuilder(
    column: $table.origin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get assignedAt => $composableBuilder(
    column: $table.assignedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$FinancialRecordsTableFilterComposer get financialRecordId {
    final $$FinancialRecordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.financialRecordId,
      referencedTable: $db.financialRecords,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FinancialRecordsTableFilterComposer(
            $db: $db,
            $table: $db.financialRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TransactionCategoriesTableFilterComposer get categoryId {
    final $$TransactionCategoriesTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.categoryId,
          referencedTable: $db.transactionCategories,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$TransactionCategoriesTableFilterComposer(
                $db: $db,
                $table: $db.transactionCategories,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }

  $$CategoryRulesTableFilterComposer get ruleId {
    final $$CategoryRulesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ruleId,
      referencedTable: $db.categoryRules,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoryRulesTableFilterComposer(
            $db: $db,
            $table: $db.categoryRules,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RecordCategoryAssignmentsTableOrderingComposer
    extends Composer<_$AppDatabase, $RecordCategoryAssignmentsTable> {
  $$RecordCategoryAssignmentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get origin => $composableBuilder(
    column: $table.origin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get assignedAt => $composableBuilder(
    column: $table.assignedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$FinancialRecordsTableOrderingComposer get financialRecordId {
    final $$FinancialRecordsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.financialRecordId,
      referencedTable: $db.financialRecords,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FinancialRecordsTableOrderingComposer(
            $db: $db,
            $table: $db.financialRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TransactionCategoriesTableOrderingComposer get categoryId {
    final $$TransactionCategoriesTableOrderingComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.categoryId,
          referencedTable: $db.transactionCategories,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$TransactionCategoriesTableOrderingComposer(
                $db: $db,
                $table: $db.transactionCategories,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }

  $$CategoryRulesTableOrderingComposer get ruleId {
    final $$CategoryRulesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ruleId,
      referencedTable: $db.categoryRules,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoryRulesTableOrderingComposer(
            $db: $db,
            $table: $db.categoryRules,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RecordCategoryAssignmentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RecordCategoryAssignmentsTable> {
  $$RecordCategoryAssignmentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get origin =>
      $composableBuilder(column: $table.origin, builder: (column) => column);

  GeneratedColumn<DateTime> get assignedAt => $composableBuilder(
    column: $table.assignedAt,
    builder: (column) => column,
  );

  $$FinancialRecordsTableAnnotationComposer get financialRecordId {
    final $$FinancialRecordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.financialRecordId,
      referencedTable: $db.financialRecords,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FinancialRecordsTableAnnotationComposer(
            $db: $db,
            $table: $db.financialRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TransactionCategoriesTableAnnotationComposer get categoryId {
    final $$TransactionCategoriesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.categoryId,
          referencedTable: $db.transactionCategories,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$TransactionCategoriesTableAnnotationComposer(
                $db: $db,
                $table: $db.transactionCategories,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }

  $$CategoryRulesTableAnnotationComposer get ruleId {
    final $$CategoryRulesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ruleId,
      referencedTable: $db.categoryRules,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoryRulesTableAnnotationComposer(
            $db: $db,
            $table: $db.categoryRules,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RecordCategoryAssignmentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RecordCategoryAssignmentsTable,
          StoredCategoryAssignment,
          $$RecordCategoryAssignmentsTableFilterComposer,
          $$RecordCategoryAssignmentsTableOrderingComposer,
          $$RecordCategoryAssignmentsTableAnnotationComposer,
          $$RecordCategoryAssignmentsTableCreateCompanionBuilder,
          $$RecordCategoryAssignmentsTableUpdateCompanionBuilder,
          (
            StoredCategoryAssignment,
            $$RecordCategoryAssignmentsTableReferences,
          ),
          StoredCategoryAssignment,
          PrefetchHooks Function({
            bool financialRecordId,
            bool categoryId,
            bool ruleId,
          })
        > {
  $$RecordCategoryAssignmentsTableTableManager(
    _$AppDatabase db,
    $RecordCategoryAssignmentsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecordCategoryAssignmentsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$RecordCategoryAssignmentsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$RecordCategoryAssignmentsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> financialRecordId = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                Value<String> origin = const Value.absent(),
                Value<int?> ruleId = const Value.absent(),
                Value<DateTime> assignedAt = const Value.absent(),
              }) => RecordCategoryAssignmentsCompanion(
                financialRecordId: financialRecordId,
                categoryId: categoryId,
                origin: origin,
                ruleId: ruleId,
                assignedAt: assignedAt,
              ),
          createCompanionCallback:
              ({
                required int financialRecordId,
                Value<String?> categoryId = const Value.absent(),
                required String origin,
                Value<int?> ruleId = const Value.absent(),
                Value<DateTime> assignedAt = const Value.absent(),
              }) => RecordCategoryAssignmentsCompanion.insert(
                financialRecordId: financialRecordId,
                categoryId: categoryId,
                origin: origin,
                ruleId: ruleId,
                assignedAt: assignedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$RecordCategoryAssignmentsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                financialRecordId = false,
                categoryId = false,
                ruleId = false,
              }) {
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
                        if (financialRecordId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.financialRecordId,
                                    referencedTable:
                                        $$RecordCategoryAssignmentsTableReferences
                                            ._financialRecordIdTable(db),
                                    referencedColumn:
                                        $$RecordCategoryAssignmentsTableReferences
                                            ._financialRecordIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (categoryId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.categoryId,
                                    referencedTable:
                                        $$RecordCategoryAssignmentsTableReferences
                                            ._categoryIdTable(db),
                                    referencedColumn:
                                        $$RecordCategoryAssignmentsTableReferences
                                            ._categoryIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (ruleId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.ruleId,
                                    referencedTable:
                                        $$RecordCategoryAssignmentsTableReferences
                                            ._ruleIdTable(db),
                                    referencedColumn:
                                        $$RecordCategoryAssignmentsTableReferences
                                            ._ruleIdTable(db)
                                            .id,
                                  )
                                  as T;
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

typedef $$RecordCategoryAssignmentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RecordCategoryAssignmentsTable,
      StoredCategoryAssignment,
      $$RecordCategoryAssignmentsTableFilterComposer,
      $$RecordCategoryAssignmentsTableOrderingComposer,
      $$RecordCategoryAssignmentsTableAnnotationComposer,
      $$RecordCategoryAssignmentsTableCreateCompanionBuilder,
      $$RecordCategoryAssignmentsTableUpdateCompanionBuilder,
      (StoredCategoryAssignment, $$RecordCategoryAssignmentsTableReferences),
      StoredCategoryAssignment,
      PrefetchHooks Function({
        bool financialRecordId,
        bool categoryId,
        bool ruleId,
      })
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$AccountsTableTableManager get accounts =>
      $$AccountsTableTableManager(_db, _db.accounts);
  $$TransactionCategoriesTableTableManager get transactionCategories =>
      $$TransactionCategoriesTableTableManager(_db, _db.transactionCategories);
  $$BudgetsTableTableManager get budgets =>
      $$BudgetsTableTableManager(_db, _db.budgets);
  $$FinancialRecordsTableTableManager get financialRecords =>
      $$FinancialRecordsTableTableManager(_db, _db.financialRecords);
  $$RawMessagesTableTableManager get rawMessages =>
      $$RawMessagesTableTableManager(_db, _db.rawMessages);
  $$BalanceEvidenceTableTableManager get balanceEvidence =>
      $$BalanceEvidenceTableTableManager(_db, _db.balanceEvidence);
  $$CategoryRulesTableTableManager get categoryRules =>
      $$CategoryRulesTableTableManager(_db, _db.categoryRules);
  $$RecordCategoryAssignmentsTableTableManager get recordCategoryAssignments =>
      $$RecordCategoryAssignmentsTableTableManager(
        _db,
        _db.recordCategoryAssignments,
      );
}

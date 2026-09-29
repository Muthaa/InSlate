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
  final DateTime createdAt;
  const Account({
    required this.id,
    required this.uuid,
    required this.name,
    required this.type,
    this.institution,
    required this.isActive,
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
    DateTime? createdAt,
  }) => Account(
    id: id ?? this.id,
    uuid: uuid ?? this.uuid,
    name: name ?? this.name,
    type: type ?? this.type,
    institution: institution.present ? institution.value : this.institution,
    isActive: isActive ?? this.isActive,
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
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, uuid, name, type, institution, isActive, createdAt);
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
          other.createdAt == this.createdAt);
}

class AccountsCompanion extends UpdateCompanion<Account> {
  final Value<int> id;
  final Value<String> uuid;
  final Value<String> name;
  final Value<String> type;
  final Value<String?> institution;
  final Value<bool> isActive;
  final Value<DateTime> createdAt;
  const AccountsCompanion({
    this.id = const Value.absent(),
    this.uuid = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.institution = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  AccountsCompanion.insert({
    this.id = const Value.absent(),
    required String uuid,
    required String name,
    required String type,
    this.institution = const Value.absent(),
    this.isActive = const Value.absent(),
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
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (uuid != null) 'uuid': uuid,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (institution != null) 'institution': institution,
      if (isActive != null) 'is_active': isActive,
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
    Value<DateTime>? createdAt,
  }) {
    return AccountsCompanion(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      name: name ?? this.name,
      type: type ?? this.type,
      institution: institution ?? this.institution,
      isActive: isActive ?? this.isActive,
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
          ..write('createdAt: $createdAt')
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
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
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
    reference,
    transactionDate,
    amount,
    balance,
    transactionCost,
    type,
    subtype,
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
    if (data.containsKey('reference')) {
      context.handle(
        _referenceMeta,
        reference.isAcceptableOrUnknown(data['reference']!, _referenceMeta),
      );
    } else if (isInserting) {
      context.missing(_referenceMeta);
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
      reference: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reference'],
      )!,
      transactionDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}transaction_date'],
      ),
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
  final String reference;
  final DateTime? transactionDate;
  final double amount;
  final double? balance;
  final double? transactionCost;
  final String type;
  final String subtype;
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
    required this.reference,
    this.transactionDate,
    required this.amount,
    this.balance,
    this.transactionCost,
    required this.type,
    required this.subtype,
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
    map['reference'] = Variable<String>(reference);
    if (!nullToAbsent || transactionDate != null) {
      map['transaction_date'] = Variable<DateTime>(transactionDate);
    }
    map['amount'] = Variable<double>(amount);
    if (!nullToAbsent || balance != null) {
      map['balance'] = Variable<double>(balance);
    }
    if (!nullToAbsent || transactionCost != null) {
      map['transaction_cost'] = Variable<double>(transactionCost);
    }
    map['type'] = Variable<String>(type);
    map['subtype'] = Variable<String>(subtype);
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
      reference: Value(reference),
      transactionDate: transactionDate == null && nullToAbsent
          ? const Value.absent()
          : Value(transactionDate),
      amount: Value(amount),
      balance: balance == null && nullToAbsent
          ? const Value.absent()
          : Value(balance),
      transactionCost: transactionCost == null && nullToAbsent
          ? const Value.absent()
          : Value(transactionCost),
      type: Value(type),
      subtype: Value(subtype),
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
      reference: serializer.fromJson<String>(json['reference']),
      transactionDate: serializer.fromJson<DateTime?>(json['transactionDate']),
      amount: serializer.fromJson<double>(json['amount']),
      balance: serializer.fromJson<double?>(json['balance']),
      transactionCost: serializer.fromJson<double?>(json['transactionCost']),
      type: serializer.fromJson<String>(json['type']),
      subtype: serializer.fromJson<String>(json['subtype']),
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
      'reference': serializer.toJson<String>(reference),
      'transactionDate': serializer.toJson<DateTime?>(transactionDate),
      'amount': serializer.toJson<double>(amount),
      'balance': serializer.toJson<double?>(balance),
      'transactionCost': serializer.toJson<double?>(transactionCost),
      'type': serializer.toJson<String>(type),
      'subtype': serializer.toJson<String>(subtype),
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
    String? reference,
    Value<DateTime?> transactionDate = const Value.absent(),
    double? amount,
    Value<double?> balance = const Value.absent(),
    Value<double?> transactionCost = const Value.absent(),
    String? type,
    String? subtype,
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
    reference: reference ?? this.reference,
    transactionDate: transactionDate.present
        ? transactionDate.value
        : this.transactionDate,
    amount: amount ?? this.amount,
    balance: balance.present ? balance.value : this.balance,
    transactionCost: transactionCost.present
        ? transactionCost.value
        : this.transactionCost,
    type: type ?? this.type,
    subtype: subtype ?? this.subtype,
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
      reference: data.reference.present ? data.reference.value : this.reference,
      transactionDate: data.transactionDate.present
          ? data.transactionDate.value
          : this.transactionDate,
      amount: data.amount.present ? data.amount.value : this.amount,
      balance: data.balance.present ? data.balance.value : this.balance,
      transactionCost: data.transactionCost.present
          ? data.transactionCost.value
          : this.transactionCost,
      type: data.type.present ? data.type.value : this.type,
      subtype: data.subtype.present ? data.subtype.value : this.subtype,
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
          ..write('reference: $reference, ')
          ..write('transactionDate: $transactionDate, ')
          ..write('amount: $amount, ')
          ..write('balance: $balance, ')
          ..write('transactionCost: $transactionCost, ')
          ..write('type: $type, ')
          ..write('subtype: $subtype, ')
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
  int get hashCode => Object.hash(
    id,
    reference,
    transactionDate,
    amount,
    balance,
    transactionCost,
    type,
    subtype,
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
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FinancialRecord &&
          other.id == this.id &&
          other.reference == this.reference &&
          other.transactionDate == this.transactionDate &&
          other.amount == this.amount &&
          other.balance == this.balance &&
          other.transactionCost == this.transactionCost &&
          other.type == this.type &&
          other.subtype == this.subtype &&
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
  final Value<String> reference;
  final Value<DateTime?> transactionDate;
  final Value<double> amount;
  final Value<double?> balance;
  final Value<double?> transactionCost;
  final Value<String> type;
  final Value<String> subtype;
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
    this.reference = const Value.absent(),
    this.transactionDate = const Value.absent(),
    this.amount = const Value.absent(),
    this.balance = const Value.absent(),
    this.transactionCost = const Value.absent(),
    this.type = const Value.absent(),
    this.subtype = const Value.absent(),
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
    required String reference,
    this.transactionDate = const Value.absent(),
    required double amount,
    this.balance = const Value.absent(),
    this.transactionCost = const Value.absent(),
    required String type,
    required String subtype,
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
       amount = Value(amount),
       type = Value(type),
       subtype = Value(subtype),
       status = Value(status),
       title = Value(title),
       rawMessage = Value(rawMessage);
  static Insertable<FinancialRecord> custom({
    Expression<int>? id,
    Expression<String>? reference,
    Expression<DateTime>? transactionDate,
    Expression<double>? amount,
    Expression<double>? balance,
    Expression<double>? transactionCost,
    Expression<String>? type,
    Expression<String>? subtype,
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
      if (reference != null) 'reference': reference,
      if (transactionDate != null) 'transaction_date': transactionDate,
      if (amount != null) 'amount': amount,
      if (balance != null) 'balance': balance,
      if (transactionCost != null) 'transaction_cost': transactionCost,
      if (type != null) 'type': type,
      if (subtype != null) 'subtype': subtype,
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
    Value<String>? reference,
    Value<DateTime?>? transactionDate,
    Value<double>? amount,
    Value<double?>? balance,
    Value<double?>? transactionCost,
    Value<String>? type,
    Value<String>? subtype,
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
      reference: reference ?? this.reference,
      transactionDate: transactionDate ?? this.transactionDate,
      amount: amount ?? this.amount,
      balance: balance ?? this.balance,
      transactionCost: transactionCost ?? this.transactionCost,
      type: type ?? this.type,
      subtype: subtype ?? this.subtype,
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
    if (reference.present) {
      map['reference'] = Variable<String>(reference.value);
    }
    if (transactionDate.present) {
      map['transaction_date'] = Variable<DateTime>(transactionDate.value);
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
          ..write('reference: $reference, ')
          ..write('transactionDate: $transactionDate, ')
          ..write('amount: $amount, ')
          ..write('balance: $balance, ')
          ..write('transactionCost: $transactionCost, ')
          ..write('type: $type, ')
          ..write('subtype: $subtype, ')
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

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $AccountsTable accounts = $AccountsTable(this);
  late final $FinancialRecordsTable financialRecords = $FinancialRecordsTable(
    this,
  );
  late final $RawMessagesTable rawMessages = $RawMessagesTable(this);
  late final AccountsDao accountsDao = AccountsDao(this as AppDatabase);
  late final FinancialRecordsDao financialRecordsDao = FinancialRecordsDao(
    this as AppDatabase,
  );
  late final RawMessagesDao rawMessagesDao = RawMessagesDao(
    this as AppDatabase,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    accounts,
    financialRecords,
    rawMessages,
  ];
}

typedef $$AccountsTableCreateCompanionBuilder =
    AccountsCompanion Function({
      Value<int> id,
      required String uuid,
      required String name,
      required String type,
      Value<String?> institution,
      Value<bool> isActive,
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
      Value<DateTime> createdAt,
    });

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

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
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

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
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
          (Account, BaseReferences<_$AppDatabase, $AccountsTable, Account>),
          Account,
          PrefetchHooks Function()
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
                Value<DateTime> createdAt = const Value.absent(),
              }) => AccountsCompanion(
                id: id,
                uuid: uuid,
                name: name,
                type: type,
                institution: institution,
                isActive: isActive,
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
                Value<DateTime> createdAt = const Value.absent(),
              }) => AccountsCompanion.insert(
                id: id,
                uuid: uuid,
                name: name,
                type: type,
                institution: institution,
                isActive: isActive,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
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
      (Account, BaseReferences<_$AppDatabase, $AccountsTable, Account>),
      Account,
      PrefetchHooks Function()
    >;
typedef $$FinancialRecordsTableCreateCompanionBuilder =
    FinancialRecordsCompanion Function({
      Value<int> id,
      required String reference,
      Value<DateTime?> transactionDate,
      required double amount,
      Value<double?> balance,
      Value<double?> transactionCost,
      required String type,
      required String subtype,
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
      Value<String> reference,
      Value<DateTime?> transactionDate,
      Value<double> amount,
      Value<double?> balance,
      Value<double?> transactionCost,
      Value<String> type,
      Value<String> subtype,
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

  ColumnFilters<DateTime> get transactionDate => $composableBuilder(
    column: $table.transactionDate,
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

  ColumnOrderings<DateTime> get transactionDate => $composableBuilder(
    column: $table.transactionDate,
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

  GeneratedColumn<DateTime> get transactionDate => $composableBuilder(
    column: $table.transactionDate,
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
          (
            FinancialRecord,
            BaseReferences<
              _$AppDatabase,
              $FinancialRecordsTable,
              FinancialRecord
            >,
          ),
          FinancialRecord,
          PrefetchHooks Function()
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
                Value<String> reference = const Value.absent(),
                Value<DateTime?> transactionDate = const Value.absent(),
                Value<double> amount = const Value.absent(),
                Value<double?> balance = const Value.absent(),
                Value<double?> transactionCost = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> subtype = const Value.absent(),
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
                reference: reference,
                transactionDate: transactionDate,
                amount: amount,
                balance: balance,
                transactionCost: transactionCost,
                type: type,
                subtype: subtype,
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
                required String reference,
                Value<DateTime?> transactionDate = const Value.absent(),
                required double amount,
                Value<double?> balance = const Value.absent(),
                Value<double?> transactionCost = const Value.absent(),
                required String type,
                required String subtype,
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
                reference: reference,
                transactionDate: transactionDate,
                amount: amount,
                balance: balance,
                transactionCost: transactionCost,
                type: type,
                subtype: subtype,
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
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
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
      (
        FinancialRecord,
        BaseReferences<_$AppDatabase, $FinancialRecordsTable, FinancialRecord>,
      ),
      FinancialRecord,
      PrefetchHooks Function()
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
          (
            RawMessage,
            BaseReferences<_$AppDatabase, $RawMessagesTable, RawMessage>,
          ),
          RawMessage,
          PrefetchHooks Function()
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
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
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
      (
        RawMessage,
        BaseReferences<_$AppDatabase, $RawMessagesTable, RawMessage>,
      ),
      RawMessage,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$AccountsTableTableManager get accounts =>
      $$AccountsTableTableManager(_db, _db.accounts);
  $$FinancialRecordsTableTableManager get financialRecords =>
      $$FinancialRecordsTableTableManager(_db, _db.financialRecords);
  $$RawMessagesTableTableManager get rawMessages =>
      $$RawMessagesTableTableManager(_db, _db.rawMessages);
}

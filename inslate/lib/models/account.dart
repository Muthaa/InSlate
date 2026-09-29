import '/core/enums/account_type.dart';

class Account {
  final String id;

  final String name;

  final AccountType type;

  final String? institution;

  const Account({
    required this.id,
    required this.name,
    required this.type,
    this.institution,
  });
}

import '/core/enums/party_type.dart';

class Party {
  final String name;

  final PartyType type;

  final String? phone;

  final String? account;

  final String? identifier;

  const Party({
    required this.name,
    required this.type,
    this.phone,
    this.account,
    this.identifier,
  });
}

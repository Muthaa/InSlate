import '/core/enums/party_type.dart';

class PartyTypeMapper {
  PartyTypeMapper._();

  static PartyType fromName(String name) {
    final text = name.toLowerCase();

    if (text.contains('ltd') ||
        text.contains('limited') ||
        text.contains('bank') ||
        text.contains('fund') ||
        text.contains('sacco') ||
        text.contains('co-operative')) {
      return PartyType.business;
    }

    return PartyType.person;
  }
}

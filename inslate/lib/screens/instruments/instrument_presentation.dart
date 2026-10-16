import 'package:flutter/material.dart';
import '../../models/financial_instrument.dart';

String instrumentTypeLabel(InstrumentType type) => switch (type) {
  InstrumentType.bankAccount => 'Bank account',
  InstrumentType.mobileWallet => 'Mobile wallet',
  InstrumentType.savingsProduct => 'Savings product',
  InstrumentType.investmentAccount => 'Investment account / product',
  InstrumentType.saccoMembership => 'SACCO membership',
  InstrumentType.insurancePolicy => 'Insurance policy',
  InstrumentType.pension => 'Pension',
  InstrumentType.other => 'Other',
};

IconData instrumentTypeIcon(InstrumentType type) => switch (type) {
  InstrumentType.bankAccount => Icons.account_balance_outlined,
  InstrumentType.mobileWallet => Icons.account_balance_wallet_outlined,
  InstrumentType.savingsProduct => Icons.savings_outlined,
  InstrumentType.investmentAccount => Icons.trending_up,
  InstrumentType.saccoMembership => Icons.groups_outlined,
  InstrumentType.insurancePolicy => Icons.shield_outlined,
  InstrumentType.pension => Icons.event_available_outlined,
  InstrumentType.other => Icons.folder_outlined,
};

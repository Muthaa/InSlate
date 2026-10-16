import '../../models/financial_instrument.dart';

/// Registration/discovery metadata only. Never used to classify SMS or infer ownership.
enum InstrumentProduct {
  bankAccount('Bank accounts', InstrumentType.bankAccount),
  mobileWallet('Mobile wallets', InstrumentType.mobileWallet),
  savings('Savings and fixed deposits', InstrumentType.savingsProduct),
  moneyMarket('Money market funds', InstrumentType.investmentAccount),
  fixedIncome('Fixed income funds', InstrumentType.investmentAccount),
  specialFund('Special / multi-asset funds', InstrumentType.investmentAccount),
  equities(
    'Stocks, ETFs and brokerage accounts',
    InstrumentType.investmentAccount,
  ),
  trading('Trading accounts and wallets', InstrumentType.investmentAccount),
  treasuryBills('Government Treasury bills', InstrumentType.investmentAccount),
  treasuryBonds(
    'Government / infrastructure bonds',
    InstrumentType.investmentAccount,
  ),
  insurance('Insurance policies', InstrumentType.insurancePolicy),
  sacco('SACCO memberships', InstrumentType.saccoMembership),
  pension('Pensions and retirement products', InstrumentType.pension),
  cryptoExchange('Crypto exchange accounts', InstrumentType.investmentAccount),
  cryptoWallet('Bitcoin / crypto self-custody wallets', InstrumentType.other),
  other('Other instruments', InstrumentType.other);

  final String label;
  final InstrumentType type;
  const InstrumentProduct(this.label, this.type);
}

class ProviderPaymentRoute {
  final String paybill, referenceDescription, source;
  const ProviderPaymentRoute(
    this.paybill,
    this.referenceDescription,
    this.source,
  );
}

class InstrumentProviderEntry {
  final String id, name;
  final List<InstrumentProduct> products;
  final List<String> aliases;
  final List<ProviderPaymentRoute> routes;

  /// Empty means registration-only metadata, never a new SMS classifier term.
  final List<String> investmentKeywords;
  const InstrumentProviderEntry(
    this.id,
    this.name,
    this.products, {
    this.aliases = const [],
    this.routes = const [],
    this.investmentKeywords = const [],
  });
}

class InstrumentCatalogue {
  InstrumentCatalogue._();
  static const providers = <InstrumentProviderEntry>[
    // Existing recognized brands retained without extending SMS recognition.
    InstrumentProviderEntry(
      'cytonn',
      'Cytonn',
      [InstrumentProduct.moneyMarket],
      investmentKeywords: ['cytonn'],
    ),
    InstrumentProviderEntry(
      'mali',
      'Mali',
      [InstrumentProduct.moneyMarket],
      investmentKeywords: ['mali'],
    ),
    InstrumentProviderEntry(
      'apollo',
      'Apollo',
      [InstrumentProduct.moneyMarket],
      investmentKeywords: ['apollo'],
    ),
    InstrumentProviderEntry(
      'ziidi',
      'Ziidi',
      [InstrumentProduct.moneyMarket],
      investmentKeywords: ['ziidi'],
    ),
    InstrumentProviderEntry(
      'suluhu',
      'Suluhu',
      [InstrumentProduct.moneyMarket],
      investmentKeywords: ['suluhu'],
    ),

    InstrumentProviderEntry(
      'britam_asset',
      'Britam Asset Managers',
      [InstrumentProduct.moneyMarket, InstrumentProduct.fixedIncome],
      investmentKeywords: ['britam'],
    ),
    InstrumentProviderEntry(
      'icea_asset',
      'ICEA LION Asset Management',
      [InstrumentProduct.moneyMarket],
      investmentKeywords: ['icea'],
    ),
    InstrumentProviderEntry(
      'old_mutual_invest',
      'Old Mutual Investment Group',
      [InstrumentProduct.moneyMarket, InstrumentProduct.equities],
      investmentKeywords: ['old mutual'],
    ),
    InstrumentProviderEntry('zimele', 'Zimele Asset Management', [
      InstrumentProduct.fixedIncome,
      InstrumentProduct.pension,
    ]),
    InstrumentProviderEntry(
      'cic_asset',
      'CIC Asset Management',
      [
        InstrumentProduct.moneyMarket,
        InstrumentProduct.fixedIncome,
        InstrumentProduct.equities,
      ],
      routes: [
        ProviderPaymentRoute(
          '600118',
          'Member number',
          'https://cic.co.ke/wp-content/uploads/2022/11/Mpesa-Payment-Process-2.pdf',
        ),
      ],
    ),
    InstrumentProviderEntry(
      'jubilee_asset',
      'Jubilee Asset Management',
      [InstrumentProduct.moneyMarket, InstrumentProduct.fixedIncome],
      routes: [
        ProviderPaymentRoute(
          '4103749',
          'Investment account number',
          'https://jubileeinsurance.com/ke/asset-management-products/jubilee-money-market-fund-kes/',
        ),
      ],
    ),
    InstrumentProviderEntry(
      'genghis',
      'Genghis Capital',
      [InstrumentProduct.moneyMarket, InstrumentProduct.equities],
      routes: [
        ProviderPaymentRoute(
          '819392',
          'Member number',
          'https://genghis-capital.com/wp-content/uploads/2024/08/Genghis-Money-Market-Fund-Flyer-3_compressed.pdf',
        ),
      ],
    ),
    InstrumentProviderEntry(
      'sanlam_invest',
      'SanlamAllianz Investments',
      [InstrumentProduct.moneyMarket, InstrumentProduct.fixedIncome],
      aliases: ['Sanlam Investments East Africa'],
      investmentKeywords: ['sanlam'],
    ),
    InstrumentProviderEntry(
      'etica',
      'Etica Capital',
      [
        InstrumentProduct.moneyMarket,
        InstrumentProduct.fixedIncome,
        InstrumentProduct.specialFund,
      ],
      aliases: ['Etica'],
      routes: [
        ProviderPaymentRoute('4096483', 'Client code', 'https://eticacap.com/'),
      ],
      investmentKeywords: ['etica'],
    ),
    InstrumentProviderEntry('nabo', 'Nabo Capital', [
      InstrumentProduct.moneyMarket,
      InstrumentProduct.equities,
    ]),
    InstrumentProviderEntry('kuza', 'Kuza Asset Management', [
      InstrumentProduct.moneyMarket,
      InstrumentProduct.fixedIncome,
      InstrumentProduct.specialFund,
      InstrumentProduct.pension,
    ]),
    InstrumentProviderEntry('absa_asset', 'Absa Asset Management', [
      InstrumentProduct.moneyMarket,
      InstrumentProduct.fixedIncome,
      InstrumentProduct.equities,
    ]),
    InstrumentProviderEntry('kcb_invest', 'KCB Investment Bank', [
      InstrumentProduct.moneyMarket,
      InstrumentProduct.fixedIncome,
      InstrumentProduct.equities,
      InstrumentProduct.specialFund,
    ]),
    InstrumentProviderEntry(
      'sib',
      'Standard Investment Bank',
      [
        InstrumentProduct.specialFund,
        InstrumentProduct.equities,
        InstrumentProduct.trading,
      ],
      aliases: ['SIB'],
    ),
    InstrumentProviderEntry('mansa', 'Mansa-X', [
      InstrumentProduct.specialFund,
    ]),
    InstrumentProviderEntry(
      'ndovu',
      'Ndovu',
      [InstrumentProduct.moneyMarket, InstrumentProduct.equities],
      investmentKeywords: ['ndovu'],
    ),
    InstrumentProviderEntry('mpesa', 'M-PESA', [
      InstrumentProduct.mobileWallet,
    ]),
    InstrumentProviderEntry('mshwari', 'M-Shwari', [InstrumentProduct.savings]),
    InstrumentProviderEntry('kcb_mpesa', 'KCB M-PESA', [
      InstrumentProduct.savings,
    ]),
    InstrumentProviderEntry(
      'coop',
      'Co-operative Bank',
      [InstrumentProduct.bankAccount, InstrumentProduct.savings],
      routes: [
        ProviderPaymentRoute(
          '400200',
          'Destination bank account number; ownership is not established',
          'https://www.co-opbank.co.ke/ways_to_bank/paybill-400200/',
        ),
      ],
    ),
    InstrumentProviderEntry(
      'cic_pension',
      'CIC Pension',
      [InstrumentProduct.pension],
      routes: [
        ProviderPaymentRoute(
          '600113',
          'Member number',
          'https://cic.co.ke/wp-content/uploads/2022/11/Mpesa-Payment-Process-2.pdf',
        ),
      ],
    ),
    InstrumentProviderEntry(
      'gencap_pension',
      'Gencap Individual Pension Plan',
      [InstrumentProduct.pension],
      routes: [
        ProviderPaymentRoute(
          '7139239',
          'Member number',
          'https://genghis-capital.com/wp-content/uploads/2023/08/Gencap-IPP-FAQs.pdf',
        ),
      ],
    ),
    InstrumentProviderEntry(
      'nssf',
      'NSSF',
      [InstrumentProduct.pension],
      routes: [
        ProviderPaymentRoute(
          '333300',
          'Full membership number, retaining leading zeros and any trailing X',
          'https://selfservice.nssf.or.ke/member-resources/',
        ),
      ],
    ),
    InstrumentProviderEntry('cic_insurance', 'CIC Insurance', [
      InstrumentProduct.insurance,
    ]),
    InstrumentProviderEntry(
      'enwealth_faraja',
      'Enwealth Faraja',
      [InstrumentProduct.insurance],
      routes: [
        ProviderPaymentRoute(
          '808900',
          'Principal member full name',
          'https://enwealth.co.ke/insurance/wp-content/uploads/sites/4/Faraja-Benevolent-Fund-Sign-Up.pdf',
        ),
      ],
    ),
    InstrumentProviderEntry(
      'kenversity',
      'Kenversity SACCO',
      [InstrumentProduct.sacco],
      routes: [
        ProviderPaymentRoute(
          '577820',
          'Product code and membership number; deposits and loan payments share this route',
          'https://kenversitysacco.co.ke/',
        ),
      ],
    ),
    InstrumentProviderEntry('cbk', 'Central Bank of Kenya / DhowCSD', [
      InstrumentProduct.treasuryBills,
      InstrumentProduct.treasuryBonds,
    ]),
    InstrumentProviderEntry('binance', 'Binance', [
      InstrumentProduct.cryptoExchange,
    ]),
  ];

  // Legacy generic wording; registration-only providers do not affect classification.
  static const _genericInvestmentKeywords = [
    'money market',
    'money market fund',
    'mmf',
  ];
  static final List<String> investmentKeywords = List.unmodifiable([
    ..._genericInvestmentKeywords,
    for (final provider in providers) ...provider.investmentKeywords,
  ]);

  static String normalizeName(String value) =>
      value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  /// Exact published names/aliases only; never fuzzy or substring matching.
  static String providerKey(String value) {
    final normalized = normalizeName(value);
    for (final entry in providers) {
      if ([
        entry.name,
        ...entry.aliases,
      ].any((name) => normalizeName(name) == normalized)) {
        return entry.id;
      }
    }
    return normalized;
  }

  static List<FinancialInstrument> registrations(
    String provider,
    InstrumentType type,
    List<FinancialInstrument> instruments,
  ) => instruments
      .where(
        (i) =>
            i.type == type &&
            i.provider != null &&
            providerKey(i.provider!) == providerKey(provider),
      )
      .toList();
}

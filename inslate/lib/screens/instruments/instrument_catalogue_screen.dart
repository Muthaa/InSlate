import 'package:flutter/material.dart';
import '../../core/constants/instrument_catalogue.dart';
import '../../core/theme/app_theme.dart';
import 'instrument_form_screen.dart';

class InstrumentCatalogueScreen extends StatefulWidget {
  const InstrumentCatalogueScreen({super.key});
  @override
  State<InstrumentCatalogueScreen> createState() =>
      _InstrumentCatalogueScreenState();
}

class _InstrumentCatalogueScreenState extends State<InstrumentCatalogueScreen> {
  String _search = '';
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppTheme.appBackground,
    appBar: AppBar(title: const Text('Instrument catalogue')),
    body: SafeArea(
      top: false,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Choose a product to register locally. Listed providers are examples, not investment recommendations or detected ownership. You can enter any provider.',
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: const InputDecoration(
              hintText: 'Search products or providers',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (value) => setState(
              () => _search = InstrumentCatalogue.normalizeName(value),
            ),
          ),
          const SizedBox(height: 12),
          if (!InstrumentProduct.values.any((product) => _matches(product)))
            const Text(
              'No matching products or providers. Clear your search to register another instrument.',
            ),
          for (final product in InstrumentProduct.values)
            if (_matches(product))
              Card(
                color: Colors.white,
                child: ExpansionTile(
                  key: ValueKey(product.name),
                  title: Text(product.label),
                  children: [
                    if (product == InstrumentProduct.specialFund)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'High yield describes a return or risk characteristic, not a guaranteed yield or separate account type.',
                        ),
                      ),
                    if (product == InstrumentProduct.cryptoWallet ||
                        product == InstrumentProduct.cryptoExchange)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'Manual registration only. M-PESA P2P payments do not identify a crypto wallet. Do not enter seed phrases, private keys or passwords. No crypto holdings or valuations are calculated.',
                        ),
                      ),
                    if (product == InstrumentProduct.treasuryBills ||
                        product == InstrumentProduct.treasuryBonds)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'Register your securities account or a named holding manually. No universal M-PESA payment identifier or inferred portfolio value is assumed.',
                        ),
                      ),
                    for (final provider in InstrumentCatalogue.providers)
                      if (provider.products.contains(product) &&
                          (_search.isEmpty ||
                              InstrumentCatalogue.normalizeName(
                                product.label,
                              ).contains(_search) ||
                              InstrumentCatalogue.normalizeName(
                                provider.name,
                              ).contains(_search)))
                        ListTile(
                          title: Text(provider.name),
                          subtitle: const Text('Register explicitly'),
                          trailing: const Icon(
                            Icons.add_circle_outline,
                            color: AppTheme.teal,
                          ),
                          onTap: () => _register(product, provider.name),
                        ),
                    ListTile(
                      title: const Text('Other provider / custom instrument'),
                      trailing: const Icon(Icons.add),
                      onTap: () => _register(product, null),
                    ),
                  ],
                ),
              ),
        ],
      ),
    ),
  );

  bool _matches(InstrumentProduct product) =>
      _search.isEmpty ||
      InstrumentCatalogue.normalizeName(product.label).contains(_search) ||
      InstrumentCatalogue.providers.any(
        (p) =>
            p.products.contains(product) &&
            InstrumentCatalogue.normalizeName(p.name).contains(_search),
      );

  void _register(InstrumentProduct product, String? provider) => Navigator.push(
    context,
    MaterialPageRoute<void>(
      builder: (_) => InstrumentFormScreen(
        suggestedProvider: provider,
        suggestedType: product.type,
        suggestedName: product.label,
      ),
    ),
  );
}

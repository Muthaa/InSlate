import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/your_data_provider.dart';
import '../../repositories/your_data_repository.dart';

class StoredSmsScreen extends ConsumerStatefulWidget {
  const StoredSmsScreen({super.key});
  @override
  ConsumerState<StoredSmsScreen> createState() => _StoredSmsScreenState();
}

class _StoredSmsScreenState extends ConsumerState<StoredSmsScreen> {
  int _page = 0;
  @override
  Widget build(BuildContext context) {
    final summary = ref.watch(yourDataSummaryProvider);
    final dates = ref.watch(storedSmsDatesProvider(_page));
    final count = summary.asData?.value.messages;
    return Scaffold(
      backgroundColor: AppTheme.appBackground,
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.sms_outlined, size: 24),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Stored SMS messages'),
                  Text(
                    'Local source-message history',
                    style: TextStyle(fontSize: 11, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.darkBlue,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        color: AppTheme.teal,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Private by design',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.darkBlue,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Receipt times of locally stored source messages. Bodies, senders and identifiers are hidden. '
                    'These messages are not a count of successful financial transactions.',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: Colors.blueGrey,
                    ),
                  ),
                ],
              ),
            ),
            summary.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, _) => TextButton(
                onPressed: () => ref.invalidate(yourDataSummaryProvider),
                child: const Text('Unable to load count. Retry'),
              ),
              data: (s) => Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${s.messages} stored messages',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.darkBlue,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: dates.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) => Center(
                  child: TextButton(
                    onPressed: () =>
                        ref.invalidate(storedSmsDatesProvider(_page)),
                    child: const Text('Unable to load messages. Retry'),
                  ),
                ),
                data: (rows) => rows.isEmpty
                    ? const Center(
                        child: Text('No stored messages on this page'),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        itemCount: rows.length,
                        itemBuilder: (context, index) => Card(
                          color: Colors.white,
                          surfaceTintColor: Colors.transparent,
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 4,
                            ),
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppTheme.appBackground,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.sms_outlined,
                                color: AppTheme.teal,
                                size: 20,
                              ),
                            ),
                            title: const Text('Stored SMS'),
                            subtitle: Text(
                              DateFormat.yMMMd().add_jm().format(
                                rows[index].toLocal(),
                              ),
                            ),
                          ),
                        ),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: _page == 0
                        ? null
                        : () => setState(() => _page--),
                    child: const Text('Previous'),
                  ),
                  Text('Page ${_page + 1}'),
                  TextButton(
                    onPressed:
                        count == null ||
                            (_page + 1) * YourDataRepository.smsPageSize >=
                                count
                        ? null
                        : () => setState(() => _page++),
                    child: const Text('Next'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

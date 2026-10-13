import 'package:drift/drift.dart';
import '../database/app_database.dart';
import '../models/activity_filter.dart';
import '../models/financial_period.dart';
import '../core/enums/record_subtype.dart';
import '../services/financial_semantics.dart';

class UnspecifiedMovements {
  final double outgoing, incoming;
  final int outgoingCount, incomingCount;
  const UnspecifiedMovements(
    this.outgoing,
    this.incoming,
    this.outgoingCount,
    this.incomingCount,
  );
  static ActivityFilter filter(
    FinancialPeriod period, {
    required bool incoming,
  }) => ActivityFilter(
    period: period,
    subtype: incoming
        ? RecordSubtype.instrumentReceipt
        : RecordSubtype.instrumentPayment,
  );
}

/// Presentation-only aggregation. Does not change canonical financial totals.
class UnspecifiedMovementsRepository {
  final AppDatabase database;
  UnspecifiedMovementsRepository(this.database);
  Stream<UnspecifiedMovements> watch(FinancialPeriod period) => database
      .customSelect(
        '''
    SELECT ${FinancialSemantics.effectiveSubtypeSql('f')} AS subtype,
      COUNT(*) AS n, SUM(f.amount) AS principal
    FROM financial_records f
    WHERE COALESCE(f.transaction_date, f.received_at) >= ?
      AND COALESCE(f.transaction_date, f.received_at) < ?
      AND ${FinancialSemantics.effectiveSubtypeSql('f')} IN ('instrumentPayment', 'instrumentReceipt')
    GROUP BY ${FinancialSemantics.effectiveSubtypeSql('f')}
  ''',
        variables: [
          Variable(period.start.millisecondsSinceEpoch ~/ 1000),
          Variable(period.end.millisecondsSinceEpoch ~/ 1000),
        ],
        readsFrom: {database.financialRecords},
      )
      .watch()
      .map((rows) {
        var outgoing = 0.0, incoming = 0.0;
        var outgoingCount = 0, incomingCount = 0;
        for (final row in rows) {
          if (row.read<String>('subtype') == 'instrumentPayment') {
            outgoing = row.read<double>('principal');
            outgoingCount = row.read<int>('n');
          } else {
            incoming = row.read<double>('principal');
            incomingCount = row.read<int>('n');
          }
        }
        return UnspecifiedMovements(
          outgoing,
          incoming,
          outgoingCount,
          incomingCount,
        );
      });
}

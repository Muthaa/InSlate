import '../models/activity_filter.dart';
import '../models/financial_breakdown.dart';
import '../models/financial_period.dart';
import '../models/financial_records.dart';
import '../core/enums/account_type.dart';
import '../core/enums/record_subtype.dart';
import '../core/presentation/financial_presentation.dart';
import 'financial_semantics.dart';

class FinancialBreakdownService {
  const FinancialBreakdownService();

  static ActivityScope scopeFor(BreakdownKind kind) => switch (kind) {
    BreakdownKind.spending ||
    BreakdownKind.expenseParties => ActivityScope.expenses,
    BreakdownKind.incomeParties ||
    BreakdownKind.incomeCategories => ActivityScope.income,
    BreakdownKind.internalMovement => ActivityScope.internalTransfers,
    BreakdownKind.loans => ActivityScope.loans,
    BreakdownKind.investmentsAndSavings ||
    BreakdownKind.investmentPurchases ||
    BreakdownKind.investmentRedemptions ||
    BreakdownKind.savingsDeposits ||
    BreakdownKind.savingsWithdrawals => ActivityScope.investmentsAndSavings,
  };

  DashboardSummary dashboard(
    List<FinancialRecord> orderedPeriodRecords,
    FinancialPeriod period,
  ) => DashboardSummary(
    period: period,
    totals: const FinancialSemantics().calculate(orderedPeriodRecords),
    breakdowns: {
      for (final kind in BreakdownKind.values)
        kind: calculate(orderedPeriodRecords, (
          kind: kind,
          filter: ActivityFilter(period: period, scope: scopeFor(kind)),
        )),
    },
    recent: orderedPeriodRecords.take(5),
  );

  FinancialBreakdown calculate(
    List<FinancialRecord> records,
    BreakdownQuery query,
  ) {
    final base = query.filter.withScope(scopeFor(query.kind));
    final selectedSubtypes = switch (query.kind) {
      BreakdownKind.investmentPurchases => {RecordSubtype.investmentPurchase},
      BreakdownKind.investmentRedemptions => {
        RecordSubtype.investmentRedemption,
      },
      BreakdownKind.savingsDeposits => {
        RecordSubtype.mshwariDeposit,
        RecordSubtype.kcbDeposit,
      },
      BreakdownKind.savingsWithdrawals => {
        RecordSubtype.mshwariWithdrawal,
        RecordSubtype.kcbWithdrawal,
      },
      _ => null,
    };
    final matched = records
        .where(
          (record) =>
              base.matches(record) &&
              (selectedSubtypes == null ||
                  selectedSubtypes.contains(record.subtype)),
        )
        .toList();
    const semantics = FinancialSemantics();
    final total = matched.fold<double>(0, (sum, record) => sum + record.amount);
    final sectionGroups = <String, Map<ActivityFilter, _Group>>{};
    void add(
      String section,
      String label,
      FinancialRecord record,
      ActivityFilter filter, {
      String? detail,
    }) {
      final group = sectionGroups
          .putIfAbsent(section, () => {})
          .putIfAbsent(filter, () => _Group(label, filter, detail));
      group.amount += record.amount;
      group.fees += record.transactionCost;
      group.count++;
    }

    ActivityFilter child({
      RecordSubtype? subtype,
      PartyIdentity? party,
      PartyPresence? presence,
      TransferDirection? direction,
      AccountEndpoint? endpoint,
      SemanticResolution? resolution,
      ActivityScope? scope,
    }) => ActivityFilter(
      period: base.period,
      scope: scope ?? base.scope,
      subtype: subtype ?? base.subtype,
      party: party ?? base.party,
      partyPresence: presence ?? base.partyPresence,
      resolution: resolution ?? base.resolution,
      direction: direction ?? base.direction,
      endpoint: endpoint ?? base.endpoint,
      central: base.central,
    );
    for (final record in matched) {
      switch (query.kind) {
        case BreakdownKind.spending || BreakdownKind.incomeCategories:
          add(
            'Categories',
            subtypeLabel(record.subtype),
            record,
            child(subtype: record.subtype),
          );
        case BreakdownKind.expenseParties || BreakdownKind.incomeParties:
          final party = record.party;
          add(
            query.kind == BreakdownKind.expenseParties
                ? 'Expense parties'
                : 'Income sources',
            party?.name.trim().isNotEmpty == true
                ? party!.name.trim()
                : 'Unidentified party',
            record,
            child(
              party: party == null ? null : PartyIdentity.fromParty(party),
              presence: party == null ? PartyPresence.unidentified : null,
            ),
            detail: party == null ? null : PartyIdentity.fromParty(party).value,
          );
        case BreakdownKind.loans:
          final label =
              semantics.classify(record) == MovementClass.loanBorrowing
              ? 'Borrowed'
              : 'Repaid';
          add(
            label,
            record.party != null &&
                    record.subtype != RecordSubtype.fulizaLoan &&
                    record.subtype != RecordSubtype.fulizaRepayment
                ? '${record.party!.name.trim()} · ${subtypeLabel(record.subtype)}'
                : subtypeLabel(record.subtype),
            record,
            child(
              subtype: record.subtype,
              party: record.party == null
                  ? null
                  : PartyIdentity.fromParty(record.party!),
              presence: record.party == null
                  ? PartyPresence.unidentified
                  : null,
            ),
            detail: record.party == null
                ? null
                : PartyIdentity.fromParty(record.party!).value,
          );
        case BreakdownKind.internalMovement ||
            BreakdownKind.investmentsAndSavings ||
            BreakdownKind.investmentPurchases ||
            BreakdownKind.investmentRedemptions ||
            BreakdownKind.savingsDeposits ||
            BreakdownKind.savingsWithdrawals:
          final movement = semantics.movement(record);
          final direction = movement.relativeTo(base.central);
          final other = direction == TransferDirection.intoCentral
              ? movement.source
              : direction == TransferDirection.fromCentral
              ? movement.destination
              : null;
          if (other == null) {
            add(
              'Unresolved direction',
              subtypeLabel(record.subtype),
              record,
              child(subtype: record.subtype),
            );
            continue;
          }
          if (query.kind == BreakdownKind.internalMovement) {
            final section = direction == TransferDirection.intoCentral
                ? 'Into ${accountLabel(base.central.type)}'
                : 'From ${accountLabel(base.central.type)}';
            add(
              section,
              '${direction == TransferDirection.intoCentral ? 'From' : 'To'} ${accountLabel(other.type)}',
              record,
              child(
                direction: direction,
                endpoint: AccountEndpoint(other.type),
              ),
            );
          } else {
            final investment = other.type == AccountType.investment;
            final action = direction == TransferDirection.intoCentral
                ? 'Withdrawn'
                : investment
                ? 'Invested'
                : 'Deposited';
            final name =
                investment && record.party?.name.trim().isNotEmpty == true
                ? record.party!.name.trim()
                : accountLabel(other.type);
            add(
              investment ? 'Investments' : 'Savings',
              '$name · $action',
              record,
              child(
                direction: direction,
                endpoint: other,
                subtype: selectedSubtypes == null ? null : record.subtype,
                presence: investment && record.party == null
                    ? PartyPresence.unidentified
                    : null,
              ),
              detail: investment ? other.identity?.value : null,
            );
          }
      }
    }
    List<FinancialGroup> buildGroups(
      Map<ActivityFilter, _Group> items, {
      bool shares = false,
    }) {
      final groups =
          items.values
              .map(
                (group) => FinancialGroup(
                  label: group.label,
                  detail: group.detail,
                  amount: group.amount,
                  fees: group.fees,
                  count: group.count,
                  filter: group.filter,
                  share: shares && total > 0 ? group.amount / total : 0,
                ),
              )
              .toList()
            ..sort((a, b) {
              final amount = b.amount.compareTo(a.amount);
              return amount != 0 ? amount : a.label.compareTo(b.label);
            });
      return groups;
    }

    final preferredSections = switch (query.kind) {
      BreakdownKind.internalMovement => [
        'Into ${accountLabel(base.central.type)}',
        'From ${accountLabel(base.central.type)}',
        'Unresolved direction',
      ],
      BreakdownKind.loans => ['Borrowed', 'Repaid'],
      BreakdownKind.investmentsAndSavings => [
        'Savings',
        'Investments',
        'Unresolved direction',
      ],
      _ => sectionGroups.keys.toList(),
    };
    final sections = [
      for (final label in preferredSections)
        if (sectionGroups.containsKey(label) || label != 'Unresolved direction')
          BreakdownSection(
            label,
            buildGroups(
              sectionGroups[label] ?? {},
              shares:
                  query.kind == BreakdownKind.spending ||
                  query.kind == BreakdownKind.incomeCategories,
            ),
          ),
    ];
    if (query.kind == BreakdownKind.internalMovement ||
        query.kind == BreakdownKind.investmentsAndSavings) {
      final unresolved = <ActivityFilter, _Group>{};
      for (final record in records) {
        if (!base.period.contains(
              record.transactionDate ?? record.receivedAt,
            ) ||
            semantics.classify(record) != MovementClass.unresolved) {
          continue;
        }
        if (query.kind == BreakdownKind.investmentsAndSavings &&
            ![
              RecordSubtype.savingsDeposit,
              RecordSubtype.savingsWithdrawal,
              RecordSubtype.investmentPurchase,
              RecordSubtype.investmentRedemption,
            ].contains(record.subtype)) {
          continue;
        }
        final filter = child(
          subtype: record.subtype,
          scope: ActivityScope.all,
          resolution: SemanticResolution.unresolved,
        );
        if (!filter.matches(record)) continue;
        final group = unresolved.putIfAbsent(
          filter,
          () => _Group(subtypeLabel(record.subtype), filter),
        );
        group.amount += record.amount;
        group.fees += record.transactionCost;
        group.count++;
      }
      if (unresolved.isNotEmpty) {
        sections.add(
          BreakdownSection(
            'Unresolved financial meaning — excluded from totals',
            buildGroups(unresolved),
            includedInTotal: false,
          ),
        );
      }
    }
    return FinancialBreakdown(
      kind: query.kind,
      filter: base,
      sections: sections,
    );
  }
}

class _Group {
  final String label;
  final ActivityFilter filter;
  final String? detail;
  double amount = 0, fees = 0;
  int count = 0;
  _Group(this.label, this.filter, [this.detail]);
}

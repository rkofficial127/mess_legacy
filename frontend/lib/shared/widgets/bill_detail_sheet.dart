import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/constants.dart';
import '../../core/providers/admin_providers.dart';
import '../../core/providers/meal_skip_provider.dart';
import 'shimmer_loading.dart';

enum _EntryType { skipped, messOff, extra }

class _LedgerEntry {
  final DateTime date;
  final String mealType;
  final _EntryType type;
  final String? note;
  const _LedgerEntry(this.date, this.mealType, this.type, {this.note});
}

/// Bottom sheet showing every skipped, mess-off, and extra meal behind a
/// bill's numbers — the "why is my bill this amount" transparency view.
class BillDetailSheet extends ConsumerWidget {
  final String userId;
  final bool isAdminView;
  final int month;
  final int year;
  final ScrollController? scrollController;

  const BillDetailSheet({
    super.key,
    required this.userId,
    required this.isAdminView,
    required this.month,
    required this.year,
    this.scrollController,
  });

  static void show(
    BuildContext context, {
    required String userId,
    required bool isAdminView,
    required int month,
    required int year,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (ctx, scrollCtrl) => BillDetailSheet(
          userId: userId,
          isAdminView: isAdminView,
          month: month,
          year: year,
          scrollController: scrollCtrl,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;

    final skipsAsync = isAdminView
        ? ref.watch(
            adminUserSkipsProvider((userId: userId, month: month, year: year)))
        : ref.watch(monthSkipsProvider((month: month, year: year)));
    final extrasAsync = isAdminView
        ? ref.watch(adminUserExtraMealsProvider(
            (userId: userId, month: month, year: year)))
        : ref.watch(extraMealsProvider((month: month, year: year)));
    final messOffAsync = ref.watch(messOffProvider((month: month, year: year)));

    final loading = skipsAsync.isLoading ||
        extrasAsync.isLoading ||
        messOffAsync.isLoading;
    final error = skipsAsync.hasError
        ? skipsAsync.error
        : (extrasAsync.hasError ? extrasAsync.error : messOffAsync.error);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: cs.outline)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Bill Details',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 16)),
                    Text(DateFormat('MMMM yyyy').format(DateTime(year, month)),
                        style: TextStyle(
                            fontSize: 12, color: cs.onSurfaceVariant)),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: loading
              ? const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: ShimmerCardList(count: 4, cardHeight: 56),
                )
              : error != null
                  ? Center(child: Text('Error: $error'))
                  : _buildLedger(
                      context,
                      cs,
                      scrollController,
                      skipsAsync.valueOrNull ?? [],
                      messOffAsync.valueOrNull ?? [],
                      extrasAsync.valueOrNull ?? [],
                    ),
        ),
      ],
    );
  }

  Widget _buildLedger(
    BuildContext context,
    ColorScheme cs,
    ScrollController? scrollController,
    List skips,
    List messOffs,
    List extras,
  ) {
    final entries = <_LedgerEntry>[
      for (final s in skips) _LedgerEntry(s.date, s.mealType, _EntryType.skipped),
      for (final m in messOffs)
        _LedgerEntry(m.date, m.mealType, _EntryType.messOff, note: m.reason),
      for (final e in extras)
        _LedgerEntry(e.date, e.mealType, _EntryType.extra, note: e.note),
    ]..sort((a, b) => a.date.compareTo(b.date));

    if (entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 40, color: cs.onSurfaceVariant.withOpacity(0.3)),
            const SizedBox(height: 8),
            Text('No skips, mess-off days, or extras this month',
                style: TextStyle(color: cs.onSurfaceVariant)),
          ],
        ),
      );
    }

    return ListView.separated(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemCount: entries.length,
      itemBuilder: (ctx, i) => _LedgerRow(entry: entries[i]),
    );
  }
}

class _LedgerRow extends StatelessWidget {
  final _LedgerEntry entry;
  const _LedgerRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    late IconData icon;
    late Color color;
    late String label;
    switch (entry.type) {
      case _EntryType.skipped:
        icon = Icons.close_rounded;
        color = cs.error;
        label = 'Skipped';
        break;
      case _EntryType.messOff:
        icon = Icons.event_busy_outlined;
        color = cs.onSurfaceVariant;
        label = 'Mess off';
        break;
      case _EntryType.extra:
        icon = Icons.add_circle_outline;
        color = cs.tertiary;
        label = 'Extra';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.outline),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${mealLabel[entry.mealType] ?? entry.mealType} · $label',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14, color: color),
                ),
                if (entry.note != null && entry.note!.isNotEmpty)
                  Text(entry.note!,
                      style:
                          TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
              ],
            ),
          ),
          Text(DateFormat('d MMM').format(entry.date),
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }
}

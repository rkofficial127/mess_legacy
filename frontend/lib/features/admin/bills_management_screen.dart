import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/providers/admin_providers.dart';

class BillsManagementScreen extends ConsumerStatefulWidget {
  const BillsManagementScreen({super.key});

  @override
  ConsumerState<BillsManagementScreen> createState() =>
      _BillsManagementScreenState();
}

class _BillsManagementScreenState
    extends ConsumerState<BillsManagementScreen> {
  late int _month;
  late int _year;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = now.month;
    _year = now.year;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final billsAsync =
        ref.watch(adminBillsProvider((month: _month, year: _year)));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bills'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              avatar: Icon(Icons.calendar_today, size: 14, color: cs.primary),
              label: Text(
                DateFormat('MMM yyyy').format(DateTime(_year, _month)),
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: cs.primary),
              ),
              onPressed: _pickMonth,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _generateAllBills,
        icon: const Icon(Icons.calculate_outlined, size: 20),
        label: const Text('Generate All'),
      ),
      body: billsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _EmptyBillsView(cs: cs, month: _month, year: _year),
        data: (bills) {
          if (bills.isEmpty) {
            return _EmptyBillsView(cs: cs, month: _month, year: _year);
          }

          final totalRevenue =
              bills.fold<double>(0, (s, b) => s + b.finalAmount);
          final totalDeductions =
              bills.fold<double>(0, (s, b) => s + b.deductionAmount);

          return Column(
            children: [
              // Summary row
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Row(
                  children: [
                    _SummaryChip('${bills.length}', 'Users'),
                    const SizedBox(width: 8),
                    _SummaryChip(
                        '₹${totalRevenue.toStringAsFixed(0)}', 'Revenue'),
                    const SizedBox(width: 8),
                    _SummaryChip(
                        '₹${totalDeductions.toStringAsFixed(0)}', 'Deducted'),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemCount: bills.length,
                  itemBuilder: (ctx, i) {
                    final b = bills[i];
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: cs.outline),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: cs.primary.withOpacity(0.1),
                            child: Text(
                              (b.userFullName ?? '?')[0].toUpperCase(),
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: cs.primary,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(b.userFullName ?? 'Unknown',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14)),
                                const SizedBox(height: 2),
                                Text(
                                  '${b.planName} · ${b.skippedMeals} skipped, ${b.messOffMeals} off',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: cs.onSurfaceVariant),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '₹${b.finalAmount.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: cs.primary,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => _regenerateForUser(b.userId),
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.refresh,
                                          size: 12, color: cs.secondary),
                                      const SizedBox(width: 3),
                                      Text('Regen',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: cs.secondary,
                                            fontWeight: FontWeight.w600,
                                          )),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _pickMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(_year, _month),
      firstDate: DateTime(2024),
      lastDate: DateTime(2100),
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );
    if (picked != null) {
      setState(() {
        _month = picked.month;
        _year = picked.year;
      });
    }
  }

  Future<void> _generateAllBills() async {
    try {
      final bills = await generateBills(_month, _year);
      ref.invalidate(adminBillsProvider((month: _month, year: _year)));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${bills.length} bill(s) generated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _regenerateForUser(String userId) async {
    try {
      await generateBillForUser(userId, _month, _year);
      ref.invalidate(adminBillsProvider((month: _month, year: _year)));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bill regenerated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}

class _EmptyBillsView extends StatelessWidget {
  final ColorScheme cs;
  final int month;
  final int year;
  const _EmptyBillsView(
      {required this.cs, required this.month, required this.year});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.receipt_long_outlined,
              size: 48, color: cs.onSurfaceVariant.withOpacity(0.3)),
          const SizedBox(height: 12),
          Text(
            'No bills for ${DateFormat('MMM yyyy').format(DateTime(year, month))}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text('Tap "Generate All" to create them',
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String value;
  final String label;
  const _SummaryChip(this.value, this.label);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: cs.outline),
        ),
        child: Column(
          children: [
            Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center),
            const SizedBox(height: 2),
            Text(label,
                style:
                    TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

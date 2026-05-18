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
              avatar: Icon(Icons.calendar_today, size: 16, color: cs.primary),
              label: Text(
                DateFormat('MMM yyyy').format(DateTime(_year, _month)),
                style:
                    TextStyle(fontWeight: FontWeight.w600, color: cs.primary),
              ),
              onPressed: _pickMonth,
              side: BorderSide(color: cs.primary.withOpacity(0.3)),
              backgroundColor: cs.primaryContainer.withOpacity(0.3),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _generateBills,
        icon: const Icon(Icons.calculate_outlined),
        label: const Text('Generate Bills'),
      ),
      body: billsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.receipt_long_outlined,
                  size: 64, color: cs.onSurfaceVariant.withOpacity(0.3)),
              const SizedBox(height: 16),
              Text(
                'No bills for ${DateFormat('MMM yyyy').format(DateTime(_year, _month))}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text('Tap "Generate Bills" to create them',
                  style: TextStyle(color: cs.onSurfaceVariant)),
            ],
          ),
        ),
        data: (bills) {
          if (bills.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.receipt_long_outlined,
                      size: 64, color: cs.onSurfaceVariant.withOpacity(0.3)),
                  const SizedBox(height: 16),
                  Text('No Bills Yet',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text('Tap "Generate Bills" to create them',
                      style: TextStyle(color: cs.onSurfaceVariant)),
                ],
              ),
            );
          }

          final totalRevenue =
              bills.fold<double>(0, (s, b) => s + b.finalAmount);
          final totalDeductions =
              bills.fold<double>(0, (s, b) => s + b.deductionAmount);

          return Column(
            children: [
              // Summary header
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [cs.primaryContainer, cs.primaryContainer.withOpacity(0.6)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _Stat('Users', '${bills.length}',
                        Icons.people_outline),
                    Container(
                      width: 1,
                      height: 36,
                      color: cs.onPrimaryContainer.withOpacity(0.2),
                    ),
                    _Stat('Revenue', '₹${totalRevenue.toStringAsFixed(0)}',
                        Icons.trending_up),
                    Container(
                      width: 1,
                      height: 36,
                      color: cs.onPrimaryContainer.withOpacity(0.2),
                    ),
                    _Stat(
                        'Deductions',
                        '₹${totalDeductions.toStringAsFixed(0)}',
                        Icons.trending_down),
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
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: cs.outlineVariant.withOpacity(0.5)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: cs.primaryContainer.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.receipt_outlined,
                                size: 20, color: cs.primary),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(b.planName,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600)),
                                const SizedBox(height: 2),
                                Text(
                                  '${b.skippedMeals} skipped, ${b.messOffMeals} mess-off',
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: cs.onSurfaceVariant),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '₹${b.finalAmount.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: cs.primary,
                            ),
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

  Future<void> _generateBills() async {
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
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _Stat(this.label, this.value, this.icon);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Icon(icon, size: 18, color: cs.onPrimaryContainer),
        const SizedBox(height: 6),
        Text(value,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: cs.onPrimaryContainer,
            )),
        Text(label,
            style: TextStyle(
                fontSize: 11, color: cs.onPrimaryContainer.withOpacity(0.7))),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/providers/bill_provider.dart';

class BillScreen extends ConsumerStatefulWidget {
  const BillScreen({super.key});

  @override
  ConsumerState<BillScreen> createState() => _BillScreenState();
}

class _BillScreenState extends ConsumerState<BillScreen> {
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
    final billAsync =
        ref.watch(myBillProvider((month: _month, year: _year)));

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bill'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              avatar: Icon(Icons.calendar_today, size: 16, color: cs.primary),
              label: Text(
                DateFormat('MMM yyyy').format(DateTime(_year, _month)),
                style: TextStyle(
                    fontWeight: FontWeight.w600, color: cs.primary),
              ),
              onPressed: _pickMonth,
              side: BorderSide(color: cs.primary.withOpacity(0.3)),
              backgroundColor: cs.primaryContainer.withOpacity(0.3),
            ),
          ),
        ],
      ),
      body: billAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (bill) {
          if (bill == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.receipt_long_outlined,
                        size: 64,
                        color: cs.onSurfaceVariant.withOpacity(0.3)),
                    const SizedBox(height: 16),
                    Text('No Bill Yet',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text(
                      'Bill for this month has not been generated yet.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Amount hero card
              Container(
                padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [cs.primary, cs.primary.withOpacity(0.85)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: cs.primary.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text('Final Amount',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        )),
                    const SizedBox(height: 8),
                    Text(
                      '₹${bill.finalAmount.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      bill.planName,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Breakdown
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: cs.outlineVariant.withOpacity(0.5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Breakdown',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 16),
                    _BillRow(
                        'Plan Rate', '₹${bill.planRate.toStringAsFixed(0)}'),
                    _BillRow('Total Billable Meals', '${bill.totalMeals}'),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Divider(),
                    ),
                    _BillRow('Meals Skipped', '${bill.skippedMeals}',
                        iconColor: Colors.amber.shade700,
                        icon: Icons.close_rounded),
                    _BillRow('Mess-Off Meals', '${bill.messOffMeals}',
                        iconColor: Colors.grey, icon: Icons.event_busy),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Divider(),
                    ),
                    _BillRow(
                      'Deduction',
                      '-₹${bill.deductionAmount.toStringAsFixed(0)}',
                      valueColor: cs.error,
                    ),
                    const SizedBox(height: 4),
                    _BillRow(
                      'Final Amount',
                      '₹${bill.finalAmount.toStringAsFixed(0)}',
                      bold: true,
                      valueColor: cs.primary,
                    ),
                  ],
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
}

class _BillRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final Color? valueColor;
  final IconData? icon;
  final Color? iconColor;

  const _BillRow(this.label, this.value,
      {this.bold = false, this.valueColor, this.icon, this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(label,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
                )),
          ),
          Text(value,
              style: TextStyle(
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                fontSize: bold ? 18 : 15,
                color: valueColor,
              )),
        ],
      ),
    );
  }
}

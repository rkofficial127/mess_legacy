import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
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
      body: billAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (bill) {
          if (bill == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.receipt_long_outlined,
                      size: 48,
                      color: cs.onSurfaceVariant.withOpacity(0.3)),
                  const SizedBox(height: 12),
                  const Text('No Bill Yet'),
                  const SizedBox(height: 4),
                  Text('Bill has not been generated yet.',
                      style: TextStyle(
                          color: cs.onSurfaceVariant, fontSize: 13)),
                ],
              ),
            );
          }

          final saved = bill.planRate - bill.finalAmount;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Amount
              Center(
                child: Column(
                  children: [
                    Text(
                      '₹${bill.finalAmount.toStringAsFixed(0)}',
                      style: GoogleFonts.inter(
                          fontSize: 40, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('MMMM yyyy')
                          .format(DateTime(_year, _month)),
                      style: TextStyle(
                          color: cs.onSurfaceVariant, fontSize: 14),
                    ),
                    if (saved > 0) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: cs.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'You saved ₹${saved.toStringAsFixed(0)}',
                          style: TextStyle(
                              color: cs.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Breakdown
              Text('Breakdown',
                  style: GoogleFonts.inter(
                      fontSize: 15, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: cs.outline),
                ),
                child: Column(
                  children: [
                    _Row('Base Rate',
                        '₹${bill.planRate.toStringAsFixed(0)}'),
                    _Row('Total Meals', '${bill.totalMeals}'),
                    _Row('Skipped', '-${bill.skippedMeals}',
                        valueColor: cs.error),
                    _Row('Mess Off', '-${bill.messOffMeals}',
                        valueColor: cs.onSurfaceVariant),
                    const Divider(height: 20),
                    _Row('Deduction',
                        '-₹${bill.deductionAmount.toStringAsFixed(0)}',
                        valueColor: cs.error),
                    const SizedBox(height: 4),
                    _Row(
                      'Total Due',
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

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final Color? valueColor;
  const _Row(this.label, this.value, {this.bold = false, this.valueColor});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  color: cs.onSurfaceVariant,
                  fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 14)),
          Text(value,
              style: TextStyle(
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                  fontSize: bold ? 16 : 14,
                  color: valueColor ?? cs.onSurface)),
        ],
      ),
    );
  }
}

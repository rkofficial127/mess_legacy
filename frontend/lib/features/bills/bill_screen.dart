import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/decorations.dart';
import '../../core/providers/bill_provider.dart';
import '../../core/utils/pdf_download.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/widgets/shimmer_loading.dart';

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
    final tt = Theme.of(context).textTheme;
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
        loading: () => const ShimmerBill(),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (bill) {
          if (bill == null) {
            return const EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'No Bill Yet',
              subtitle: 'Bill has not been generated yet.',
            );
          }

          final saved = bill.planRate - bill.finalAmount;
          const successGreen = Color(0xFF22C55E);
          final savingsColor = saved > 200 ? successGreen : cs.primary;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () async {
                    try {
                      await downloadMyBillPdf(
                        month: _month,
                        year: _year,
                        filename:
                            'bill_${DateFormat('MMM_yyyy').format(DateTime(_year, _month))}.pdf',
                      );
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error downloading: $e')),
                        );
                      }
                    }
                  },
                  icon: Icon(Icons.picture_as_pdf_outlined,
                      size: 18, color: cs.primary),
                  label: Text('Download PDF',
                      style: TextStyle(color: cs.primary, fontSize: 13)),
                ),
              ),
              const SizedBox(height: 4),
              // Animated amount
              Center(
                child: Column(
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: bill.finalAmount),
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOut,
                      builder: (context, value, _) => Text(
                        '₹${value.toStringAsFixed(0)}',
                        style: tt.displaySmall?.copyWith(
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('MMMM yyyy')
                          .format(DateTime(_year, _month)),
                      style: tt.bodyMedium
                          ?.copyWith(color: cs.onSurfaceVariant),
                    ),
                    if (saved > 0) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: savingsColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'You saved ₹${saved.toStringAsFixed(0)}',
                          style: TextStyle(
                              color: savingsColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 28),

              const SectionHeader('Breakdown'),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                decoration: AppDecorations.card(cs),
                child: Column(
                  children: [
                    _Row(Icons.account_balance_wallet_outlined,
                        'Base Rate',
                        '₹${bill.planRate.toStringAsFixed(0)}'),
                    const Divider(height: 1),
                    _Row(Icons.restaurant_outlined,
                        'Total Meals', '${bill.totalMeals}'),
                    const Divider(height: 1),
                    _Row(Icons.close_rounded,
                        'Skipped', '-${bill.skippedMeals}',
                        valueColor: cs.error),
                    const Divider(height: 1),
                    _Row(Icons.event_busy_outlined,
                        'Mess Off', '-${bill.messOffMeals}',
                        valueColor: cs.onSurfaceVariant),
                    const Divider(height: 1),
                    _Row(Icons.remove_circle_outline,
                        'Deduction',
                        '-₹${bill.deductionAmount.toStringAsFixed(0)}',
                        valueColor: cs.error),
                    if (bill.extraMealsCount > 0) ...[
                      const Divider(height: 1),
                      _Row(Icons.add_circle_outline,
                          'Extra Meals', '+${bill.extraMealsCount}',
                          valueColor: cs.tertiary),
                      const Divider(height: 1),
                      _Row(Icons.add_circle_outline,
                          'Extra Charge',
                          '+₹${bill.extraMealsAmount.toStringAsFixed(0)}',
                          valueColor: cs.tertiary),
                    ],
                    Divider(height: 1, color: cs.onSurfaceVariant.withOpacity(0.3)),
                    _Row(Icons.receipt_outlined,
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
  final IconData icon;
  final String label;
  final String value;
  final bool bold;
  final Color? valueColor;
  const _Row(this.icon, this.label, this.value,
      {this.bold = false, this.valueColor});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon,
              size: 16,
              color: valueColor ?? cs.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label,
                style: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 14)),
          ),
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

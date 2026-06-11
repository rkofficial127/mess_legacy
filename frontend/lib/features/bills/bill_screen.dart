import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/decorations.dart';
import '../../core/providers/bill_provider.dart';
import '../../core/utils/pdf_download.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/meal_status_card.dart' show savingsGreen;
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
      appBar: AppBar(title: const Text('My Bill')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            child: _monthChips(cs),
          ),
          Expanded(
            child: billAsync.when(
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

                final perMeal = bill.totalMeals > 0
                    ? bill.planRate / bill.totalMeals
                    : 0.0;
                final skipAmt = perMeal * bill.skippedMeals;
                final messAmt = (bill.deductionAmount - skipAmt)
                    .clamp(0.0, double.infinity);

                return ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
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
                              style: tt.displaySmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'due for ${DateFormat('MMMM').format(DateTime(_year, _month))}',
                            style: tt.bodyMedium
                                ?.copyWith(color: cs.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Receipt-style breakdown
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 4, horizontal: 16),
                      decoration: AppDecorations.card(cs),
                      child: Column(
                        children: [
                          _ReceiptRow(
                            label: '${bill.planName} plan',
                            annotation: ' · ${bill.totalMeals} meals',
                            value:
                                '₹${bill.planRate.toStringAsFixed(0)}',
                          ),
                          if (bill.skippedMeals > 0) ...[
                            const Divider(height: 1),
                            _ReceiptRow(
                              label: 'Skipped meals',
                              annotation: ' × ${bill.skippedMeals}',
                              value: '− ₹${skipAmt.round()}',
                              valueColor: savingsGreen,
                            ),
                          ],
                          if (bill.messOffMeals > 0) ...[
                            const Divider(height: 1),
                            _ReceiptRow(
                              label: 'Mess off meals',
                              annotation: ' × ${bill.messOffMeals}',
                              value: '− ₹${messAmt.round()}',
                              valueColor: savingsGreen,
                            ),
                          ],
                          if (bill.extraMealsCount > 0) ...[
                            const Divider(height: 1),
                            _ReceiptRow(
                              label: 'Extra meals',
                              annotation: ' × ${bill.extraMealsCount}',
                              value:
                                  '+ ₹${bill.extraMealsAmount.toStringAsFixed(0)}',
                              valueColor: cs.tertiary,
                            ),
                          ],
                          Divider(
                              height: 1,
                              color:
                                  cs.onSurfaceVariant.withOpacity(0.3)),
                          _ReceiptRow(
                            label: 'Total due',
                            value:
                                '₹${bill.finalAmount.toStringAsFixed(0)}',
                            bold: true,
                            valueColor: cs.primary,
                          ),
                        ],
                      ),
                    ),

                    if (bill.deductionAmount > 0) ...[
                      const SizedBox(height: 10),
                      Center(
                        child: Text.rich(
                          TextSpan(
                            style: tt.bodySmall,
                            children: [
                              const TextSpan(
                                  text:
                                      'Skips and mess-off days reduced your bill by '),
                              TextSpan(
                                text:
                                    '₹${bill.deductionAmount.round()}',
                                style: const TextStyle(
                                    color: savingsGreen,
                                    fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),

                    OutlinedButton.icon(
                      onPressed: _downloadPdf,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: cs.primary,
                        padding:
                            const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.download_outlined, size: 18),
                      label: const Text('Download PDF',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _monthChips(ColorScheme cs) {
    final now = DateTime.now();
    final months =
        List.generate(3, (i) => DateTime(now.year, now.month - 2 + i));
    final inRecent =
        months.any((m) => m.month == _month && m.year == _year);

    return Row(
      children: [
        for (final m in months) ...[
          _chip(
            cs,
            label: DateFormat('MMM').format(m),
            selected: m.month == _month && m.year == _year,
            onTap: () => setState(() {
              _month = m.month;
              _year = m.year;
            }),
          ),
          const SizedBox(width: 6),
        ],
        _chip(
          cs,
          label: inRecent
              ? null
              : DateFormat('MMM yyyy').format(DateTime(_year, _month)),
          icon: Icons.calendar_today,
          selected: !inRecent,
          onTap: _pickMonth,
        ),
      ],
    );
  }

  Widget _chip(ColorScheme cs,
      {String? label,
      IconData? icon,
      required bool selected,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? cs.primary : Colors.transparent,
          border: selected ? null : Border.all(color: cs.outline),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null)
              Icon(icon,
                  size: 13,
                  color: selected ? cs.onPrimary : cs.onSurfaceVariant),
            if (icon != null && label != null) const SizedBox(width: 4),
            if (label != null)
              Text(label,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color:
                          selected ? cs.onPrimary : cs.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadPdf() async {
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

class _ReceiptRow extends StatelessWidget {
  final String label;
  final String? annotation;
  final String value;
  final bool bold;
  final Color? valueColor;

  const _ReceiptRow({
    required this.label,
    this.annotation,
    required this.value,
    this.bold = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text.rich(TextSpan(
              style: TextStyle(
                fontSize: 13,
                color: cs.onSurface,
                fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
              ),
              children: [
                TextSpan(text: label),
                if (annotation != null)
                  TextSpan(
                    text: annotation,
                    style: TextStyle(
                        color: cs.onSurfaceVariant, fontSize: 12),
                  ),
              ],
            )),
          ),
          Text(value,
              style: TextStyle(
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                  fontSize: bold ? 16 : 13,
                  color: valueColor ?? cs.onSurface)),
        ],
      ),
    );
  }
}

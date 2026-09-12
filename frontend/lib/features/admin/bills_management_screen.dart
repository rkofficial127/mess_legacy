import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/providers/admin_providers.dart';
import '../../core/utils/pdf_download.dart';
import '../../shared/widgets/bill_detail_sheet.dart';
import '../../shared/widgets/meal_status_card.dart' show savingsGreen;
import '../../shared/widgets/payment_history_sheet.dart';
import '../../shared/widgets/shimmer_loading.dart';

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
      body: billsAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.only(top: 24),
          child: ShimmerCardList(count: 5),
        ),
        error: (e, _) => _EmptyBillsView(
            cs: cs, month: _month, year: _year, onUserTap: _showUserBillHistory),
        data: (bills) {
          if (bills.isEmpty) {
            return _EmptyBillsView(
                cs: cs, month: _month, year: _year, onUserTap: _showUserBillHistory);
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
                    return GestureDetector(
                      onTap: () => _showUserBillHistory(b.userId, b.userFullName ?? 'Unknown'),
                      child: Container(
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
                                  '${b.planName} · ${b.skippedMeals} skip, ${b.messOffMeals} off${b.extraMealsCount > 0 ? ', ${b.extraMealsCount} extra' : ''}',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: cs.onSurfaceVariant),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '₹${b.finalAmount.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: cs.primary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            onPressed: () => _regenerateForUser(b.userId),
                            icon: Icon(Icons.refresh,
                                size: 18, color: cs.secondary),
                            tooltip: 'Regenerate',
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                                minWidth: 32, minHeight: 32),
                          ),
                        ],
                      ),
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

  void _showUserBillHistory(String userId, String userName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (ctx, scrollCtrl) => _UserBillHistorySheet(
          userId: userId,
          userName: userName,
          scrollController: scrollCtrl,
          currentMonth: _month,
          currentYear: _year,
          onRegenerate: () {
            ref.invalidate(adminBillsProvider((month: _month, year: _year)));
          },
        ),
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

class _EmptyBillsView extends ConsumerWidget {
  final ColorScheme cs;
  final int month;
  final int year;
  final void Function(String userId, String userName) onUserTap;
  const _EmptyBillsView({
    required this.cs,
    required this.month,
    required this.year,
    required this.onUserTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(usersProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
          child: Column(
            children: [
              Icon(Icons.receipt_long_outlined,
                  size: 40, color: cs.onSurfaceVariant.withOpacity(0.3)),
              const SizedBox(height: 10),
              Text(
                'No bills for ${DateFormat('MMM yyyy').format(DateTime(year, month))}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text('Tap a user below to generate their bill',
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
            ],
          ),
        ),
        Expanded(
          child: usersAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.only(top: 8),
              child: ShimmerCardList(count: 4, cardHeight: 56),
            ),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (users) {
              final active = users.where((u) => u.isActive).toList();
              if (active.isEmpty) {
                return Center(
                  child: Text('No active users yet',
                      style: TextStyle(color: cs.onSurfaceVariant)),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemCount: active.length,
                itemBuilder: (ctx, i) {
                  final u = active[i];
                  return InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => onUserTap(u.id, u.fullName),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: cs.outline),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: cs.primary.withOpacity(0.1),
                            child: Text(
                              u.fullName.isNotEmpty
                                  ? u.fullName[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: cs.primary,
                                  fontSize: 13),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(u.fullName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 14)),
                          ),
                          Icon(Icons.chevron_right,
                              size: 18, color: cs.onSurfaceVariant),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
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

class _UserBillHistorySheet extends ConsumerStatefulWidget {
  final String userId;
  final String userName;
  final ScrollController scrollController;
  final int currentMonth;
  final int currentYear;
  final VoidCallback onRegenerate;

  const _UserBillHistorySheet({
    required this.userId,
    required this.userName,
    required this.scrollController,
    required this.currentMonth,
    required this.currentYear,
    required this.onRegenerate,
  });

  @override
  ConsumerState<_UserBillHistorySheet> createState() =>
      _UserBillHistorySheetState();
}

class _UserBillHistorySheetState extends ConsumerState<_UserBillHistorySheet> {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final billsAsync = ref.watch(
      userBillsProvider((userId: widget.userId, month: null, year: null)),
    );
    final balanceAsync = ref.watch(adminUserBalanceProvider(widget.userId));

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: cs.outline)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: cs.primary.withOpacity(0.1),
                    child: Text(
                      widget.userName[0].toUpperCase(),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: cs.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.userName,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 16)),
                        Text('Bill History',
                            style: TextStyle(
                                fontSize: 12, color: cs.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  Flexible(
                    child: FilledButton.tonalIcon(
                      onPressed: () => _generateForUser(),
                      icon: const Icon(Icons.calculate_outlined, size: 16),
                      label: const Text('Generate'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              balanceAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (balance) {
                  final isCredit = balance.balance > 0;
                  final isSettled = balance.balance == 0;
                  final color = isSettled
                      ? cs.onSurfaceVariant
                      : (isCredit ? savingsGreen : cs.error);
                  final label = isSettled
                      ? 'Settled'
                      : (isCredit
                          ? '₹${balance.balance.abs().toStringAsFixed(0)} credit'
                          : '₹${balance.balance.abs().toStringAsFixed(0)} due');
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isSettled
                                ? Icons.check_circle_outline
                                : (isCredit
                                    ? Icons.trending_up
                                    : Icons.error_outline),
                            size: 16,
                            color: color,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(label,
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: color)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Flexible(
                            child: TextButton.icon(
                              onPressed: () => PaymentHistorySheet.show(
                                context,
                                userId: widget.userId,
                                isAdminView: true,
                              ),
                              icon: Icon(Icons.history,
                                  size: 14, color: cs.secondary),
                              label: const Text('History',
                                  style: TextStyle(fontSize: 12)),
                              style: TextButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 6),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: FilledButton.tonalIcon(
                              onPressed: _recordPayment,
                              icon: const Icon(Icons.add, size: 14),
                              label: const Text('Record Payment',
                                  style: TextStyle(fontSize: 12)),
                              style: FilledButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 10),
                                  visualDensity: VisualDensity.compact),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: billsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.only(top: 16),
              child: ShimmerCardList(count: 3, cardHeight: 56),
            ),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (bills) {
              if (bills.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.receipt_long_outlined,
                          size: 40,
                          color: cs.onSurfaceVariant.withOpacity(0.3)),
                      const SizedBox(height: 8),
                      Text('No bills yet',
                          style: TextStyle(color: cs.onSurfaceVariant)),
                    ],
                  ),
                );
              }
              return ListView.separated(
                controller: widget.scrollController,
                padding: const EdgeInsets.all(16),
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemCount: bills.length,
                itemBuilder: (ctx, i) {
                  final b = bills[i];
                  final isLatest = i == 0;
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isLatest ? cs.primary : cs.outline,
                        width: isLatest ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              DateFormat('MMM yyyy')
                                  .format(DateTime(b.year, b.month)),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 14),
                            ),
                            if (isLatest) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: cs.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text('Latest',
                                    style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: cs.primary)),
                              ),
                            ],
                            const Spacer(),
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
                        const SizedBox(height: 6),
                        Text(
                          '${b.planName} · ${b.skippedMeals} skip, ${b.messOffMeals} off${b.extraMealsCount > 0 ? ', ${b.extraMealsCount} extra' : ''}',
                          style: TextStyle(
                              fontSize: 12, color: cs.onSurfaceVariant),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Base ₹${b.planRate.toStringAsFixed(0)} · Deduction ₹${b.deductionAmount.toStringAsFixed(0)}${b.extraMealsAmount > 0 ? ' · Extra ₹${b.extraMealsAmount.toStringAsFixed(0)}' : ''}',
                                style: TextStyle(
                                    fontSize: 11, color: cs.onSurfaceVariant),
                              ),
                            ),
                            Text(
                              DateFormat('dd MMM, HH:mm').format(b.generatedAt),
                              style: TextStyle(
                                  fontSize: 10, color: cs.onSurfaceVariant),
                            ),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () => BillDetailSheet.show(
                                context,
                                userId: widget.userId,
                                isAdminView: true,
                                month: b.month,
                                year: b.year,
                              ),
                              child: Icon(Icons.receipt_long_outlined,
                                  size: 16, color: cs.secondary),
                            ),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () async {
                                try {
                                  await downloadBillPdf(
                                    billId: b.id,
                                    filename:
                                        'bill_${widget.userName.replaceAll(' ', '_')}_${DateFormat('MMM_yyyy').format(DateTime(b.year, b.month))}.pdf',
                                  );
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Error: $e')),
                                    );
                                  }
                                }
                              },
                              child: Icon(Icons.picture_as_pdf_outlined,
                                  size: 16, color: cs.primary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _generateForUser() async {
    try {
      await generateBillForUser(
          widget.userId, widget.currentMonth, widget.currentYear);
      ref.invalidate(userBillsProvider(
          (userId: widget.userId, month: null, year: null)));
      widget.onRegenerate();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bill generated')),
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

  Future<void> _recordPayment() async {
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          title: const Text('Record Payment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Amount (₹)'),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: dialogCtx,
                    initialDate: selectedDate,
                    firstDate: DateTime(2024),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) setDialogState(() => selectedDate = picked);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Date'),
                  child: Text(DateFormat('d MMM yyyy').format(selectedDate)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteCtrl,
                decoration: const InputDecoration(labelText: 'Note (optional)'),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogCtx, false),
                child: const Text('Cancel')),
            FilledButton(
                onPressed: () => Navigator.pop(dialogCtx, true),
                child: const Text('Record')),
          ],
        ),
      ),
    );

    if (confirmed != true) return;
    final amount = double.tryParse(amountCtrl.text.trim());
    if (amount == null || amount <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Enter a valid amount')));
      }
      return;
    }

    try {
      await recordPayment(
        userId: widget.userId,
        amount: amount,
        date: selectedDate,
        note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
      );
      ref.invalidate(adminUserBalanceProvider(widget.userId));
      ref.invalidate(adminUserPaymentsProvider(widget.userId));
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Payment recorded')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}

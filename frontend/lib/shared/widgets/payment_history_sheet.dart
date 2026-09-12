import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/models/payment.dart';
import '../../core/providers/admin_providers.dart';
import '../../core/providers/payment_provider.dart';
import 'shimmer_loading.dart';

class PaymentHistorySheet extends ConsumerWidget {
  final String userId;
  final bool isAdminView;
  final ScrollController? scrollController;

  const PaymentHistorySheet({
    super.key,
    required this.userId,
    required this.isAdminView,
    this.scrollController,
  });

  static void show(
    BuildContext context, {
    required String userId,
    required bool isAdminView,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.35,
        expand: false,
        builder: (ctx, scrollCtrl) => PaymentHistorySheet(
          userId: userId,
          isAdminView: isAdminView,
          scrollController: scrollCtrl,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final paymentsAsync = isAdminView
        ? ref.watch(adminUserPaymentsProvider(userId))
        : ref.watch(myPaymentsProvider);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: cs.outline)),
          ),
          child: const Row(
            children: [
              Expanded(
                child: Text('Payment History',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              ),
            ],
          ),
        ),
        Expanded(
          child: paymentsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.only(top: 16),
              child: ShimmerCardList(count: 4, cardHeight: 56),
            ),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (payments) {
              if (payments.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.payments_outlined,
                          size: 40, color: cs.onSurfaceVariant.withOpacity(0.3)),
                      const SizedBox(height: 8),
                      Text('No payments recorded yet',
                          style: TextStyle(color: cs.onSurfaceVariant)),
                    ],
                  ),
                );
              }
              return ListView.separated(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemCount: payments.length,
                itemBuilder: (ctx, i) => _PaymentRow(
                  payment: payments[i],
                  onDelete: isAdminView
                      ? () async {
                          await deletePayment(payments[i].id);
                          ref.invalidate(adminUserPaymentsProvider(userId));
                          ref.invalidate(adminUserBalanceProvider(userId));
                        }
                      : null,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PaymentRow extends StatelessWidget {
  final Payment payment;
  final Future<void> Function()? onDelete;
  const _PaymentRow({required this.payment, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.outline),
      ),
      child: Row(
        children: [
          Icon(Icons.payments_outlined, size: 18, color: cs.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('₹${payment.amount.toStringAsFixed(0)}',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14, color: cs.primary)),
                if (payment.note != null && payment.note!.isNotEmpty)
                  Text(payment.note!,
                      style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
              ],
            ),
          ),
          Text(DateFormat('d MMM yyyy').format(payment.date),
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
          if (onDelete != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onDelete,
              child: Icon(Icons.delete_outline, size: 18, color: cs.error),
            ),
          ],
        ],
      ),
    );
  }
}

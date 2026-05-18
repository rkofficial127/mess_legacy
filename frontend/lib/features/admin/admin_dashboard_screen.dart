import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/providers/admin_providers.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final usersAsync = ref.watch(usersProvider);
    final plansAsync = ref.watch(plansProvider);
    final now = DateTime.now();
    final billsAsync =
        ref.watch(adminBillsProvider((month: now.month, year: now.year)));

    return Scaffold(
      body: RefreshIndicator(
        color: cs.primary,
        onRefresh: () async {
          ref.invalidate(usersProvider);
          ref.invalidate(plansProvider);
          ref.invalidate(
              adminBillsProvider((month: now.month, year: now.year)));
        },
        child: ListView(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 20,
            left: 20,
            right: 20,
            bottom: 20,
          ),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Admin',
                      style: GoogleFonts.inter(
                          fontSize: 24, fontWeight: FontWeight.w700)),
                ),
                IconButton(
                  icon: Icon(Icons.refresh, color: cs.onSurfaceVariant),
                  onPressed: () {
                    ref.invalidate(usersProvider);
                    ref.invalidate(plansProvider);
                    ref.invalidate(adminBillsProvider(
                        (month: now.month, year: now.year)));
                  },
                ),
                IconButton(
                  icon: Icon(Icons.person_outline, color: cs.onSurfaceVariant),
                  onPressed: () => context.go('/profile'),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Stats row
            Row(
              children: [
                _StatChip(
                  usersAsync.when(
                    data: (u) => '${u.where((x) => x.isActive).length}',
                    loading: () => '-',
                    error: (_, __) => '-',
                  ),
                  'Users',
                ),
                const SizedBox(width: 8),
                _StatChip(
                  plansAsync.when(
                    data: (p) => '${p.length}',
                    loading: () => '-',
                    error: (_, __) => '-',
                  ),
                  'Plans',
                ),
                const SizedBox(width: 8),
                _StatChip(
                  billsAsync.when(
                    data: (b) => '${b.length}',
                    loading: () => '-',
                    error: (_, __) => '0',
                  ),
                  'Bills',
                ),
                const SizedBox(width: 8),
                _StatChip(
                  billsAsync.when(
                    data: (b) {
                      final total = b.fold<double>(
                          0, (s, bill) => s + bill.finalAmount);
                      return '₹${total.toStringAsFixed(0)}';
                    },
                    loading: () => '-',
                    error: (_, __) => '-',
                  ),
                  'Revenue',
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Meal Plans
            Text('Meal Plans',
                style: GoogleFonts.inter(
                    fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            if (plansAsync.hasValue)
              ...plansAsync.value!.map((p) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: cs.outline),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          p.foodType == 'VEG'
                              ? Icons.eco_outlined
                              : Icons.restaurant_outlined,
                          color: cs.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: 2),
                              Text(
                                '${p.foodType} · ${p.mealsPerDay} meals/day',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: cs.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '₹${p.monthlyRate.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: cs.primary,
                          ),
                        ),
                      ],
                    ),
                  )),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String value;
  final String label;
  const _StatChip(this.value, this.label);

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

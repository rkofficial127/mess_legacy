import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
        onRefresh: () async {
          ref.invalidate(usersProvider);
          ref.invalidate(plansProvider);
          ref.invalidate(
              adminBillsProvider((month: now.month, year: now.year)));
        },
        child: CustomScrollView(
          slivers: [
            // Admin header
            SliverToBoxAdapter(
              child: Container(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 16,
                  left: 20,
                  right: 20,
                  bottom: 24,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [cs.primary, cs.primary.withOpacity(0.85)],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('Admin Dashboard',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            )),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.refresh, color: Colors.white),
                          onPressed: () {
                            ref.invalidate(usersProvider);
                            ref.invalidate(plansProvider);
                            ref.invalidate(adminBillsProvider(
                                (month: now.month, year: now.year)));
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        _HeroStat(
                          icon: Icons.people_outline,
                          value: usersAsync.when(
                            data: (u) =>
                                '${u.where((x) => x.isActive).length}',
                            loading: () => '-',
                            error: (_, __) => '-',
                          ),
                          label: 'Users',
                        ),
                        const SizedBox(width: 12),
                        _HeroStat(
                          icon: Icons.restaurant_menu,
                          value: plansAsync.when(
                            data: (p) => '${p.length}',
                            loading: () => '-',
                            error: (_, __) => '-',
                          ),
                          label: 'Plans',
                        ),
                        const SizedBox(width: 12),
                        _HeroStat(
                          icon: Icons.receipt_long_outlined,
                          value: billsAsync.when(
                            data: (b) => '${b.length}',
                            loading: () => '-',
                            error: (_, __) => '0',
                          ),
                          label: 'Bills',
                        ),
                        const SizedBox(width: 12),
                        _HeroStat(
                          icon: Icons.currency_rupee,
                          value: billsAsync.when(
                            data: (b) {
                              final total = b.fold<double>(
                                  0, (s, bill) => s + bill.finalAmount);
                              return '₹${total.toStringAsFixed(0)}';
                            },
                            loading: () => '-',
                            error: (_, __) => '-',
                          ),
                          label: 'Revenue',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Meal plans
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Text('Meal Plans',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  if (plansAsync.hasValue)
                    ...plansAsync.value!.map((p) => Container(
                          margin: const EdgeInsets.only(bottom: 10),
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
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: cs.primaryContainer.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  p.foodType == 'VEG'
                                      ? Icons.eco_outlined
                                      : Icons.restaurant_outlined,
                                  color: cs.primary,
                                  size: 22,
                                ),
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
                                      '${p.foodType} • ${p.mealsPerDay} meals/day',
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
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _HeroStat({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(height: 8),
            Text(value,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                )),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 11,
                )),
          ],
        ),
      ),
    );
  }
}

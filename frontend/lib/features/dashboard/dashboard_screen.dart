import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/constants.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/meal_skip_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isSunday = now.weekday == DateTime.sunday;
    final cs = Theme.of(context).colorScheme;

    final subAsync = ref.watch(subscriptionProvider);
    final skipsAsync =
        ref.watch(monthSkipsProvider((month: now.month, year: now.year)));
    final messOffAsync =
        ref.watch(messOffProvider((month: now.month, year: now.year)));

    return Scaffold(
      body: subAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (sub) {
          if (sub == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.no_meals_outlined,
                        size: 64, color: cs.onSurfaceVariant.withOpacity(0.5)),
                    const SizedBox(height: 16),
                    Text('No Active Plan',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text(
                      'Contact your admin to get a meal plan assigned for this month.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            );
          }

          final mealsPerDay = sub.planMealsPerDay ?? 2;
          List<String> todayMeals;
          if (isSunday) {
            todayMeals = ['LUNCH'];
          } else if (mealsPerDay == 2) {
            todayMeals = ['LUNCH', 'DINNER'];
          } else {
            todayMeals = ['BREAKFAST', 'LUNCH', 'DINNER'];
          }

          return skipsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (skips) {
              final todaySkips = skips
                  .where((s) =>
                      s.date.year == today.year &&
                      s.date.month == today.month &&
                      s.date.day == today.day)
                  .toList();

              final messOffs = messOffAsync.valueOrNull ?? [];
              final todayMessOff = messOffs
                  .where((m) =>
                      m.date.year == today.year &&
                      m.date.month == today.month &&
                      m.date.day == today.day)
                  .toList();
              final isFullDayOff =
                  todayMessOff.any((m) => m.mealType == 'ALL');

              final totalSkips = skips.length;
              final totalMessOff = messOffs.length;

              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(subscriptionProvider);
                  ref.invalidate(
                      monthSkipsProvider((month: now.month, year: now.year)));
                  ref.invalidate(
                      messOffProvider((month: now.month, year: now.year)));
                },
                child: CustomScrollView(
                  slivers: [
                    // Greeting header
                    SliverToBoxAdapter(
                      child: Container(
                        padding: EdgeInsets.only(
                          top: MediaQuery.of(context).padding.top + 16,
                          left: 20,
                          right: 20,
                          bottom: 20,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              cs.primary,
                              cs.primary.withOpacity(0.85),
                            ],
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _greeting(),
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.8),
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        auth.user?.fullName ?? 'User',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 24,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    DateFormat('d MMM').format(now),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            // Quick stats row
                            Row(
                              children: [
                                _QuickStat(
                                  label: 'Plan',
                                  value: sub.planName ?? '-',
                                ),
                                Container(
                                  width: 1,
                                  height: 32,
                                  color: Colors.white.withOpacity(0.3),
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                ),
                                _QuickStat(
                                  label: 'Rate',
                                  value:
                                      '₹${sub.planMonthlyRate?.toStringAsFixed(0) ?? '-'}',
                                ),
                                Container(
                                  width: 1,
                                  height: 32,
                                  color: Colors.white.withOpacity(0.3),
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                ),
                                _QuickStat(
                                  label: 'Skipped',
                                  value: '$totalSkips',
                                ),
                                Container(
                                  width: 1,
                                  height: 32,
                                  color: Colors.white.withOpacity(0.3),
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                ),
                                _QuickStat(
                                  label: 'Mess Off',
                                  value: '$totalMessOff',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    SliverPadding(
                      padding: const EdgeInsets.all(20),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          // Mess-off banner
                          if (isFullDayOff) ...[
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: cs.errorContainer,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(children: [
                                Icon(Icons.event_busy,
                                    color: cs.onErrorContainer),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('Mess is off today',
                                          style: TextStyle(
                                            color: cs.onErrorContainer,
                                            fontWeight: FontWeight.w600,
                                          )),
                                      if (todayMessOff.first.reason != null)
                                        Text(todayMessOff.first.reason!,
                                            style: TextStyle(
                                                color: cs.onErrorContainer
                                                    .withOpacity(0.8),
                                                fontSize: 13)),
                                    ],
                                  ),
                                ),
                              ]),
                            ),
                            const SizedBox(height: 20),
                          ],

                          if (!isFullDayOff) ...[
                            Row(
                              children: [
                                Text("Today's Meals",
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium),
                                const Spacer(),
                                Text(
                                  DateFormat('EEEE').format(now),
                                  style: TextStyle(
                                    color: cs.onSurfaceVariant,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ...todayMeals.map((meal) {
                              final isMessOff = todayMessOff.any(
                                  (m) => m.mealType == meal || m.mealType == 'ALL');
                              final skip = todaySkips
                                  .where((s) => s.mealType == meal)
                                  .firstOrNull;
                              final isSkipped = skip != null;

                              return _MealCard(
                                mealType: meal,
                                isSkipped: isSkipped,
                                isMessOff: isMessOff,
                                skipId: skip?.id,
                                date: today,
                                onChanged: () {
                                  ref.invalidate(monthSkipsProvider(
                                      (month: now.month, year: now.year)));
                                },
                              );
                            }),
                            const SizedBox(height: 8),
                          ],

                          if (isSunday)
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color:
                                    cs.tertiaryContainer.withOpacity(0.4),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.info_outline,
                                      size: 20,
                                      color: cs.onTertiaryContainer),
                                  const SizedBox(width: 10),
                                  Text('Only lunch is served on Sundays',
                                      style: TextStyle(
                                          color: cs.onTertiaryContainer,
                                          fontSize: 13)),
                                ],
                              ),
                            ),
                        ]),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }
}

class _QuickStat extends StatelessWidget {
  final String label;
  final String value;
  const _QuickStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
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
    );
  }
}

class _MealCard extends StatelessWidget {
  final String mealType;
  final bool isSkipped;
  final bool isMessOff;
  final String? skipId;
  final DateTime date;
  final VoidCallback onChanged;

  const _MealCard({
    required this.mealType,
    required this.isSkipped,
    required this.isMessOff,
    this.skipId,
    required this.date,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final emoji = mealEmoji[mealType] ?? '';
    final label = mealLabel[mealType] ?? mealType;

    Color cardColor;
    Color accentColor;
    String statusText;
    IconData statusIcon;

    if (isMessOff) {
      cardColor = cs.surfaceContainerHighest;
      accentColor = cs.onSurfaceVariant;
      statusText = 'Mess Off';
      statusIcon = Icons.event_busy_outlined;
    } else if (isSkipped) {
      cardColor = cs.errorContainer.withOpacity(0.5);
      accentColor = cs.error;
      statusText = 'Skipped';
      statusIcon = Icons.close_rounded;
    } else {
      cardColor = cs.primaryContainer.withOpacity(0.4);
      accentColor = cs.primary;
      statusText = 'Taking';
      statusIcon = Icons.check_circle_outline;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accentColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 32)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 16)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(statusIcon, size: 14, color: accentColor),
                    const SizedBox(width: 4),
                    Text(statusText,
                        style: TextStyle(
                            color: accentColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ],
            ),
          ),
          if (!isMessOff)
            FilledButton.tonal(
              onPressed: () async {
                try {
                  if (isSkipped && skipId != null) {
                    await cancelSkip(skipId!);
                  } else {
                    await createSkip(date, mealType);
                  }
                  onChanged();
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.toString())),
                    );
                  }
                }
              },
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 40),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(isSkipped ? 'Undo' : 'Skip',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
        ],
      ),
    );
  }
}

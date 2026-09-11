import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/decorations.dart';
import '../../core/constants.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/delivery_status_provider.dart';
import '../../core/providers/meal_skip_provider.dart';
import '../../core/utils/meal_cutoff.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/meal_status_card.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/widgets/shimmer_loading.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with TickerProviderStateMixin {
  late final AnimationController _fadeController;
  Timer? _countdownTimer;
  bool _heroLoading = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _countdownTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => setState(() {}),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  int _totalMealsInMonth(int month, int year, int mealsPerDay) {
    final days = DateTime(year, month + 1, 0).day;
    var total = 0;
    for (var d = 1; d <= days; d++) {
      total +=
          DateTime(year, month, d).weekday == DateTime.sunday ? 1 : mealsPerDay;
    }
    return total;
  }

  Future<void> _skipMeal(String meal) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    HapticFeedback.mediumImpact();
    setState(() => _heroLoading = true);
    try {
      await createSkip(today, meal);
      ref.invalidate(monthSkipsProvider((month: now.month, year: now.year)));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${mealLabel[meal]} skipped'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () async {
              final freshSkips = await ref.read(
                  monthSkipsProvider((month: now.month, year: now.year))
                      .future);
              final newSkip = freshSkips
                  .where((s) =>
                      s.mealType == meal && s.date.day == today.day)
                  .firstOrNull;
              if (newSkip != null) {
                await cancelSkip(newSkip.id);
                ref.invalidate(
                    monthSkipsProvider((month: now.month, year: now.year)));
              }
            },
          ),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _heroLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isSunday = now.weekday == DateTime.sunday;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final subAsync = ref.watch(subscriptionProvider);
    final skipsAsync =
        ref.watch(monthSkipsProvider((month: now.month, year: now.year)));
    final messOffAsync =
        ref.watch(messOffProvider((month: now.month, year: now.year)));
    final deliveryStatusAsync = ref.watch(myDeliveryStatusProvider);

    return Scaffold(
      body: subAsync.when(
        loading: () => const ShimmerDashboard(),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (sub) {
          if (sub == null) {
            return const EmptyState(
              icon: Icons.no_meals_outlined,
              title: 'No Active Plan',
              subtitle: 'Contact your admin to get a meal plan assigned.',
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

          final perMeal = sub.planMonthlyRate != null
              ? sub.planMonthlyRate! /
                  _totalMealsInMonth(now.month, now.year, mealsPerDay)
              : null;

          return skipsAsync.when(
            loading: () => const ShimmerDashboard(),
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

              final messOffMealCount = messOffs.fold<int>(0, (sum, m) {
                if (m.mealType == 'ALL') {
                  return sum +
                      (m.date.weekday == DateTime.sunday ? 1 : mealsPerDay);
                }
                return sum + 1;
              });
              final savings = perMeal != null
                  ? perMeal * (totalSkips + messOffMealCount)
                  : null;

              void invalidateSkips() {
                ref.invalidate(
                    monthSkipsProvider((month: now.month, year: now.year)));
              }

              bool isActionable(String meal) {
                final isMessOff = todayMessOff.any(
                    (m) => m.mealType == meal || m.mealType == 'ALL');
                final isSkipped =
                    todaySkips.any((s) => s.mealType == meal);
                return !isMessOff &&
                    !isSkipped &&
                    !isMealCutoffPassed(meal, today);
              }

              final hero = isFullDayOff
                  ? null
                  : todayMeals.where(isActionable).firstOrNull;
              final rest = todayMeals.where((m) => m != hero).toList()
                ..sort((a, b) => (isActionable(b) ? 1 : 0)
                    .compareTo(isActionable(a) ? 1 : 0));

              Widget mealCard(String meal) {
                final isMessOff = todayMessOff.any(
                    (m) => m.mealType == meal || m.mealType == 'ALL');
                final skip = todaySkips
                    .where((s) => s.mealType == meal)
                    .firstOrNull;
                final isSkipped = skip != null;
                final frozen = isMealCutoffPassed(meal, today);
                final canSwipe = !isMessOff && !frozen && !isSkipped;
                final isDelivered =
                    deliveryStatusAsync.valueOrNull?[meal] ?? false;

                final card = MealStatusCard(
                  mealType: meal,
                  isSkipped: isSkipped,
                  isMessOff: isMessOff,
                  isFrozen: frozen,
                  isDelivered: isDelivered,
                  skipId: skip?.id,
                  date: today,
                  perMealValue: perMeal,
                  onSkip: (date, mealType) => createSkip(date, mealType),
                  onUndo: (skipId) => cancelSkip(skipId),
                  onChanged: invalidateSkips,
                );

                if (!canSwipe) return card;
                return Dismissible(
                  key: ValueKey('dismiss_$meal'),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (_) async {
                    await _skipMeal(meal);
                    return false;
                  },
                  background: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: cs.error.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Skip',
                            style: TextStyle(
                                color: cs.error,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(width: 8),
                        Icon(Icons.chevron_left, color: cs.error, size: 20),
                      ],
                    ),
                  ),
                  child: card,
                );
              }

              return RefreshIndicator(
                color: cs.primary,
                onRefresh: () async {
                  HapticFeedback.mediumImpact();
                  ref.invalidate(subscriptionProvider);
                  ref.invalidate(
                      monthSkipsProvider((month: now.month, year: now.year)));
                  ref.invalidate(
                      messOffProvider((month: now.month, year: now.year)));
                  ref.invalidate(myDeliveryStatusProvider);
                },
                child: FadeTransition(
                  opacity: CurvedAnimation(
                      parent: _fadeController, curve: Curves.easeOut),
                  child: ListView(
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top + 20,
                      left: 20,
                      right: 20,
                      bottom: 20,
                    ),
                    children: [
                      Text(_greeting(), style: tt.bodySmall),
                      const SizedBox(height: 2),
                      Text(
                        auth.user?.fullName ?? 'User',
                        style: tt.headlineSmall,
                      ),
                      const SizedBox(height: 2),
                      Text(DateFormat('EEEE, d MMMM').format(now),
                          style: tt.bodySmall),
                      const SizedBox(height: 10),

                      // Plan pill
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: cs.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${sub.planName ?? '-'} · ₹${sub.planMonthlyRate?.toStringAsFixed(0) ?? '-'}/mo',
                            style: TextStyle(
                                color: cs.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // This-month summary strip
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: AppDecorations.card(cs),
                        child: Row(
                          children: [
                            Text('This month', style: tt.bodySmall),
                            const Spacer(),
                            Text.rich(TextSpan(
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w600),
                              children: [
                                TextSpan(
                                    text: '$totalSkips skipped',
                                    style:
                                        TextStyle(color: cs.onSurface)),
                                if (savings != null) ...[
                                  TextSpan(
                                      text: ' · ',
                                      style: TextStyle(
                                          color: cs.onSurfaceVariant)),
                                  TextSpan(
                                      text:
                                          '₹${savings.round()} saved',
                                      style: const TextStyle(
                                          color: savingsGreen)),
                                ],
                              ],
                            )),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Mess-off banner
                      if (isFullDayOff) ...[
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: cs.errorContainer,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(children: [
                            Icon(Icons.event_busy,
                                size: 20, color: cs.onErrorContainer),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Mess is off today',
                                      style: TextStyle(
                                          color: cs.onErrorContainer,
                                          fontWeight: FontWeight.w600)),
                                  if (todayMessOff.first.reason != null)
                                    Text(todayMessOff.first.reason!,
                                        style: TextStyle(
                                            color: cs.onErrorContainer
                                                .withOpacity(0.7),
                                            fontSize: 13)),
                                ],
                              ),
                            ),
                          ]),
                        ),
                        const SizedBox(height: 20),
                      ],

                      if (!isFullDayOff) ...[
                        if (hero != null) ...[
                          _UpNextCard(
                            meal: hero,
                            date: today,
                            perMealValue: perMeal,
                            loading: _heroLoading,
                            onSkip: () => _skipMeal(hero),
                          ),
                          if (rest.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            SectionHeader(
                              'Later today',
                              trailing: Text(
                                  DateFormat('EEEE').format(now),
                                  style: tt.bodySmall),
                            ),
                            const SizedBox(height: 12),
                            ...rest.map(mealCard),
                          ],
                        ] else ...[
                          SectionHeader(
                            "Today's Meals",
                            trailing: Text(DateFormat('EEEE').format(now),
                                style: tt.bodySmall),
                          ),
                          const SizedBox(height: 12),
                          ...todayMeals.map(mealCard),
                        ],
                      ],

                      if (isSunday)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text('Only lunch is served on Sundays',
                              style: tt.bodySmall),
                        ),
                    ],
                  ),
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

class _UpNextCard extends StatelessWidget {
  final String meal;
  final DateTime date;
  final double? perMealValue;
  final bool loading;
  final VoidCallback onSkip;

  const _UpNextCard({
    required this.meal,
    required this.date,
    required this.perMealValue,
    required this.loading,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final deadline = skipDeadlineLabel(meal, date);
    final serving = mealServingTime[meal];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.primary.withOpacity(0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('UP NEXT',
              style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 1,
                  color: cs.primary,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(mealLabel[meal] ?? meal,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600)),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: cs.tertiary.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('Skip by $deadline',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: cs.tertiary)),
              ),
            ],
          ),
          if (serving != null) ...[
            const SizedBox(height: 3),
            Text('Served $serving', style: tt.bodySmall),
          ],
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: loading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(8),
                      child: SizedBox(
                          width: 20,
                          height: 20,
                          child:
                              CircularProgressIndicator(strokeWidth: 2)),
                    ),
                  )
                : FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: cs.primary.withOpacity(0.15),
                      foregroundColor: cs.primary,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onPressed: onSkip,
                    child: Text(
                      perMealValue != null
                          ? 'Skip this meal · saves ₹${perMealValue!.round()}'
                          : 'Skip this meal',
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

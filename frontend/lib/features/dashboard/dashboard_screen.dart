import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/constants.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/meal_skip_provider.dart';
import '../../core/utils/meal_cutoff.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/meal_status_card.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/widgets/shimmer_loading.dart';
import '../../shared/widgets/stat_chip.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with TickerProviderStateMixin {
  late final AnimationController _fadeController;
  Timer? _countdownTimer;

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
              final totalMessOff = messOffs.length;

              void invalidateSkips() {
                ref.invalidate(
                    monthSkipsProvider((month: now.month, year: now.year)));
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
                      // Greeting + name
                      Text(_greeting(),
                          style: tt.bodySmall),
                      const SizedBox(height: 2),
                      Text(
                        auth.user?.fullName ?? 'User',
                        style: tt.headlineSmall,
                      ),
                      const SizedBox(height: 2),
                      // Date + plan inline
                      Text(
                        '${DateFormat('EEEE, d MMMM').format(now)} · ${sub.planName ?? '-'} · ₹${sub.planMonthlyRate?.toStringAsFixed(0) ?? '-'}/mo',
                        style: tt.bodySmall,
                      ),
                      const SizedBox(height: 20),

                      // Stats — 2 chips
                      Row(
                        children: [
                          StatChip('$totalSkips', 'Skipped',
                              accentColor:
                                  totalSkips > 0 ? cs.error : null),
                          const SizedBox(width: 8),
                          StatChip('$totalMessOff', 'Mess Off'),
                        ],
                      ),
                      const SizedBox(height: 24),

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
                        SectionHeader(
                          "Today's Meals",
                          trailing: Text(DateFormat('EEEE').format(now),
                              style: tt.bodySmall),
                        ),
                        const SizedBox(height: 12),

                        // Meal cards with swipe-to-skip
                        ...todayMeals.map((meal) {
                          final isMessOff = todayMessOff.any((m) =>
                              m.mealType == meal || m.mealType == 'ALL');
                          final skip = todaySkips
                              .where((s) => s.mealType == meal)
                              .firstOrNull;
                          final isSkipped = skip != null;
                          final frozen = isMealCutoffPassed(meal, today);
                          final canSwipe =
                              !isMessOff && !frozen && !isSkipped;

                          final card = MealStatusCard(
                            mealType: meal,
                            isSkipped: isSkipped,
                            isMessOff: isMessOff,
                            isFrozen: frozen,
                            skipId: skip?.id,
                            date: today,
                            showCountdown: true,
                            onSkip: (date, mealType) =>
                                createSkip(date, mealType),
                            onUndo: (skipId) => cancelSkip(skipId),
                            onChanged: invalidateSkips,
                          );

                          if (canSwipe) {
                            return Dismissible(
                              key: ValueKey('dismiss_$meal'),
                              direction: DismissDirection.endToStart,
                              confirmDismiss: (_) async {
                                HapticFeedback.mediumImpact();
                                try {
                                  await createSkip(today, meal);
                                  invalidateSkips();
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(SnackBar(
                                      content: Text(
                                          '${mealLabel[meal]} skipped'),
                                      action: SnackBarAction(
                                        label: 'Undo',
                                        onPressed: () async {
                                          final freshSkips =
                                              await ref.read(
                                                  monthSkipsProvider((
                                                      month: now.month,
                                                      year: now.year))
                                                  .future);
                                          final newSkip = freshSkips
                                              .where((s) =>
                                                  s.mealType == meal &&
                                                  s.date.day == today.day)
                                              .firstOrNull;
                                          if (newSkip != null) {
                                            await cancelSkip(newSkip.id);
                                            invalidateSkips();
                                          }
                                        },
                                      ),
                                    ));
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(SnackBar(
                                            content: Text(e.toString())));
                                  }
                                }
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
                                    Icon(Icons.chevron_left,
                                        color: cs.error, size: 20),
                                  ],
                                ),
                              ),
                              child: card,
                            );
                          }
                          return card;
                        }),
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

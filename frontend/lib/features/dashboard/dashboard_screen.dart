import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/constants.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/meal_skip_provider.dart';
import '../../core/utils/meal_cutoff.dart';

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
          if (sub == null) return _NoPlanView(cs: cs);

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
                color: cs.primary,
                onRefresh: () async {
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
                      // Greeting
                      Text(_greeting(),
                          style: TextStyle(
                              color: cs.onSurfaceVariant, fontSize: 13)),
                      const SizedBox(height: 2),
                      Text(
                        auth.user?.fullName ?? 'User',
                        style: GoogleFonts.inter(
                            fontSize: 24, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 20),

                      // Stats row
                      Row(
                        children: [
                          _StatChip(sub.planName ?? '-', 'Plan'),
                          const SizedBox(width: 8),
                          _StatChip(
                              '₹${sub.planMonthlyRate?.toStringAsFixed(0) ?? '-'}',
                              'Rate'),
                          const SizedBox(width: 8),
                          _StatChip('$totalSkips', 'Skipped'),
                          const SizedBox(width: 8),
                          _StatChip('$totalMessOff', 'Off'),
                        ],
                      ),
                      const SizedBox(height: 28),

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
                        // Section label
                        Row(
                          children: [
                            Text("Today's Meals",
                                style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600)),
                            const Spacer(),
                            Text(DateFormat('EEEE').format(now),
                                style: TextStyle(
                                    color: cs.onSurfaceVariant,
                                    fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Meal cards
                        ...todayMeals.map((meal) {
                          final isMessOff = todayMessOff.any((m) =>
                              m.mealType == meal || m.mealType == 'ALL');
                          final skip = todaySkips
                              .where((s) => s.mealType == meal)
                              .firstOrNull;
                          final isSkipped = skip != null;
                          final frozen = isMealCutoffPassed(meal, today);

                          return _MealCard(
                            mealType: meal,
                            isSkipped: isSkipped,
                            isMessOff: isMessOff,
                            isFrozen: frozen,
                            skipId: skip?.id,
                            date: today,
                            onChanged: () {
                              ref.invalidate(monthSkipsProvider(
                                  (month: now.month, year: now.year)));
                            },
                          );
                        }),
                      ],

                      if (isSunday)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text('Only lunch is served on Sundays',
                              style: TextStyle(
                                  color: cs.onSurfaceVariant, fontSize: 13)),
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

class _NoPlanView extends StatelessWidget {
  final ColorScheme cs;
  const _NoPlanView({required this.cs});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.no_meals_outlined,
                size: 48, color: cs.onSurfaceVariant.withOpacity(0.4)),
            const SizedBox(height: 16),
            Text('No Active Plan',
                style: GoogleFonts.inter(
                    fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(
              'Contact your admin to get a meal plan assigned.',
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 14),
            ),
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
                style: TextStyle(
                    fontSize: 10, color: cs.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

class _MealCard extends StatefulWidget {
  final String mealType;
  final bool isSkipped;
  final bool isMessOff;
  final bool isFrozen;
  final String? skipId;
  final DateTime date;
  final VoidCallback onChanged;

  const _MealCard({
    required this.mealType,
    required this.isSkipped,
    required this.isMessOff,
    required this.isFrozen,
    this.skipId,
    required this.date,
    required this.onChanged,
  });

  @override
  State<_MealCard> createState() => _MealCardState();
}

class _MealCardState extends State<_MealCard> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final label = mealLabel[widget.mealType] ?? widget.mealType;
    final canAct = !widget.isMessOff && !widget.isFrozen;
    final isLocked = widget.isFrozen && !widget.isMessOff;

    Color accentColor;
    String statusText;

    if (widget.isMessOff) {
      accentColor = cs.onSurfaceVariant;
      statusText = 'Mess Off';
    } else if (widget.isSkipped) {
      accentColor = cs.error;
      statusText = 'Skipped';
    } else if (widget.isFrozen) {
      accentColor = cs.onSurfaceVariant;
      statusText = 'Locked';
    } else {
      accentColor = cs.primary;
      statusText = 'Taking';
    }

    final mealIcons = {
      'BREAKFAST': Icons.wb_twilight_rounded,
      'LUNCH': Icons.wb_sunny_rounded,
      'DINNER': Icons.nightlight_round,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.outline),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(mealIcons[widget.mealType] ?? Icons.restaurant,
                  size: 20, color: accentColor),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 15)),
                    Text(statusText,
                        style: TextStyle(
                            color: accentColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              if (isLocked)
                Icon(Icons.lock_outline,
                    size: 16, color: cs.onSurfaceVariant),
              if (canAct)
                _loading
                    ? const SizedBox(
                        width: 32,
                        height: 32,
                        child: Padding(
                          padding: EdgeInsets.all(6),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ))
                    : TextButton(
                        onPressed: _handleAction,
                        style: TextButton.styleFrom(
                          foregroundColor:
                              widget.isSkipped ? cs.primary : cs.error,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          minimumSize: const Size(0, 36),
                        ),
                        child: Text(widget.isSkipped ? 'Undo' : 'Skip',
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                      ),
            ],
          ),
          // Countdown
          if (!widget.isMessOff && !widget.isSkipped && !widget.isFrozen)
            _CountdownBar(mealType: widget.mealType, date: widget.date),
        ],
      ),
    );
  }

  Future<void> _handleAction() async {
    setState(() => _loading = true);
    try {
      if (widget.isSkipped && widget.skipId != null) {
        await cancelSkip(widget.skipId!);
      } else {
        await createSkip(widget.date, widget.mealType);
      }
      widget.onChanged();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

class _CountdownBar extends StatelessWidget {
  final String mealType;
  final DateTime date;
  const _CountdownBar({required this.mealType, required this.date});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final now = DateTime.now();
    DateTime cutoff;
    if (mealType == 'BREAKFAST') {
      cutoff = DateTime(date.year, date.month, date.day - 1, 20, 0);
    } else if (mealType == 'LUNCH') {
      cutoff = DateTime(date.year, date.month, date.day, 8, 0);
    } else {
      cutoff = DateTime(date.year, date.month, date.day, 16, 0);
    }

    final diff = cutoff.difference(now);
    if (diff.isNegative) return const SizedBox.shrink();

    final totalMinutes = diff.inMinutes;
    final hours = diff.inHours;
    final minutes = totalMinutes % 60;
    final maxMinutes = 480.0;
    final progress = (totalMinutes / maxMinutes).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 3,
                backgroundColor: cs.outline,
                color: cs.primary.withOpacity(0.6),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text('${hours}h ${minutes}m left',
              style: TextStyle(
                  fontSize: 10,
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../core/constants.dart';
import '../../core/providers/meal_skip_provider.dart';
import '../../core/utils/meal_cutoff.dart';
import '../../shared/widgets/meal_status_card.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDay = DateTime(now.year, now.month, now.day);
  }

  @override
  Widget build(BuildContext context) {
    final month = _focusedDay.month;
    final year = _focusedDay.year;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final subAsync = ref.watch(subscriptionProvider);
    final skipsAsync =
        ref.watch(monthSkipsProvider((month: month, year: year)));
    final messOffAsync =
        ref.watch(messOffProvider((month: month, year: year)));

    return Scaffold(
      appBar: AppBar(title: const Text('Calendar')),
      body: Column(
        children: [
          skipsAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => const SizedBox.shrink(),
            data: (skips) {
              final messOffs = messOffAsync.valueOrNull ?? [];

              return TableCalendar(
                firstDay: DateTime(2024),
                lastDay: DateTime(2100),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selected, focused) {
                  setState(() {
                    _selectedDay = selected;
                    _focusedDay = focused;
                  });
                },
                onPageChanged: (focused) {
                  setState(() => _focusedDay = focused);
                },
                calendarBuilders: CalendarBuilders(
                  defaultBuilder: (ctx, day, focused) => _DayCell(
                    day: day,
                    skips: skips
                        .where((s) => isSameDay(s.date, day))
                        .map((s) => s.mealType)
                        .toList(),
                    messOffs: messOffs
                        .where((m) => isSameDay(m.date, day))
                        .map((m) => m.mealType)
                        .toList(),
                  ),
                  todayBuilder: (ctx, day, focused) => _DayCell(
                    day: day,
                    isToday: true,
                    skips: skips
                        .where((s) => isSameDay(s.date, day))
                        .map((s) => s.mealType)
                        .toList(),
                    messOffs: messOffs
                        .where((m) => isSameDay(m.date, day))
                        .map((m) => m.mealType)
                        .toList(),
                  ),
                  selectedBuilder: (ctx, day, focused) => _DayCell(
                    day: day,
                    isSelected: true,
                    skips: skips
                        .where((s) => isSameDay(s.date, day))
                        .map((s) => s.mealType)
                        .toList(),
                    messOffs: messOffs
                        .where((m) => isSameDay(m.date, day))
                        .map((m) => m.mealType)
                        .toList(),
                  ),
                ),
                headerStyle: HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: tt.titleMedium!,
                  leftChevronIcon:
                      Icon(Icons.chevron_left, color: cs.onSurfaceVariant),
                  rightChevronIcon:
                      Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
                  headerPadding: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    border: Border(
                        bottom: BorderSide(
                            color: cs.outline.withOpacity(0.5))),
                  ),
                ),
                daysOfWeekStyle: DaysOfWeekStyle(
                  weekdayStyle: TextStyle(
                      color: cs.onSurfaceVariant,
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                  weekendStyle: TextStyle(
                      color: cs.onSurfaceVariant.withOpacity(0.5),
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
                calendarFormat: CalendarFormat.month,
                rowHeight: 42,
              );
            },
          ),

          // Compact legend row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _LegendDot(color: cs.primary, label: 'Today'),
                const SizedBox(width: 16),
                _LegendDot(color: cs.error, label: 'Skipped'),
                const SizedBox(width: 16),
                _LegendDot(color: cs.onSurfaceVariant, label: 'Mess Off'),
              ],
            ),
          ),

          Divider(color: cs.outline, height: 1),

          Expanded(
            child: _DayDetail(
              day: _selectedDay,
              month: month,
              year: year,
              mealsPerDay: subAsync.valueOrNull?.planMealsPerDay ?? 0,
              hasSubscription: subAsync.valueOrNull != null,
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  final DateTime day;
  final bool isToday;
  final bool isSelected;
  final List<String> skips;
  final List<String> messOffs;

  const _DayCell({
    required this.day,
    this.isToday = false,
    this.isSelected = false,
    required this.skips,
    required this.messOffs,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasSkip = skips.isNotEmpty;
    final hasMessOff = messOffs.any((m) => m == 'ALL') || messOffs.length >= 3;

    return Container(
      margin: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: isSelected ? cs.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: isToday && !isSelected
            ? Border.all(color: cs.primary, width: 1.5)
            : null,
      ),
      alignment: Alignment.center,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            '${day.day}',
            style: TextStyle(
              fontWeight:
                  isToday || isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? cs.onPrimary
                  : isToday
                      ? cs.primary
                      : cs.onSurface,
              fontSize: 14,
            ),
          ),
          if (!isSelected && (hasSkip || hasMessOff))
            Positioned(
              bottom: 4,
              child: Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: hasMessOff ? cs.onSurfaceVariant : cs.error,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DayDetail extends ConsumerWidget {
  final DateTime day;
  final int month;
  final int year;
  final int mealsPerDay;
  final bool hasSubscription;

  const _DayDetail({
    required this.day,
    required this.month,
    required this.year,
    required this.mealsPerDay,
    required this.hasSubscription,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final skipsAsync =
        ref.watch(monthSkipsProvider((month: month, year: year)));
    final messOffAsync =
        ref.watch(messOffProvider((month: month, year: year)));
    final extrasAsync =
        ref.watch(extraMealsProvider((month: month, year: year)));

    final skips = skipsAsync.valueOrNull ?? [];
    final messOffs = messOffAsync.valueOrNull ?? [];
    final extras = extrasAsync.valueOrNull ?? [];

    final daySkips = skips.where((s) => isSameDay(s.date, day)).toList();
    final dayMessOffs = messOffs.where((m) => isSameDay(m.date, day)).toList();
    final dayExtras = extras.where((e) => isSameDay(e.date, day)).toList();
    final isFullDayOff = dayMessOffs.any((m) => m.mealType == 'ALL');

    final isSunday = day.weekday == DateTime.sunday;
    List<String> mealsForDay;
    if (!hasSubscription) {
      mealsForDay = [];
    } else if (isSunday) {
      mealsForDay = ['LUNCH'];
    } else if (mealsPerDay == 2) {
      mealsForDay = ['LUNCH', 'DINNER'];
    } else {
      mealsForDay = ['BREAKFAST', 'LUNCH', 'DINNER'];
    }

    final isToday = isSameDay(day, DateTime.now());

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                DateFormat('EEEE, d MMMM').format(day),
                style: tt.titleMedium,
              ),
            ),
            if (isToday)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: cs.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('TODAY',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: cs.primary,
                    )),
              )
            else if (day
                .isBefore(DateTime.now().subtract(const Duration(days: 1))))
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: cs.onSurfaceVariant.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('Past',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurfaceVariant)),
              ),
          ],
        ),
        const SizedBox(height: 12),

        if (!hasSubscription) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cs.tertiary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: cs.tertiary.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: cs.tertiary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('No active plan',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: cs.tertiary,
                          )),
                      Text(
                        'Contact your mess admin to get a meal plan.',
                        style: TextStyle(
                            fontSize: 13,
                            color: cs.tertiary.withOpacity(0.8)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],

        if (isFullDayOff) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cs.errorContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.event_busy, color: cs.onErrorContainer, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Mess is off this day',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: cs.onErrorContainer,
                          )),
                      if (dayMessOffs.first.reason != null)
                        Text(dayMessOffs.first.reason!,
                            style: TextStyle(
                                fontSize: 13,
                                color:
                                    cs.onErrorContainer.withOpacity(0.8))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          // Shared MealStatusCard for each meal
          ...mealsForDay.map((meal) {
            final isMealMessOff = dayMessOffs
                .any((m) => m.mealType == meal || m.mealType == 'ALL');
            final skip =
                daySkips.where((s) => s.mealType == meal).firstOrNull;
            final isSkipped = skip != null;
            final frozen = isMealCutoffPassed(meal, day);

            return MealStatusCard(
              mealType: meal,
              isSkipped: isSkipped,
              isMessOff: isMealMessOff,
              isFrozen: frozen,
              skipId: skip?.id,
              date: day,
              onSkip: (date, mealType) => createSkip(date, mealType),
              onUndo: (skipId) => cancelSkip(skipId),
              onChanged: () {
                ref.invalidate(
                    monthSkipsProvider((month: month, year: year)));
              },
            );
          }),

          if (dayMessOffs.isNotEmpty && !isFullDayOff)
            ...dayMessOffs.map((m) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainer,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: cs.outline),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.event_busy,
                          size: 16, color: cs.onSurfaceVariant),
                      const SizedBox(width: 10),
                      Text(
                        '${mealLabel[m.mealType] ?? m.mealType} — Mess Off',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      if (m.reason != null) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(m.reason!,
                              style: tt.bodySmall,
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ],
                  ),
                )),
        ],

        // Skip all — only show when actionable
        if (!isFullDayOff && mealsForDay.length > 1) ...[
          Builder(builder: (ctx) {
            final allSkipped = mealsForDay.every(
                (m) => daySkips.any((s) => s.mealType == m));
            final allFrozenOrSkipped = mealsForDay.every((m) =>
                isMealCutoffPassed(m, day) ||
                daySkips.any((s) => s.mealType == m));
            if (allSkipped || allFrozenOrSkipped) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: OutlinedButton.icon(
                onPressed: () async {
                  HapticFeedback.mediumImpact();
                  try {
                    await bulkSkipDay(day);
                    ref.invalidate(
                        monthSkipsProvider((month: month, year: year)));
                  } catch (e) {
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(content: Text(e.toString())),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.block, size: 16),
                label: const Text('Skip All Meals'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: cs.error,
                  side: BorderSide(color: cs.error.withOpacity(0.3)),
                  minimumSize: const Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            );
          }),
        ],

        // Extra meals
        if (dayExtras.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text('Extra Meals',
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: cs.secondary)),
          const SizedBox(height: 8),
          ...dayExtras.map((e) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cs.secondary.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                  border:
                      Border.all(color: cs.secondary.withOpacity(0.15)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.add_circle_outline,
                        size: 16, color: cs.secondary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${mealLabel[e.mealType] ?? e.mealType} (Extra)',
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: cs.secondary),
                          ),
                          if (e.note != null)
                            Text(e.note!,
                                style: tt.labelSmall),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
        ],

        if (isSunday)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.secondary.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
                border:
                    Border.all(color: cs.secondary.withOpacity(0.15)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: cs.secondary),
                  const SizedBox(width: 8),
                  Text('Only lunch on Sundays', style: tt.bodySmall),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

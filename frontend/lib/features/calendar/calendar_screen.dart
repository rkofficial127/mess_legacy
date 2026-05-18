import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../core/constants.dart';
import '../../core/providers/meal_skip_provider.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    final month = _focusedDay.month;
    final year = _focusedDay.year;
    final cs = Theme.of(context).colorScheme;

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
                  titleTextStyle: Theme.of(context)
                      .textTheme
                      .titleMedium!
                      .copyWith(fontWeight: FontWeight.w600),
                  leftChevronIcon:
                      Icon(Icons.chevron_left, color: cs.onSurface),
                  rightChevronIcon:
                      Icon(Icons.chevron_right, color: cs.onSurface),
                ),
                daysOfWeekStyle: DaysOfWeekStyle(
                  weekdayStyle: TextStyle(
                      color: cs.onSurfaceVariant,
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                  weekendStyle: TextStyle(
                      color: cs.onSurfaceVariant.withOpacity(0.6),
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
                calendarFormat: CalendarFormat.month,
                rowHeight: 48,
              );
            },
          ),

          // Legend
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _LegendDot(color: cs.primaryContainer, label: 'Normal'),
                const SizedBox(width: 16),
                _LegendDot(color: Colors.amber.shade200, label: 'Skipped'),
                const SizedBox(width: 16),
                _LegendDot(color: cs.errorContainer, label: 'All Skipped'),
                const SizedBox(width: 16),
                _LegendDot(color: Colors.grey.shade300, label: 'Mess Off'),
              ],
            ),
          ),

          const Divider(),

          if (_selectedDay != null)
            Expanded(
              child: _DayDetail(
                day: _selectedDay!,
                month: month,
                year: year,
                mealsPerDay: subAsync.valueOrNull?.planMealsPerDay ?? 2,
              ),
            )
          else
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.touch_app_outlined,
                        size: 48, color: cs.onSurfaceVariant.withOpacity(0.3)),
                    const SizedBox(height: 12),
                    Text('Tap a day to see details or skip meals',
                        style: TextStyle(color: cs.onSurfaceVariant)),
                  ],
                ),
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
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
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

    Color bg;
    if (messOffs.any((m) => m == 'ALL') || messOffs.length >= 3) {
      bg = Colors.grey.shade300;
    } else if (skips.length >= 3 ||
        (day.weekday == DateTime.sunday && skips.isNotEmpty)) {
      bg = cs.errorContainer;
    } else if (skips.isNotEmpty) {
      bg = Colors.amber.shade200;
    } else if (day.isBefore(DateTime.now()) &&
        day.month == DateTime.now().month) {
      bg = cs.primaryContainer.withOpacity(0.4);
    } else {
      bg = Colors.transparent;
    }

    return Container(
      margin: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: isSelected ? cs.primary : bg,
        shape: BoxShape.circle,
        border: isToday && !isSelected
            ? Border.all(color: cs.primary, width: 2)
            : null,
      ),
      alignment: Alignment.center,
      child: Text(
        '${day.day}',
        style: TextStyle(
          fontWeight:
              isToday || isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? cs.onPrimary : cs.onSurface,
          fontSize: 14,
        ),
      ),
    );
  }
}

class _DayDetail extends ConsumerWidget {
  final DateTime day;
  final int month;
  final int year;
  final int mealsPerDay;

  const _DayDetail({
    required this.day,
    required this.month,
    required this.year,
    required this.mealsPerDay,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final skipsAsync =
        ref.watch(monthSkipsProvider((month: month, year: year)));
    final messOffAsync =
        ref.watch(messOffProvider((month: month, year: year)));

    final skips = skipsAsync.valueOrNull ?? [];
    final messOffs = messOffAsync.valueOrNull ?? [];

    final daySkips = skips.where((s) => isSameDay(s.date, day)).toList();
    final dayMessOffs = messOffs.where((m) => isSameDay(m.date, day)).toList();
    final isFullDayOff = dayMessOffs.any((m) => m.mealType == 'ALL');

    final isSunday = day.weekday == DateTime.sunday;
    List<String> mealsForDay;
    if (isSunday) {
      mealsForDay = ['LUNCH'];
    } else if (mealsPerDay == 2) {
      mealsForDay = ['LUNCH', 'DINNER'];
    } else {
      mealsForDay = ['BREAKFAST', 'LUNCH', 'DINNER'];
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                DateFormat('EEEE, d MMMM').format(day),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            if (day.isBefore(DateTime.now().subtract(const Duration(days: 1))))
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('Past',
                    style: TextStyle(
                        fontSize: 12, color: cs.onSurfaceVariant)),
              ),
          ],
        ),
        const SizedBox(height: 16),

        // Full day mess-off banner
        if (isFullDayOff) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cs.errorContainer,
              borderRadius: BorderRadius.circular(14),
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
                                color: cs.onErrorContainer.withOpacity(0.8))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          // Per-meal cards with skip toggle
          ...mealsForDay.map((meal) {
            final isMealMessOff = dayMessOffs
                .any((m) => m.mealType == meal || m.mealType == 'ALL');
            final skip =
                daySkips.where((s) => s.mealType == meal).firstOrNull;
            final isSkipped = skip != null;

            final emoji = mealEmoji[meal] ?? '';
            final label = mealLabel[meal] ?? meal;

            Color cardColor;
            Color accentColor;
            String statusText;
            IconData statusIcon;

            if (isMealMessOff) {
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
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: accentColor.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 15)),
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
                  if (!isMealMessOff)
                    FilledButton.tonal(
                      onPressed: () async {
                        try {
                          if (isSkipped) {
                            await cancelSkip(skip.id);
                          } else {
                            await createSkip(day, meal);
                          }
                          ref.invalidate(monthSkipsProvider(
                              (month: month, year: year)));
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(e.toString())),
                            );
                          }
                        }
                      },
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 36),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(isSkipped ? 'Undo' : 'Skip',
                          style:
                              const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                ],
              ),
            );
          }),

          // Partial mess-off entries
          if (dayMessOffs.isNotEmpty)
            ...dayMessOffs.map((m) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.event_busy,
                          size: 18, color: cs.onSurfaceVariant),
                      const SizedBox(width: 10),
                      Text(
                        '${mealLabel[m.mealType] ?? m.mealType} — Mess Off',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      if (m.reason != null) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(m.reason!,
                              style: TextStyle(
                                  fontSize: 13,
                                  color: cs.onSurfaceVariant),
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
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
                color: cs.tertiaryContainer.withOpacity(0.4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 18, color: cs.onTertiaryContainer),
                  const SizedBox(width: 8),
                  Text('Only lunch on Sundays',
                      style: TextStyle(
                          fontSize: 13, color: cs.onTertiaryContainer)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

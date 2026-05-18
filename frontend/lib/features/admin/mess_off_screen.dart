import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../core/providers/admin_providers.dart';
import '../../core/providers/meal_skip_provider.dart';

class MessOffScreen extends ConsumerStatefulWidget {
  const MessOffScreen({super.key});

  @override
  ConsumerState<MessOffScreen> createState() => _MessOffScreenState();
}

class _MessOffScreenState extends ConsumerState<MessOffScreen> {
  DateTime _focusedDay = DateTime.now();
  final Set<DateTime> _selectedDates = {};
  String _mealType = 'ALL';
  final _reasonCtrl = TextEditingController();

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final month = _focusedDay.month;
    final year = _focusedDay.year;
    final messOffAsync =
        ref.watch(messOffProvider((month: month, year: year)));

    return Scaffold(
      appBar: AppBar(title: const Text('Mess Off Days')),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime(2024),
            lastDay: DateTime(2100),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) =>
                _selectedDates.any((d) => isSameDay(d, day)),
            onDaySelected: (selected, focused) {
              setState(() {
                _focusedDay = focused;
                final normalized =
                    DateTime(selected.year, selected.month, selected.day);
                if (_selectedDates.any((d) => isSameDay(d, normalized))) {
                  _selectedDates
                      .removeWhere((d) => isSameDay(d, normalized));
                } else {
                  _selectedDates.add(normalized);
                }
              });
            },
            onPageChanged: (focused) =>
                setState(() => _focusedDay = focused),
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: Theme.of(context)
                  .textTheme
                  .titleMedium!
                  .copyWith(fontWeight: FontWeight.w600),
            ),
            calendarFormat: CalendarFormat.month,
            rowHeight: 44,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _mealType,
                    decoration: const InputDecoration(
                      labelText: 'Meal',
                      isDense: true,
                      prefixIcon: Icon(Icons.restaurant_outlined),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'ALL', child: Text('Full Day')),
                      DropdownMenuItem(
                          value: 'BREAKFAST', child: Text('Breakfast')),
                      DropdownMenuItem(value: 'LUNCH', child: Text('Lunch')),
                      DropdownMenuItem(
                          value: 'DINNER', child: Text('Dinner')),
                    ],
                    onChanged: (v) => setState(() => _mealType = v!),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _reasonCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Reason (optional)',
                      isDense: true,
                      prefixIcon: Icon(Icons.notes_outlined),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _selectedDates.isEmpty
                    ? null
                    : () async {
                        try {
                          await createMessOff(
                            dates: _selectedDates.toList(),
                            mealType: _mealType,
                            reason: _reasonCtrl.text.isNotEmpty
                                ? _reasonCtrl.text
                                : null,
                          );
                          setState(() => _selectedDates.clear());
                          _reasonCtrl.clear();
                          ref.invalidate(
                              messOffProvider((month: month, year: year)));
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Mess off created')),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        }
                      },
                icon: const Icon(Icons.event_busy),
                label: Text(
                  _selectedDates.isEmpty
                      ? 'Select dates to mark off'
                      : 'Mark ${_selectedDates.length} day(s) off',
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Divider(),
          Expanded(
            child: messOffAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (entries) {
                if (entries.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.event_available_outlined,
                            size: 48,
                            color: cs.onSurfaceVariant.withOpacity(0.3)),
                        const SizedBox(height: 12),
                        Text('No mess-off days this month',
                            style: TextStyle(color: cs.onSurfaceVariant)),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemCount: entries.length,
                  itemBuilder: (ctx, i) {
                    final e = entries[i];
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.event_busy,
                              size: 20, color: cs.onSurfaceVariant),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${DateFormat('d MMM, EEE').format(e.date)} — ${e.mealType}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w500),
                                ),
                                if (e.reason != null)
                                  Text(e.reason!,
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: cs.onSurfaceVariant)),
                              ],
                            ),
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
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/constants.dart';
import '../../core/models/meal_delivery.dart';
import '../../core/providers/admin_providers.dart';
import '../../shared/widgets/meal_status_card.dart' show savingsGreen;
import '../../shared/widgets/shimmer_loading.dart';

class AttendanceReportScreen extends ConsumerStatefulWidget {
  const AttendanceReportScreen({super.key});

  @override
  ConsumerState<AttendanceReportScreen> createState() =>
      _AttendanceReportScreenState();
}

class _AttendanceReportScreenState
    extends ConsumerState<AttendanceReportScreen> {
  DateTime _selectedDate = DateTime.now();
  String? _selectedMeal;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final attendanceAsync = ref.watch(
        attendanceProvider((date: dateStr, mealType: _selectedMeal)));
    final today = DateTime.now();
    final selectedDateOnly =
        DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    final todayOnly = DateTime(today.year, today.month, today.day);
    final isTodayOrPast = !selectedDateOnly.isAfter(todayOnly);

    return Scaffold(
      appBar: AppBar(title: const Text('Meal Attendance')),
      body: Column(
        children: [
          // Filters
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: cs.outline)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: ActionChip(
                    avatar: Icon(Icons.calendar_today,
                        size: 14, color: cs.primary),
                    label: Text(
                      DateFormat('EEE, d MMM').format(_selectedDate),
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: cs.primary),
                    ),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2024),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() => _selectedDate = picked);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                SegmentedButton<String?>(
                  segments: const [
                    ButtonSegment(
                        value: null,
                        label: Icon(Icons.auto_awesome, size: 18)),
                    ButtonSegment(
                        value: 'BREAKFAST',
                        label: Icon(Icons.wb_twilight_rounded, size: 18)),
                    ButtonSegment(
                        value: 'LUNCH',
                        label: Icon(Icons.wb_sunny_rounded, size: 18)),
                    ButtonSegment(
                        value: 'DINNER',
                        label: Icon(Icons.nightlight_round, size: 18)),
                  ],
                  selected: {_selectedMeal},
                  onSelectionChanged: (s) =>
                      setState(() => _selectedMeal = s.first),
                  style: const ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: attendanceAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.only(top: 16),
                child: ShimmerCardList(count: 5),
              ),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Error: $e', textAlign: TextAlign.center),
                ),
              ),
              data: (report) {
                if (report.messOff) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.event_busy,
                            size: 48,
                            color: cs.onSurfaceVariant.withOpacity(0.3)),
                        const SizedBox(height: 12),
                        Text(
                            'Mess is off for ${mealLabel[report.mealType] ?? report.mealType}',
                            style: Theme.of(context).textTheme.titleMedium),
                        Text(
                            DateFormat('EEEE, d MMMM yyyy')
                                .format(report.date),
                            style:
                                TextStyle(color: cs.onSurfaceVariant)),
                      ],
                    ),
                  );
                }

                final deliveriesAsync = isTodayOrPast
                    ? ref.watch(deliveriesProvider(
                        (date: dateStr, mealType: report.mealType)))
                    : const AsyncValue<List<MealDelivery>>.data([]);
                final deliveredByUserId = {
                  for (final d in deliveriesAsync.valueOrNull ?? <MealDelivery>[])
                    d.userId: d.id,
                };

                return RefreshIndicator(
                  color: cs.primary,
                  onRefresh: () async {
                    ref.invalidate(attendanceProvider(
                        (date: dateStr, mealType: _selectedMeal)));
                    if (isTodayOrPast) {
                      ref.invalidate(deliveriesProvider(
                          (date: dateStr, mealType: report.mealType)));
                    }
                  },
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Meal label + date
                      Center(
                        child: Column(
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(_mealIcon(report.mealType),
                                    size: 18, color: cs.onSurfaceVariant),
                                const SizedBox(width: 8),
                                Text(
                                  mealLabel[report.mealType] ??
                                      report.mealType,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              DateFormat('EEEE, d MMMM')
                                  .format(report.date),
                              style: TextStyle(
                                  color: cs.onSurfaceVariant, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Count cards
                      Row(
                        children: [
                          _CountCard(
                            count: report.totalTaking,
                            label: 'Taking',
                            color: cs.primary,
                          ),
                          const SizedBox(width: 8),
                          _CountCard(
                            count: report.totalSkipped,
                            label: 'Skipped',
                            color: cs.error,
                          ),
                          const SizedBox(width: 8),
                          _CountCard(
                            count: report.totalSubscribed,
                            label: 'Total',
                            color: cs.onSurfaceVariant,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Taking list
                      if (report.taking.isNotEmpty) ...[
                        _SectionHeader(
                          label: 'Taking Meal (${report.totalTaking})',
                          color: cs.primary,
                        ),
                        const SizedBox(height: 8),
                        ...report.taking.map((u) => _UserTile(
                              user: u,
                              color: cs.primary,
                              deliveryId: deliveredByUserId[u.userId],
                              showDeliveryAction: isTodayOrPast,
                              onMarkDelivered: () async {
                                HapticFeedback.mediumImpact();
                                await markDelivered(
                                  userId: u.userId,
                                  date: _selectedDate,
                                  mealType: report.mealType,
                                );
                                ref.invalidate(deliveriesProvider((
                                  date: dateStr,
                                  mealType: report.mealType,
                                )));
                              },
                              onUnmark: (deliveryId) async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (d) => AlertDialog(
                                    title: const Text('Unmark Delivered?'),
                                    content: Text(
                                        '${u.fullName} will show as not yet delivered.'),
                                    actions: [
                                      TextButton(
                                          onPressed: () =>
                                              Navigator.pop(d, false),
                                          child: const Text('Cancel')),
                                      FilledButton(
                                          onPressed: () =>
                                              Navigator.pop(d, true),
                                          child: const Text('Unmark')),
                                    ],
                                  ),
                                );
                                if (confirm != true) return;
                                await unmarkDelivered(deliveryId);
                                ref.invalidate(deliveriesProvider((
                                  date: dateStr,
                                  mealType: report.mealType,
                                )));
                              },
                            )),
                        const SizedBox(height: 16),
                      ],

                      // Skipped list
                      if (report.skipped.isNotEmpty) ...[
                        _SectionHeader(
                          label: 'Skipped (${report.totalSkipped})',
                          color: cs.error,
                        ),
                        const SizedBox(height: 8),
                        ...report.skipped.map((u) => _UserTile(
                              user: u,
                              color: cs.error,
                            )),
                      ],

                      if (report.totalSubscribed == 0)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              children: [
                                Icon(Icons.no_meals_outlined,
                                    size: 48,
                                    color: cs.onSurfaceVariant
                                        .withOpacity(0.3)),
                                const SizedBox(height: 12),
                                Text('No subscribers for this meal',
                                    style: TextStyle(
                                        color: cs.onSurfaceVariant)),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  IconData _mealIcon(String mealType) {
    switch (mealType) {
      case 'BREAKFAST':
        return Icons.wb_twilight_rounded;
      case 'LUNCH':
        return Icons.wb_sunny_rounded;
      case 'DINNER':
        return Icons.nightlight_round;
      default:
        return Icons.restaurant;
    }
  }
}

class _CountCard extends StatelessWidget {
  final int count;
  final String label;
  final Color color;
  const _CountCard({
    required this.count,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: cs.outline),
        ),
        child: Column(
          children: [
            Text('$count',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: color,
                )),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final Color color;
  const _SectionHeader({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Text(label,
        style: TextStyle(
            fontWeight: FontWeight.w600, fontSize: 14, color: color));
  }
}

class _UserTile extends StatefulWidget {
  final AttendanceUser user;
  final Color color;
  final bool showDeliveryAction;
  final String? deliveryId;
  final Future<void> Function()? onMarkDelivered;
  final Future<void> Function(String deliveryId)? onUnmark;

  const _UserTile({
    required this.user,
    required this.color,
    this.showDeliveryAction = false,
    this.deliveryId,
    this.onMarkDelivered,
    this.onUnmark,
  });

  @override
  State<_UserTile> createState() => _UserTileState();
}

class _UserTileState extends State<_UserTile> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final delivered = widget.deliveryId != null;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.outline),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: widget.color.withOpacity(0.1),
            child: Text(
              widget.user.fullName.isNotEmpty
                  ? widget.user.fullName[0].toUpperCase()
                  : '?',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: widget.color,
                  fontSize: 13),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.user.fullName,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                Text(widget.user.planName,
                    style: TextStyle(
                        fontSize: 12, color: cs.onSurfaceVariant)),
              ],
            ),
          ),
          if (widget.showDeliveryAction)
            _loading
                ? const SizedBox(
                    width: 28,
                    height: 28,
                    child: Padding(
                      padding: EdgeInsets.all(6),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    icon: Icon(
                      delivered
                          ? Icons.check_circle
                          : Icons.check_circle_outline,
                      color: delivered ? savingsGreen : cs.onSurfaceVariant,
                    ),
                    tooltip: delivered ? 'Delivered' : 'Mark delivered',
                    onPressed: _handleTap,
                  ),
        ],
      ),
    );
  }

  Future<void> _handleTap() async {
    setState(() => _loading = true);
    try {
      if (widget.deliveryId != null) {
        await widget.onUnmark?.call(widget.deliveryId!);
      } else {
        await widget.onMarkDelivered?.call();
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

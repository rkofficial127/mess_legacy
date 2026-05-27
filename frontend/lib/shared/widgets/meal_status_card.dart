import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/decorations.dart';
import '../../core/constants.dart';

class MealStatusCard extends StatefulWidget {
  final String mealType;
  final bool isSkipped;
  final bool isMessOff;
  final bool isFrozen;
  final String? skipId;
  final DateTime date;
  final VoidCallback? onChanged;
  final bool showCountdown;
  final Future<void> Function(DateTime date, String mealType)? onSkip;
  final Future<void> Function(String skipId)? onUndo;

  const MealStatusCard({
    super.key,
    required this.mealType,
    required this.isSkipped,
    required this.isMessOff,
    required this.isFrozen,
    this.skipId,
    required this.date,
    this.onChanged,
    this.showCountdown = false,
    this.onSkip,
    this.onUndo,
  });

  @override
  State<MealStatusCard> createState() => _MealStatusCardState();
}

class _MealStatusCardState extends State<MealStatusCard> {
  bool _loading = false;

  static const _mealIcons = {
    'BREAKFAST': Icons.wb_twilight_rounded,
    'LUNCH': Icons.wb_sunny_rounded,
    'DINNER': Icons.nightlight_round,
  };

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
      statusText = isLocked ? 'Skipped (Locked)' : 'Skipped';
    } else if (widget.isFrozen) {
      accentColor = cs.onSurfaceVariant;
      statusText = 'Taking (Locked)';
    } else {
      accentColor = cs.primary;
      statusText = 'Taking';
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: AppDecorations.card(cs),
      child: Column(
        children: [
          Row(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Icon(
                  _mealIcons[widget.mealType] ?? Icons.restaurant,
                  key: ValueKey('${widget.mealType}_$accentColor'),
                  size: 20,
                  color: accentColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 15)),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: Text(
                        statusText,
                        key: ValueKey(statusText),
                        style: TextStyle(
                            color: accentColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
              if (isLocked)
                Icon(Icons.lock_outline, size: 16, color: cs.onSurfaceVariant),
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
          if (widget.showCountdown &&
              !widget.isMessOff &&
              !widget.isSkipped &&
              !widget.isFrozen)
            _CountdownBar(mealType: widget.mealType, date: widget.date),
        ],
      ),
    );
  }

  Future<void> _handleAction() async {
    HapticFeedback.mediumImpact();
    setState(() => _loading = true);
    try {
      if (widget.isSkipped && widget.skipId != null && widget.onUndo != null) {
        await widget.onUndo!(widget.skipId!);
      } else if (widget.onSkip != null) {
        await widget.onSkip!(widget.date, widget.mealType);
      }
      widget.onChanged?.call();
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
    const maxMinutes = 480.0;
    final progress = (totalMinutes / maxMinutes).clamp(0.0, 1.0);
    final isUrgent = totalMinutes < 60;

    final barColor = isUrgent ? cs.tertiary : cs.primary;

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 4,
                backgroundColor: cs.outline,
                color: barColor.withOpacity(0.7),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text('${hours}h ${minutes}m left',
              style: TextStyle(
                  fontSize: 11,
                  color: isUrgent ? cs.tertiary : cs.onSurfaceVariant,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

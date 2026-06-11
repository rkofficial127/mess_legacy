import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/decorations.dart';
import '../../core/constants.dart';
import '../../core/utils/meal_cutoff.dart';

const Color savingsGreen = Color(0xFF22C55E);

class MealStatusCard extends StatefulWidget {
  final String mealType;
  final bool isSkipped;
  final bool isMessOff;
  final bool isFrozen;
  final String? skipId;
  final DateTime date;
  final VoidCallback? onChanged;
  final double? perMealValue;
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
    this.perMealValue,
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
    final isDone = widget.isSkipped || widget.isFrozen || widget.isMessOff;

    Color accentColor;
    if (widget.isMessOff || (widget.isFrozen && !widget.isSkipped)) {
      accentColor = cs.onSurfaceVariant;
    } else if (widget.isSkipped) {
      accentColor = cs.error;
    } else {
      accentColor = cs.primary;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: AppDecorations.card(cs),
      child: Opacity(
        opacity: isDone && !widget.isSkipped ? 0.7 : 1,
        child: Row(
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
                  const SizedBox(height: 2),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: KeyedSubtree(
                      key: ValueKey(
                          '${widget.isSkipped}_${widget.isFrozen}_${widget.isMessOff}'),
                      child: _buildSubtitle(cs),
                    ),
                  ),
                ],
              ),
            ),
            if (isLocked && !widget.isSkipped)
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
      ),
    );
  }

  Widget _buildSubtitle(ColorScheme cs) {
    final muted = TextStyle(fontSize: 12, color: cs.onSurfaceVariant);

    if (widget.isMessOff) {
      return Text('Mess off', style: muted);
    }
    if (widget.isSkipped) {
      return Text.rich(TextSpan(
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        children: [
          TextSpan(text: 'Skipped', style: TextStyle(color: cs.error)),
          if (widget.perMealValue != null)
            TextSpan(
              text: ' · ₹${widget.perMealValue!.round()} off your bill',
              style: const TextStyle(color: savingsGreen),
            ),
        ],
      ));
    }
    if (widget.isFrozen) {
      return Text('Closed for changes', style: muted);
    }

    final serving = mealServingTime[widget.mealType];
    final deadline = skipDeadlineLabel(widget.mealType, widget.date);
    final urgent = mealCutoff(widget.mealType, widget.date)
            .difference(DateTime.now())
            .inMinutes <
        60;
    return Text.rich(TextSpan(
      style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
      children: [
        if (serving != null) TextSpan(text: 'Served $serving · '),
        TextSpan(
          text: 'skip by $deadline',
          style: urgent
              ? TextStyle(color: cs.tertiary, fontWeight: FontWeight.w600)
              : null,
        ),
      ],
    ));
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

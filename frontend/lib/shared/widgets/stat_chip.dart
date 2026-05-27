import 'package:flutter/material.dart';
import '../../app/decorations.dart';

class StatChip extends StatelessWidget {
  final String value;
  final String label;
  final Color? accentColor;

  const StatChip(this.value, this.label, {super.key, this.accentColor});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: AppDecorations.card(cs),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: accentColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center),
            const SizedBox(height: 2),
            Text(label, style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      ),
    );
  }
}

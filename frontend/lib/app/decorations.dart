import 'package:flutter/material.dart';
import 'tokens.dart';

abstract final class AppDecorations {
  static BoxDecoration card(ColorScheme cs) => BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: AppRadius.medium,
        border: Border.all(color: cs.outline),
      );

  static BoxDecoration cardElevated(ColorScheme cs) => BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: AppRadius.medium,
        border: Border.all(color: cs.outline),
      );

  static BoxDecoration cardAccent(ColorScheme cs) => BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: AppRadius.medium,
        border: Border.all(color: cs.primary, width: 1.5),
      );
}

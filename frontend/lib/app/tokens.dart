import 'package:flutter/material.dart';

// --- Spacing scale ---
abstract final class Spacing {
  static const double s4 = 4;
  static const double s8 = 8;
  static const double s12 = 12;
  static const double s16 = 16;
  static const double s20 = 20;
  static const double s24 = 24;
  static const double s32 = 32;
  static const double s48 = 48;
}

// --- Border radius ---
abstract final class AppRadius {
  static final small = BorderRadius.circular(8);
  static final medium = BorderRadius.circular(10);
  static final large = BorderRadius.circular(12);
  static final xl = BorderRadius.circular(16);
}

// --- Color usage ---
// primary (#6C9CFC)   → active states, CTAs, selected nav, "Taking" status, primary amounts
// secondary (#A78BFA)  → admin-specific accents, role badges, extra meals, regen actions
// tertiary (#FBBF24)   → warnings, "No Plan" states, countdown < 1hr
// error (#EF4444)      → skipped meals, deactivated users, destructive actions
// onSurfaceVariant     → all secondary text, locked/frozen states, timestamps

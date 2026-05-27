import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const _accent = Color(0xFF6C9CFC);
  static const _bg = Color(0xFF111111);
  static const _surface = Color(0xFF1A1A1A);
  static const _surface2 = Color(0xFF222222);
  static const _border = Color(0xFF2A2A2A);
  static const _textPrimary = Color(0xFFF5F5F5);
  static const _textSecondary = Color(0xFF888888);

  static ThemeData get dark {
    final colorScheme = ColorScheme.dark(
      brightness: Brightness.dark,
      primary: _accent,
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFF1E2A3A),
      onPrimaryContainer: _accent,
      secondary: const Color(0xFFA78BFA),
      onSecondary: Colors.white,
      secondaryContainer: const Color(0xFF2A2040),
      onSecondaryContainer: const Color(0xFFA78BFA),
      tertiary: const Color(0xFFFBBF24),
      error: const Color(0xFFEF4444),
      onError: Colors.white,
      errorContainer: const Color(0xFF2D1B1B),
      onErrorContainer: const Color(0xFFEF4444),
      surface: _bg,
      onSurface: _textPrimary,
      onSurfaceVariant: _textSecondary,
      outline: _border,
      outlineVariant: _border,
      surfaceContainerLowest: const Color(0xFF0D0D0D),
      surfaceContainerLow: _surface,
      surfaceContainer: _surface2,
      surfaceContainerHigh: const Color(0xFF282828),
      surfaceContainerHighest: const Color(0xFF303030),
    );

    final textTheme = GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
      displayLarge: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 57, color: _textPrimary),
      displayMedium: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 45, color: _textPrimary),
      displaySmall: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 36, color: _textPrimary),
      headlineLarge: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 32, color: _textPrimary),
      headlineMedium: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 28, color: _textPrimary),
      headlineSmall: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 24, color: _textPrimary),
      titleLarge: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 22, color: _textPrimary),
      titleMedium: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16, color: _textPrimary),
      titleSmall: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 14, color: _textPrimary),
      bodyLarge: GoogleFonts.inter(fontWeight: FontWeight.w400, fontSize: 16, color: _textPrimary),
      bodyMedium: GoogleFonts.inter(fontWeight: FontWeight.w400, fontSize: 14, color: _textPrimary),
      bodySmall: GoogleFonts.inter(fontWeight: FontWeight.w400, fontSize: 12, color: _textSecondary),
      labelLarge: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: _textPrimary),
      labelMedium: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 12, color: _textSecondary),
      labelSmall: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 10, color: _textSecondary),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: Brightness.dark,
      textTheme: textTheme,
      scaffoldBackgroundColor: _bg,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: _bg,
        foregroundColor: _textPrimary,
        titleTextStyle: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          fontSize: 18,
          color: _textPrimary,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        height: 64,
        backgroundColor: _surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: _accent.withOpacity(0.12),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: _accent, size: 22);
          }
          return const IconThemeData(color: _textSecondary, size: 22);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: _accent);
          }
          return GoogleFonts.inter(fontSize: 11, color: _textSecondary);
        }),
      ),
      cardTheme: CardTheme(
        elevation: 0,
        color: _surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: _border),
        ),
        margin: const EdgeInsets.only(bottom: 8),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colorScheme.error, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        prefixIconColor: _textSecondary,
        hintStyle: const TextStyle(color: _textSecondary),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          backgroundColor: _accent,
          foregroundColor: Colors.white,
          textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          side: const BorderSide(color: _border),
          foregroundColor: _textPrimary,
          textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _accent,
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: const BorderSide(color: _border),
        backgroundColor: _surface,
      ),
      dividerTheme: const DividerThemeData(
        color: _border,
        space: 1,
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: _surface2,
        contentTextStyle: const TextStyle(color: _textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      dialogTheme: DialogTheme(
        backgroundColor: _surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: _surface,
        showDragHandle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: _accent,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return _accent.withOpacity(0.12);
            return Colors.transparent;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return _accent;
            return _textSecondary;
          }),
          side: WidgetStateProperty.all(const BorderSide(color: _border)),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: _accent,
        linearTrackColor: _border,
      ),
    );
  }
}

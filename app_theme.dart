import 'package:flutter/material.dart';

/// Defines LifeOS's Material 3 themes.
///
/// Every screen and widget in the app should read colors/typography from
/// `Theme.of(context)` rather than hardcoding values — this file is the
/// single source of truth for what the app looks like. If the brand color
/// changes, it changes here once, not in every widget that used it.
class AppTheme {
  // Private constructor: this class is never instantiated, it's just a
  // namespace for the two static theme getters below.
  AppTheme._();

  /// The single seed color both themes are generated from. Material 3's
  /// `ColorScheme.fromSeed` derives a full, accessible color palette
  /// (primary, secondary, surface, error, etc.) from one color, which is
  /// why we only need to pick one value here instead of dozens.
  static const Color _seedColor = Color(0xFF3D5AFE);

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _seedColor,
          brightness: Brightness.light,
        ),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _seedColor,
          brightness: Brightness.dark,
        ),
      );
}

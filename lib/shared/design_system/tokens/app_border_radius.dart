import 'package:flutter/material.dart';

/// Design tokens for border radius dimensions.
///
/// Ensures elements like cards, buttons, dialogs, and text fields have
/// consistent corners across light and dark interfaces.
class AppBorderRadius {
  AppBorderRadius._();

  /// Small corner radius (4.0).
  static const double s = 4.0;

  /// Medium corner radius (8.0).
  static const double m = 8.0;

  /// Large corner radius (12.0).
  static const double l = 12.0;

  /// Extra large corner radius (16.0).
  static const double xl = 16.0;

  /// Value to create fully circular surfaces.
  static const double circular = 9999.0;

  // BorderRadius objects

  /// Small radius applied to all corners.
  static const BorderRadius allS = BorderRadius.all(Radius.circular(s));

  /// Medium radius applied to all corners.
  static const BorderRadius allM = BorderRadius.all(Radius.circular(m));

  /// Large radius applied to all corners.
  static const BorderRadius allL = BorderRadius.all(Radius.circular(l));

  /// Extra large radius applied to all corners.
  static const BorderRadius allXL = BorderRadius.all(Radius.circular(xl));

  /// Circular radius applied to all corners.
  static const BorderRadius allCircular = BorderRadius.all(Radius.circular(circular));

  /// Pill-style radius applied to all corners (equivalent to circular).
  static const BorderRadius pill = BorderRadius.all(Radius.circular(circular));

  /// Radius applied only to the right corners (top-right and bottom-right).
  static const BorderRadius rightOnly = BorderRadius.only(
    topRight: Radius.circular(l),
    bottomRight: Radius.circular(l),
  );
}

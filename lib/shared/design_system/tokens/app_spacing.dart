import 'package:flutter/material.dart';

/// Spacing design tokens and layout utility variables.
///
/// Provides a consistent set of dimensions for margins, padding, and
/// component gaps. Use the vertical (`v*`) and horizontal (`h*`) [SizedBox]
/// helpers to insert clean layout spacing directly into widget lists.
class AppSpacing {
  AppSpacing._();

  /// Tiny spacing (4.0). Useful for very tight text padding or label separation.
  static const double xxs = 4.0;

  /// Extra small spacing (8.0). Standard gap between inputs or titles/descriptions.
  static const double xs = 8.0;

  /// Small spacing (12.0). Standard gap inside smaller cards or compact list items.
  static const double s = 12.0;

  /// Medium spacing (16.0). Default padding value for content columns and page margins.
  static const double m = 16.0;

  /// Large spacing (24.0). Used for major sections, card padding, and page headers.
  static const double l = 24.0;

  /// Extra large spacing (32.0). Used for layout-level gaps or top-page spacing.
  static const double xl = 32.0;

  /// Huge spacing (48.0). Used for large visual separations (e.g. form block boundaries).
  static const double xxl = 48.0;

  // Horizontal Spacing Helpers

  /// Horizontal space: 4.0 wide.
  static const SizedBox hXXS = SizedBox(width: xxs);

  /// Horizontal space: 8.0 wide.
  static const SizedBox hXS = SizedBox(width: xs);

  /// Horizontal space: 12.0 wide.
  static const SizedBox hS = SizedBox(width: s);

  /// Horizontal space: 16.0 wide.
  static const SizedBox hM = SizedBox(width: m);

  /// Horizontal space: 24.0 wide.
  static const SizedBox hL = SizedBox(width: l);

  /// Horizontal space: 32.0 wide.
  static const SizedBox hXL = SizedBox(width: xl);

  /// Horizontal space: 48.0 wide.
  static const SizedBox hXXL = SizedBox(width: xxl);

  // Vertical Spacing Helpers

  /// Vertical space: 4.0 high.
  static const SizedBox vXXS = SizedBox(height: xxs);

  /// Vertical space: 8.0 high.
  static const SizedBox vXS = SizedBox(height: xs);

  /// Vertical space: 12.0 high.
  static const SizedBox vS = SizedBox(height: s);

  /// Vertical space: 16.0 high.
  static const SizedBox vM = SizedBox(height: m);

  /// Vertical space: 24.0 high.
  static const SizedBox vL = SizedBox(height: l);

  /// Vertical space: 32.0 high.
  static const SizedBox vXL = SizedBox(height: xl);

  /// Vertical space: 48.0 high.
  static const SizedBox vXXL = SizedBox(height: xxl);
}

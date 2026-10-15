import 'package:flutter/material.dart';

/// Extension on [BuildContext] that adds responsive layout helper properties and methods.
///
/// Makes it easy to adapt UI layouts, dimensions, or value configurations
/// across varying screen size breakpoints (Mobile, Tablet, Desktop).
extension ResponsiveContext on BuildContext {
  /// Returns the current screen width.
  double get screenWidth => MediaQuery.of(this).size.width;

  /// Returns the current screen height.
  double get screenHeight => MediaQuery.of(this).size.height;

  /// Returns true if the screen width is less than 600px (Mobile range).
  bool get isMobile => screenWidth < 600;

  /// Returns true if the screen width is between 600px and 1200px (Tablet range).
  bool get isTablet => screenWidth >= 600 && screenWidth < 1200;

  /// Returns true if the screen width is 1200px or greater (Desktop range).
  bool get isDesktop => screenWidth >= 1200;

  /// Selects and returns a generic value of type [T] corresponding to the active screen breakpoint.
  ///
  /// Example:
  /// ```dart
  /// final gridCols = context.responsive<int>(mobile: 1, tablet: 2, desktop: 3);
  /// ```
  T responsive<T>({
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop && desktop != null) return desktop;
    if (isTablet && tablet != null) return tablet;
    return mobile;
  }
}

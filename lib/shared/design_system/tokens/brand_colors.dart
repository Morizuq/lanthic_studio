import 'package:flutter/material.dart';

/// A [ThemeExtension] that defines custom brand colors not covered by the default
/// Material 3 [ColorScheme].
///
/// This extension allows adding custom brand styles (e.g. logo color, gradient accents)
/// that adapt dynamically when toggling between light and dark mode.
class BrandColors extends ThemeExtension<BrandColors> {
  /// The main dark tone of the brand (used for primary text or dark logo backgrounds).
  final Color dark;

  /// The medium tone of the brand (used for prominent accents or borders).
  final Color mid;

  /// The very light, subtle tone of the brand (used for cards or hero backgrounds).
  final Color subtle;

  /// The highly visible accent tone (used for highlight pills, tags, or focus indicators).
  final Color accent;

  const BrandColors({
    required this.dark,
    required this.mid,
    required this.subtle,
    required this.accent,
  });

  @override
  BrandColors copyWith({
    Color? dark,
    Color? mid,
    Color? subtle,
    Color? accent,
  }) {
    return BrandColors(
      dark: dark ?? this.dark,
      mid: mid ?? this.mid,
      subtle: subtle ?? this.subtle,
      accent: accent ?? this.accent,
    );
  }

  @override
  BrandColors lerp(ThemeExtension<BrandColors>? other, double t) {
    if (other is! BrandColors) return this;
    return BrandColors(
      dark: Color.lerp(dark, other.dark, t)!,
      mid: Color.lerp(mid, other.mid, t)!,
      subtle: Color.lerp(subtle, other.subtle, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
    );
  }
}

/// Helper extension to easily access [BrandColors] directly from the [BuildContext].
extension BrandColorsBuildContext on BuildContext {
  /// Resolves the current theme's brand color configurations.
  BrandColors get brandColors => Theme.of(this).extension<BrandColors>()!;
}

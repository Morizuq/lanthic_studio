import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Lanthic Brand Core Colors (Electric Cyan Flame & Lantern Bronze)
  static const Color primary = Color(0xFF00B8FF);
  static const Color primaryLight = Color(0xFF38BDF8);
  static const Color primaryDark = Color(0xFF0284C7);
  static const Color onPrimary = Color(0xFF000000);

  // Lantern Warm Copper / Bronze Ambient Accent
  static const Color lanternAccent = Color(0xFFE28B47);
  static const Color lanternGlow = Color(0xFF00D2FF);

  // Dark Theme Studio Palette (Deep Midnight Obsidian & Charcoal Slate)
  static const Color backgroundDark = Color(0xFF090C12);
  static const Color surfaceDark = Color(0xFF0E121B);
  static const Color surfaceContainerLowDark = Color(0xFF131822);
  static const Color surfaceContainerHighestDark = Color(0xFF1A212E);
  static const Color onBackgroundDark = Color(0xFFF1F5F9);
  static const Color onSurfaceDark = Color(0xFFE2E8F0);
  static const Color onSurfaceVariantDark = Color(0xFF8A98AC);
  // Minimalist Whisper Borders (Ultra soft 8-12% opacity to avoid heavy border clutter)
  static const Color borderDark = Color(0x1FFFFFFF);
  static const Color borderHighlightDark = Color(0x3300B8FF);

  // Light Theme Studio Palette (Crisp Minimalist Paper Slate)
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceContainerLowLight = Color(0xFFF1F5F9);
  static const Color surfaceContainerHighestLight = Color(0xFFE2E8F0);
  static const Color onBackgroundLight = Color(0xFF0F172A);
  static const Color onSurfaceLight = Color(0xFF1E293B);
  static const Color onSurfaceVariantLight = Color(0xFF64748B);
  static const Color borderLight = Color(0x14000000);

  // Status colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
}

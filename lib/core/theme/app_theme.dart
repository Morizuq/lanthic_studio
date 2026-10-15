import 'package:flutter/material.dart';
import '../../shared/design_system/tokens/brand_colors.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.backgroundLight,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: Colors.white,
        primaryContainer: Color(0xFFE0F5FE),
        onPrimaryContainer: Color(0xFF0369A1),
        secondary: Color(0xFF0284C7),
        onSecondary: Colors.white,
        surface: AppColors.surfaceLight,
        onSurface: AppColors.onSurfaceLight,
        surfaceContainerLow: AppColors.surfaceContainerLowLight,
        surfaceContainerHighest: AppColors.surfaceContainerHighestLight,
        outline: AppColors.borderLight,
        outlineVariant: Color(0x14000000),
        error: AppColors.error,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surfaceLight,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.surfaceLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0x0F000000),
        thickness: 1,
        space: 1,
      ),
      extensions: const [
        BrandColors(
          dark: Color(0xFF082F49),
          mid: Color(0xFF0284C7),
          subtle: Color(0xFFE0F2FE),
          accent: Color(0xFF38BDF8),
        ),
      ],
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.backgroundDark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        primaryContainer: Color(0xFF003850),
        onPrimaryContainer: Color(0xFFBCEBFF),
        secondary: AppColors.primaryLight,
        onSecondary: Color(0xFF08121E),
        secondaryContainer: Color(0xFF0C4A6E),
        onSecondaryContainer: Color(0xFFE0F2FE),
        surface: AppColors.surfaceDark,
        onSurface: AppColors.onSurfaceDark,
        surfaceContainerLow: AppColors.surfaceContainerLowDark,
        surfaceContainerHighest: AppColors.surfaceContainerHighestDark,
        outline: AppColors.borderDark,
        outlineVariant: Color(0x14FFFFFF),
        error: AppColors.error,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surfaceDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.surfaceContainerLowDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0x12FFFFFF),
        thickness: 1,
        space: 1,
      ),
      extensions: const [
        BrandColors(
          dark: Color(0xFFE0F2FE),
          mid: Color(0xFF38BDF8),
          subtle: Color(0xFF082F49),
          accent: Color(0xFF0284C7),
        ),
      ],
    );
  }
}

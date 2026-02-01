import 'package:flutter/material.dart';

/// App color palette
class AppColors {
  AppColors._();

  // Primary Colors
  static const Color primary = Color(0xFF6B9BD1);
  static const Color primaryLight = Color(0xFF9BC1E8);
  static const Color primaryDark = Color(0xFF4A7AB0);

  // Text Colors
  static const Color textPrimary = Color(0xFF2D3748);
  static const Color textSecondary = Color(0xFF718096);
  static const Color textHint = Color(0xFFA0AEC0);
  static const Color textGreen = Color(0xFF8FB996);

  // Background Colors
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF7F7F5);
  static const Color surfaceLight = Color(0xFFFAFAFA);
  static const Color surfaceRed = Color(0xFFFEE2E2);

  // Border Colors
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderFocused = Color(0xFF6B9BD1);

  // Status Colors
  static const Color success = Color(0xFF68D391);
  static const Color warning = Color(0xFFF6E05E);
  static const Color error = Color(0xFFDC2626);
  static const Color info = Color(0xFF63B3ED);

  // Stress Level Colors
  static const Color stressLow = Color(0xFF68D391);
  static const Color stressMedium = Color(0xFFF6AD55);
  static const Color stressHigh = Color(0xFFFC8181);

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryLight],
  );

  static const LinearGradient calmGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFE8F4FD), Color(0xFFFFFFFF)],
  );
}

/// App text styles
class AppTextStyles {
  AppTextStyles._();

  // Headings
  static const TextStyle h1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
  );

  static const TextStyle h2 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
  );

  static const TextStyle h3 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle h4 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  // Body
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
  );

  // Labels
  static const TextStyle label = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  // Button
  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  // Link
  static TextStyle link = const TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.primary,
  );
}

/// App spacing constants
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  // Padding
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(horizontal: 24);
  static const EdgeInsets cardPadding = EdgeInsets.all(16);
  static const EdgeInsets inputPadding = EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 16,
  );
}

/// App border radius
class AppRadius {
  AppRadius._();

  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double round = 100;

  static BorderRadius get smBorder => BorderRadius.circular(sm);
  static BorderRadius get mdBorder => BorderRadius.circular(md);
  static BorderRadius get lgBorder => BorderRadius.circular(lg);
  static BorderRadius get xlBorder => BorderRadius.circular(xl);
  static BorderRadius get roundBorder => BorderRadius.circular(round);
}

/// App shadows
class AppShadows {
  AppShadows._();

  static List<BoxShadow> get small => [
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get medium => [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get large => [
    BoxShadow(
      color: Colors.black.withOpacity(0.1),
      blurRadius: 16,
      offset: const Offset(0, 8),
    ),
  ];
}

/// App animation durations
class AppDurations {
  AppDurations._();

  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration pageTransition = Duration(milliseconds: 350);
}

import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF00004D);
  static const primaryDark = Color(0xFF00002E);
  static const primaryLight = Color(0xFF1A1A8C);
  static const accent = Color(0xFFFFCC00);
  static const accentDark = Color(0xFFE6B800);
  static const background = Color(0xFFF5F6FA);
  static const card = Color(0xFFFFFFFF);
  static const textPrimary = Color(0xFF1A1A2E);
  static const textSecondary = Color(0xFF4A4A6A);
  static const textMuted = Color(0xFF8A8AAD);
  static const success = Color(0xFF059669);
  static const successLight = Color(0xFFD1FAE5);
  static const warning = Color(0xFFF59E0B);
  static const warningLight = Color(0xFFFEF3C7);
  static const danger = Color(0xFFDC2626);
  static const dangerLight = Color(0xFFFEE2E2);
  static const surface = Color(0xFFF0F1F8);
  static const border = Color(0xFFE2E4F0);

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A1A8C), Color(0xFF00004D)],
  );

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A1A8C), Color(0xFF00003A), Color(0xFF00004D)],
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFE066), Color(0xFFFFCC00)],
  );
}

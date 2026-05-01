import 'package:flutter/material.dart';

class AppColors {
  final Color bg;
  final Color bgDeep;
  final Color card;
  final Color ink;
  final Color inkMuted;
  final Color inkSubtle;
  final Color line;
  final Color accent;
  final Color accentSoft;

  const AppColors({
    required this.bg,
    required this.bgDeep,
    required this.card,
    required this.ink,
    required this.inkMuted,
    required this.inkSubtle,
    required this.line,
    required this.accent,
    required this.accentSoft,
  });
}

class AppThemes {
  static const amber = AppColors(
    bg: Color(0xFFFBF5EC),
    bgDeep: Color(0xFFF4EAD8),
    card: Color(0xFFFFFFFF),
    ink: Color(0xFF2A1E14),
    inkMuted: Color(0x942A1E14),
    inkSubtle: Color(0x522A1E14),
    line: Color(0x172A1E14),
    accent: Color(0xFFC2410C),
    accentSoft: Color(0xFFFDE4CF),
  );

  static const terracotta = AppColors(
    bg: Color(0xFFF7EFE6),
    bgDeep: Color(0xFFEEDFCE),
    card: Color(0xFFFFFFFF),
    ink: Color(0xFF3A2618),
    inkMuted: Color(0x943A2618),
    inkSubtle: Color(0x523A2618),
    line: Color(0x1A3A2618),
    accent: Color(0xFFB3541B),
    accentSoft: Color(0xFFF8D9C0),
  );

  static const olive = AppColors(
    bg: Color(0xFFF6F2E6),
    bgDeep: Color(0xFFECE5D0),
    card: Color(0xFFFFFFFF),
    ink: Color(0xFF2E2A18),
    inkMuted: Color(0x942E2A18),
    inkSubtle: Color(0x4D2E2A18),
    line: Color(0x172E2A18),
    accent: Color(0xFF7A6A1F),
    accentSoft: Color(0xFFEBE1B8),
  );

  static AppColors byName(String name) {
    switch (name) {
      case 'terracotta': return terracotta;
      case 'olive': return olive;
      default: return amber;
    }
  }
}

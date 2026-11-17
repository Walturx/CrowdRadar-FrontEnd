import 'package:flutter/material.dart';

/// Design-system palette (docs/rediseno/design-system.md, section 2).
///
/// Green, amber and red are reserved for saturation levels; the rest of the
/// interface is neutral with the brand blue.
class AppColors {
  const AppColors._();

  // Brand.
  static const Color primary = Color(0xFF1A3C8F);
  static const Color primaryPressed = Color(0xFF142F72);
  static const Color primaryContainer = Color(0xFFDCE4F7);
  static const Color primarySoft = Color(0xFFEEF2FB);

  // Neutrals.
  static const Color bg = Color(0xFFF5F7FB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color text = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF334155);
  static const Color textMuted = Color(0xFF5B6B80);
  static const Color border = Color(0xFFE2E8F0);
  static const Color iconMuted = Color(0xFF94A3B8);

  // System states.
  static const Color danger = Color(0xFFB91C1C);
  static const Color dangerBg = Color(0xFFFEE2E2);
  static const Color dangerBorder = Color(0xFFFBCACA);
  static const Color userLocation = Color(0xFF2563EB);

  // Saturation levels: text (fg), background (Bg) and pin/chart (Dot).
  static const Color tranquilo = Color(0xFF15803D);
  static const Color tranquiloBg = Color(0xFFDCFCE7);
  static const Color tranquiloDot = Color(0xFF22C55E);
  static const Color moderado = Color(0xFFB45309);
  static const Color moderadoBg = Color(0xFFFEF3C7);
  static const Color moderadoDot = Color(0xFFF59E0B);
  static const Color saturado = Color(0xFFB91C1C);
  static const Color saturadoBg = Color(0xFFFEE2E2);
  static const Color saturadoDot = Color(0xFFEF4444);
  static const Color sinDatos = Color(0xFF5B6B80);
  static const Color sinDatosBg = Color(0xFFF1F5F9);
  static const Color sinDatosDot = Color(0xFF94A3B8);

  // Temporary aliases (decision D7): removed before CRO-88 closes.
  @Deprecated('Use AppColors.primary')
  static const Color secondary = primary;
  @Deprecated('Use AppColors.tranquilo (levels only)')
  static const Color success = tranquilo;
  @Deprecated('Use AppColors.moderado (levels only)')
  static const Color warning = moderado;
  @Deprecated('Use AppColors.border')
  static const Color borderNav = border;
  @Deprecated('The blue header that used it is removed by the redesign')
  static const Color onPrimaryMuted = Color(0xFFA9C8EC);
}

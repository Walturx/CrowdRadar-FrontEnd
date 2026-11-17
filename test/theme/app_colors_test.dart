import 'dart:math' as math;

import 'package:crowdradar/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// WCAG 2.x contrast ratio between two opaque colors.
double contrast(Color a, Color b) {
  double channel(double c) =>
      c <= 0.03928 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
  double luminance(Color c) =>
      0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);
  final la = luminance(a);
  final lb = luminance(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  group('design-system palette values', () {
    test('brand and neutrals match the design system', () {
      expect(AppColors.primary, const Color(0xFF1A3C8F));
      expect(AppColors.primaryPressed, const Color(0xFF142F72));
      expect(AppColors.primaryContainer, const Color(0xFFDCE4F7));
      expect(AppColors.primarySoft, const Color(0xFFEEF2FB));
      expect(AppColors.text, const Color(0xFF0F172A));
      expect(AppColors.textSecondary, const Color(0xFF334155));
      expect(AppColors.textMuted, const Color(0xFF5B6B80));
      expect(AppColors.border, const Color(0xFFE2E8F0));
      expect(AppColors.bg, const Color(0xFFF5F7FB));
      expect(AppColors.surface, const Color(0xFFFFFFFF));
      expect(AppColors.danger, const Color(0xFFB91C1C));
      expect(AppColors.dangerBg, const Color(0xFFFEE2E2));
      expect(AppColors.dangerBorder, const Color(0xFFFBCACA));
      expect(AppColors.userLocation, const Color(0xFF2563EB));
    });

    test('each saturation level has text, background and dot colors', () {
      expect(AppColors.tranquilo, const Color(0xFF15803D));
      expect(AppColors.tranquiloBg, const Color(0xFFDCFCE7));
      expect(AppColors.tranquiloDot, const Color(0xFF22C55E));
      expect(AppColors.moderado, const Color(0xFFB45309));
      expect(AppColors.moderadoBg, const Color(0xFFFEF3C7));
      expect(AppColors.moderadoDot, const Color(0xFFF59E0B));
      expect(AppColors.saturado, const Color(0xFFB91C1C));
      expect(AppColors.saturadoBg, const Color(0xFFFEE2E2));
      expect(AppColors.saturadoDot, const Color(0xFFEF4444));
      expect(AppColors.sinDatos, const Color(0xFF5B6B80));
      expect(AppColors.sinDatosBg, const Color(0xFFF1F5F9));
      expect(AppColors.sinDatosDot, const Color(0xFF94A3B8));
    });
  });

  group('contrast (WCAG AA, 4.5:1 for body text)', () {
    const levels = {
      'tranquilo': (AppColors.tranquilo, AppColors.tranquiloBg),
      'moderado': (AppColors.moderado, AppColors.moderadoBg),
      'saturado': (AppColors.saturado, AppColors.saturadoBg),
      'sinDatos': (AppColors.sinDatos, AppColors.sinDatosBg),
    };

    for (final MapEntry(key: name, value: (fg, bg)) in levels.entries) {
      test('$name text is readable on its own background and on white', () {
        expect(contrast(fg, bg), greaterThanOrEqualTo(4.5));
        expect(contrast(fg, AppColors.surface), greaterThanOrEqualTo(4.5));
      });
    }

    test(
      'secondary text is readable on white and on the screen background',
      () {
        expect(
          contrast(AppColors.textMuted, AppColors.surface),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          contrast(AppColors.textMuted, AppColors.bg),
          greaterThanOrEqualTo(4.5),
        );
      },
    );

    test('danger text is readable on its background', () {
      expect(
        contrast(AppColors.danger, AppColors.dangerBg),
        greaterThanOrEqualTo(4.5),
      );
    });

    test('white text is readable on the brand button', () {
      expect(
        contrast(Colors.white, AppColors.primary),
        greaterThanOrEqualTo(4.5),
      );
    });
  });
}

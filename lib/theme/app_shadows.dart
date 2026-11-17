import 'package:flutter/material.dart';

/// Design-system shadows (docs/rediseno/design-system.md, section 4).
class AppShadows {
  const AppShadows._();

  /// `shadow-1`: cards and chips.
  static const List<BoxShadow> card = [
    BoxShadow(color: Color(0x0F0F172A), offset: Offset(0, 1), blurRadius: 2),
    BoxShadow(color: Color(0x0A0F172A), offset: Offset(0, 1), blurRadius: 1),
  ];

  /// `shadow-2`: elements floating over the map.
  static const List<BoxShadow> floating = [
    BoxShadow(color: Color(0x1A0F172A), offset: Offset(0, 8), blurRadius: 24),
    BoxShadow(color: Color(0x0F0F172A), offset: Offset(0, 2), blurRadius: 6),
  ];

  /// Only the filled brand button.
  static const List<BoxShadow> primaryButton = [
    BoxShadow(color: Color(0x471A3C8F), offset: Offset(0, 6), blurRadius: 16),
  ];
}

import 'package:crowdradar/theme/app_colors.dart';
import 'package:crowdradar/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final theme = AppTheme.lightTheme;

  test('the theme is built once and shared by the boot and the app', () {
    expect(identical(AppTheme.lightTheme, AppTheme.lightTheme), isTrue);
  });

  test('the theme uses the brand primary color', () {
    expect(theme.colorScheme.primary, AppColors.primary);
  });

  test('the whole app uses the Inter font', () {
    expect(theme.textTheme.bodyMedium?.fontFamily, 'Inter');
    expect(theme.appBarTheme.titleTextStyle?.fontFamily, 'Inter');
  });

  test('screens use the neutral background, not the old pale green', () {
    expect(theme.scaffoldBackgroundColor, AppColors.bg);
  });

  test('cards are flat, white, with radius 20 and a border', () {
    final card = theme.cardTheme;
    expect(card.elevation, 0);
    expect(card.color, AppColors.surface);
    final shape = card.shape! as RoundedRectangleBorder;
    expect(shape.borderRadius, BorderRadius.circular(20));
    expect(shape.side.color, AppColors.border);
  });

  test('text fields have radius 14 and a 1.5 border that turns brand on focus', () {
    final input = theme.inputDecorationTheme;
    final enabled = input.enabledBorder! as OutlineInputBorder;
    final focused = input.focusedBorder! as OutlineInputBorder;
    expect(enabled.borderRadius, BorderRadius.circular(14));
    expect(enabled.borderSide.width, 1.5);
    expect(enabled.borderSide.color, AppColors.border);
    expect(focused.borderSide.color, AppColors.primary);
  });

  test('the secondary button has a brand-100 border', () {
    final side = theme.outlinedButtonTheme.style!.side!.resolve({})!;
    expect(side.color, AppColors.primaryContainer);
    expect(side.width, 1.5);
  });

  test('buttons are 52 high with 16/600 text', () {
    final style = theme.elevatedButtonTheme.style!;
    expect(style.minimumSize!.resolve({})!.height, 52);
    final text = style.textStyle!.resolve({})!;
    expect(text.fontSize, 16);
    expect(text.fontWeight, FontWeight.w600);
  });

  test('the bottom sheet has radius 28 on top', () {
    final shape = theme.bottomSheetTheme.shape! as RoundedRectangleBorder;
    expect(
      shape.borderRadius,
      const BorderRadius.vertical(top: Radius.circular(28)),
    );
  });

  test('the admin navigation bar highlights the active item with brand-100', () {
    expect(theme.navigationBarTheme.indicatorColor, AppColors.primaryContainer);
  });
}

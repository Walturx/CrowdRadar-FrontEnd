import 'package:crowdradar/theme/app_colors.dart';
import 'package:crowdradar/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the theme is built once and shared by the boot and the app', () {
    expect(identical(AppTheme.lightTheme, AppTheme.lightTheme), isTrue);
  });

  test('the theme uses the brand primary color', () {
    expect(AppTheme.lightTheme.colorScheme.primary, AppColors.primary);
  });
}

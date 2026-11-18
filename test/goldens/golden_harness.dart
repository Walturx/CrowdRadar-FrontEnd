import 'package:crowdradar/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fixed phone surface for every baseline golden: 390 x 844 logical pixels at
/// device pixel ratio 1 (a common modern phone in portrait).
const Size phoneSurface = Size(390, 844);

/// Sets the fixed phone surface and restores the view after the test.
void usePhoneSurface(WidgetTester tester) {
  tester.view.physicalSize = phoneSurface;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// `MaterialApp.builder` that disables animations, like a device with
/// "remove animations" turned on.
Widget withoutAnimations(BuildContext context, Widget? child) => MediaQuery(
  data: MediaQuery.of(context).copyWith(disableAnimations: true),
  child: child!,
);

/// Theme every golden renders with: the real app theme, with one test-only
/// adjustment (see [_fillPlatformFont]).
ThemeData get appTheme => _fillPlatformFont(AppTheme.lightTheme);

/// Family a device uses when a TextStyle names none: the app font.
const String _platformFont = AppTheme.fontFamily;

/// The test engine draws text whose style names no font family with its own
/// box font, and that cannot be overridden from Dart. Theme styles that
/// replace (not merge) the default text style, such as the app bar title and
/// button labels, name no family, so this fills [_platformFont] into them,
/// which is what a device renders. Styles that already name a family are
/// left untouched.
ThemeData _fillPlatformFont(ThemeData theme) {
  TextStyle? fill(TextStyle? s) => s == null || s.fontFamily != null
      ? s
      : s.copyWith(fontFamily: _platformFont);

  ButtonStyle? fillButton(ButtonStyle? style) {
    final textStyle = style?.textStyle;
    if (style == null || textStyle == null) return style;
    return style.copyWith(
      textStyle: WidgetStateProperty.resolveWith(
        (states) => fill(textStyle.resolve(states)),
      ),
    );
  }

  return theme.copyWith(
    appBarTheme: theme.appBarTheme.copyWith(
      titleTextStyle: fill(theme.appBarTheme.titleTextStyle),
      toolbarTextStyle: fill(theme.appBarTheme.toolbarTextStyle),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: fillButton(theme.elevatedButtonTheme.style),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: fillButton(theme.outlinedButtonTheme.style),
    ),
    textButtonTheme: TextButtonThemeData(
      style: fillButton(theme.textButtonTheme.style),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: fillButton(theme.filledButtonTheme.style),
    ),
  );
}

/// Decodes every on-screen asset image (decoding needs real async) and
/// settles, so badges and logos appear in the image instead of blank boxes.
Future<void> loadImages(WidgetTester tester) async {
  await tester.runAsync(() async {
    for (final element in find.byType(Image).evaluate()) {
      final image = element.widget as Image;
      await precacheImage(image.image, element);
    }
  });
  await tester.pumpAndSettle();
}

/// Removes keyboard focus so no caret ends up in the image.
Future<void> clearFocus(WidgetTester tester) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
}

/// Compares the whole screen with `baseline/<name>.png`.
Future<void> matchBaseline(String name) => expectLater(
  find.byType(MaterialApp),
  matchesGoldenFile('baseline/$name.png'),
);

/// Same as [matchBaseline], but crops the image to [finder], for captures
/// that are about one component (for example the bottom navigation bar).
Future<void> matchBaselineOf(Finder finder, String name) =>
    expectLater(finder, matchesGoldenFile('baseline/$name.png'));

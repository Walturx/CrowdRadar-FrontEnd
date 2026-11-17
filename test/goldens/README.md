# Baseline goldens (CRO-88)

Screenshots of the app's screens taken **before** the visual redesign. After
each restyle they are regenerated and the image diffs are reviewed one by one.

## Run

```sh
flutter test test/goldens                  # compare against baseline/
flutter test --update-goldens test/goldens # regenerate baseline/
```

## Choices

- **Surface:** 390 x 844 logical pixels, device pixel ratio 1
  (`phoneSurface` in `golden_harness.dart`). Content below the fold is not in
  the image unless the test scrolls to it (the profile tier cards do).
- **Theme:** the real `AppTheme.lightTheme`. Animations are disabled through
  `MediaQuery.disableAnimations` and every test settles before capturing.
- **Fonts:** `flutter_test_config.dart` (only applies to this folder) loads
  Roboto and MaterialIcons from the Flutter SDK
  (`<flutter root>/bin/cache/artifacts/material_fonts/`). The SDK root comes
  from `FLUTTER_ROOT`, or from the location of the test runner executable; if
  neither is found the text falls back to Ahem boxes and a warning is printed.
- **Text with no font family:** the test engine draws it with its own box font
  and Dart cannot override that. The harness fills `Roboto` (what an Android
  device uses) into the theme styles that name no family: app bar title and
  button labels. Text styled inline inside a button by a screen would still be
  boxes.
- **Emojis** (today's category icons) render as empty boxes: there is no emoji
  font in the SDK. This is expected until the redesign replaces them.
- **Map:** a flat background with the real pins at fixed spots; no tiles are
  ever loaded.
- **Dates:** built relative to `DateTime.now()` with a few seconds of margin
  (for example 4 min 10 s ago reads "hace 4 min"). Fakes that stamp "now"
  read "ahora". The 7-day history is not captured because its data depends on
  the weekday.
- **Platform:** golden comparison is pixel exact and font rasterization
  differs between operating systems. These images were generated on Windows;
  regenerate them on the machine that compares them.

// Host side of the perf harness: receives the `watchPerformance` summaries
// reported by integration_test/perf/app_perf_test.dart and writes them to
// build/perf/ (raw JSON per scenario + a Markdown table).
//
// flutter drive --profile --driver=test_driver/perf_driver.dart \
//   --target=integration_test/perf/app_perf_test.dart \
//   --dart-define=PERF_ADMIN_EMAIL=... --dart-define=PERF_ADMIN_PASSWORD=...
import 'dart:convert';
import 'dart:io';

import 'package:integration_test/integration_test_driver.dart';

/// One frame budget at 60 Hz.
const int _presupuestoUs = 16667;

Future<void> main() => integrationDriver(
  responseDataCallback: (datos) async {
    if (datos == null) return;
    final dir = Directory('build/perf')..createSync(recursive: true);
    final tabla = StringBuffer()
      ..writeln(
        '| Escenario | Frames | Build prom / p90 / p99 (ms) '
        '| Raster prom / p90 / p99 (ms) | Frames > 16 ms (build o raster) |',
      )
      ..writeln('|---|---:|---|---|---:|');
    for (final MapEntry(:key, :value) in datos.entries) {
      final resumen = Map<String, dynamic>.from(value as Map);
      File(
        '${dir.path}/$key.json',
      ).writeAsStringSync(const JsonEncoder.withIndent('  ').convert(resumen));
      final build = List<int>.from(resumen['frame_build_times'] as List);
      final raster = List<int>.from(resumen['frame_rasterizer_times'] as List);
      var lentos = 0;
      for (var i = 0; i < build.length; i++) {
        if (build[i] > _presupuestoUs || raster[i] > _presupuestoUs) lentos++;
      }
      String ms(String k) => (resumen[k] as num).toStringAsFixed(2);
      final pct = build.isEmpty ? 0 : lentos * 100 / build.length;
      tabla.writeln(
        '| $key | ${build.length} '
        '| ${ms('average_frame_build_time_millis')} / '
        '${ms('90th_percentile_frame_build_time_millis')} / '
        '${ms('99th_percentile_frame_build_time_millis')} '
        '| ${ms('average_frame_rasterizer_time_millis')} / '
        '${ms('90th_percentile_frame_rasterizer_time_millis')} / '
        '${ms('99th_percentile_frame_rasterizer_time_millis')} '
        '| $lentos (${pct.toStringAsFixed(1)} %) |',
      );
    }
    File('${dir.path}/resumen.md').writeAsStringSync(tabla.toString());
    stdout.write(tabla);
  },
);

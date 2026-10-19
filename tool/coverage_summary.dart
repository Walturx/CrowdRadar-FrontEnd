// Summarizes coverage/lcov.info without lcov/genhtml.
//
// Usage: dart run tool/coverage_summary.dart [path/to/lcov.info]
//
// Prints total line coverage, coverage restricted to lib/features and a
// per-feature breakdown (lib/features/<feature>/...) as Markdown tables.
import 'dart:io';

class _Cobertura {
  int encontradas = 0;
  int cubiertas = 0;

  void sumar(int lf, int lh) {
    encontradas += lf;
    cubiertas += lh;
  }

  String get porcentaje => encontradas == 0
      ? '-'
      : '${(cubiertas * 100 / encontradas).toStringAsFixed(1)} %';
}

void main(List<String> args) {
  final ruta = args.isEmpty ? 'coverage/lcov.info' : args.first;
  final archivo = File(ruta);
  if (!archivo.existsSync()) {
    stderr.writeln('No existe $ruta; ejecuta "flutter test --coverage".');
    exitCode = 1;
    return;
  }

  final total = _Cobertura();
  final features = _Cobertura();
  final porFeature = <String, _Cobertura>{};
  final porCapa = <String, _Cobertura>{};
  var archivos = 0;

  String? actual;
  var lf = 0;
  var lh = 0;
  for (final linea in archivo.readAsLinesSync()) {
    if (linea.startsWith('SF:')) {
      actual = linea.substring(3).replaceAll('\\', '/');
      lf = 0;
      lh = 0;
    } else if (linea.startsWith('DA:')) {
      final partes = linea.substring(3).split(',');
      lf++;
      if (int.parse(partes[1]) > 0) lh++;
    } else if (linea == 'end_of_record' && actual != null) {
      archivos++;
      total.sumar(lf, lh);
      final i = actual.indexOf('lib/');
      final relativa = i < 0 ? actual : actual.substring(i);
      final segmentos = relativa.split('/');
      final capa = segmentos.length > 2 ? segmentos[1] : '(raiz)';
      porCapa.putIfAbsent(capa, _Cobertura.new).sumar(lf, lh);
      if (relativa.startsWith('lib/features/') && segmentos.length > 3) {
        features.sumar(lf, lh);
        porFeature.putIfAbsent(segmentos[2], _Cobertura.new).sumar(lf, lh);
      }
      actual = null;
    }
  }

  void fila(String nombre, _Cobertura c) => stdout.writeln(
    '| $nombre | ${c.cubiertas} | ${c.encontradas} | ${c.porcentaje} |',
  );

  stdout
    ..writeln('Archivos en lcov: $archivos')
    ..writeln()
    ..writeln(
      '| Ambito | Lineas cubiertas | Lineas instrumentadas | Cobertura |',
    )
    ..writeln('|---|---:|---:|---:|');
  fila('Total (lib/)', total);
  fila('lib/features', features);
  stdout
    ..writeln()
    ..writeln(
      '| Carpeta de lib/ | Lineas cubiertas | Lineas instrumentadas | Cobertura |',
    )
    ..writeln('|---|---:|---:|---:|');
  for (final e
      in porCapa.entries.toList()..sort((a, b) => a.key.compareTo(b.key))) {
    fila(e.key, e.value);
  }
  stdout
    ..writeln()
    ..writeln(
      '| Feature | Lineas cubiertas | Lineas instrumentadas | Cobertura |',
    )
    ..writeln('|---|---:|---:|---:|');
  for (final e
      in porFeature.entries.toList()..sort((a, b) => a.key.compareTo(b.key))) {
    fila(e.key, e.value);
  }
}

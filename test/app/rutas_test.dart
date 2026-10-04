import 'package:crowdradar/app/rutas.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Rutas.relativa', () {
    test('strips the parent prefix of a :id template', () {
      expect(
        Rutas.relativa(Rutas.lugarPlantilla, Rutas.mapa),
        'lugares/:id',
      );
      expect(
        Rutas.relativa(Rutas.historialPlantilla, Rutas.lugarPlantilla),
        'historial',
      );
      expect(
        Rutas.relativa(Rutas.mejorHorarioPlantilla, Rutas.lugarPlantilla),
        'mejor-horario',
      );
      expect(
        Rutas.relativa(Rutas.adminReportePlantilla, Rutas.admin),
        'reportes/:id',
      );
    });
  });

  group('Rutas builders', () {
    test('substitute the id in the template', () {
      expect(Rutas.lugar(7), '/mapa/lugares/7');
      expect(Rutas.historial(7), '/mapa/lugares/7/historial');
      expect(Rutas.adminUsuario(3), '/admin/usuarios/3');
    });
  });
}

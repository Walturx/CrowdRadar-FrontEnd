import 'dart:async';

import 'package:crowdradar/core/models/categoria_lugar.dart';
import 'package:crowdradar/core/models/lugar_resumen.dart';
import 'package:crowdradar/core/models/nivel_saturacion.dart';
import 'package:crowdradar/core/network/api_exception.dart';
import 'package:crowdradar/core/network/respuesta_api.dart';
import 'package:crowdradar/features/lugares/buscar/buscar_lugar_cubit.dart';
import 'package:crowdradar/features/lugares/buscar/buscar_lugar_state.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/lugar_repo_falso.dart';

const _kennedy = LugarResumen(
  id: 1,
  nombre: 'Parque Kennedy',
  categoria: CategoriaLugar.parque,
  latitud: -12.1219,
  longitud: -77.0297,
  saturacion: NivelSaturacion.moderado,
);
const _exposicion = LugarResumen(
  id: 4,
  nombre: 'Parque de la Exposición',
  categoria: CategoriaLugar.parque,
  latitud: -12.0690,
  longitud: -77.0360,
  saturacion: NivelSaturacion.tranquilo,
);

const _espera = Duration(milliseconds: 400);
const _menos = Duration(milliseconds: 399);

void main() {
  group('server message and request shape', () {
    test('an empty result shows the server message when there is one', () {
      fakeAsync((reloj) {
        final cubit = BuscarLugarCubit(
          RepoLugarFalso(
            alBuscar: (_) => resultado([], mensaje: 'Nada por aquí.'),
          ),
        );

        cubit.alCambiarTexto('Zoológico');
        reloj.elapse(_espera);
        reloj.flushMicrotasks();

        expect((cubit.state as BuscarSinResultados).mensaje, 'Nada por aquí.');
        cubit.close();
      });
    });

    test(
      'an empty result without server message falls back to the HU text',
      () {
        fakeAsync((reloj) {
          final cubit = BuscarLugarCubit(
            RepoLugarFalso(alBuscar: (_) => resultado([])),
          );

          cubit.alCambiarTexto('Zoológico');
          reloj.elapse(_espera);
          reloj.flushMicrotasks();

          expect(
            (cubit.state as BuscarSinResultados).mensaje,
            'No encontramos lugares para “Zoológico”. Prueba con otro nombre.',
          );
          cubit.close();
        });
      },
    );

    test('always sends the results limit', () {
      fakeAsync((reloj) {
        final repo = RepoLugarFalso();
        final cubit = BuscarLugarCubit(repo);

        cubit.alCambiarTexto('Par');
        reloj.elapse(_espera);

        expect(BuscarLugarCubit.limiteResultados, 50);
        expect(repo.pedidos.single.limite, BuscarLugarCubit.limiteResultados);
        cubit.close();
      });
    });
  });

  group('repeated query and retry', () {
    test('the same trimmed text as the last query makes no new request', () {
      fakeAsync((reloj) {
        final repo = RepoLugarFalso();
        final cubit = BuscarLugarCubit(repo);

        cubit.alCambiarTexto('Par');
        reloj.elapse(_espera);
        reloj.flushMicrotasks();
        cubit.alCambiarTexto('  Par ');
        reloj.elapse(_espera);
        reloj.flushMicrotasks();

        expect(repo.pedidos, hasLength(1));
        cubit.close();
      });
    });

    test('going back to the last query cancels the pending different one', () {
      fakeAsync((reloj) {
        final repo = RepoLugarFalso();
        final cubit = BuscarLugarCubit(repo);

        cubit.alCambiarTexto('Par');
        reloj.elapse(_espera);
        cubit.alCambiarTexto('Parq');
        cubit.alCambiarTexto('Par');
        reloj.elapse(_espera);

        expect(repo.pedidos.map((p) => p.q), ['Par']);
        cubit.close();
      });
    });

    test('retry cancels a pending debounce timer', () {
      fakeAsync((reloj) {
        final repo = RepoLugarFalso();
        final cubit = BuscarLugarCubit(repo);

        cubit.alCambiarTexto('Par');
        reloj.elapse(_espera);
        cubit.alCambiarTexto('Parq');
        cubit.reintentar();
        reloj.elapse(_espera);
        reloj.flushMicrotasks();

        expect(repo.pedidos.map((p) => p.q), ['Par', 'Par']);
        cubit.close();
      });
    });
  });

  group('debounce and minimum length', () {
    test('starts Inicial', () {
      final cubit = BuscarLugarCubit(RepoLugarFalso());

      expect(cubit.state, const BuscarInicial());
      cubit.close();
    });

    test(
      'P, Pa, Par within the window make one call with q=Par and no bbox',
      () {
        fakeAsync((reloj) {
          final repo = RepoLugarFalso(alBuscar: (_) => resultado([_kennedy]));
          final cubit = BuscarLugarCubit(repo);

          cubit.alCambiarTexto('P');
          reloj.elapse(const Duration(milliseconds: 100));
          cubit.alCambiarTexto('Pa');
          reloj.elapse(const Duration(milliseconds: 100));
          cubit.alCambiarTexto('Par');
          reloj.elapse(_menos);
          expect(repo.pedidos, isEmpty);

          reloj.elapse(const Duration(milliseconds: 1));
          expect(repo.pedidos, hasLength(1));
          expect(repo.pedidos.single.q, 'Par');
          expect(repo.pedidos.single.bbox, isNull);
          cubit.close();
        });
      },
    );

    test('typing pauses longer than the window make one call each', () {
      fakeAsync((reloj) {
        final repo = RepoLugarFalso(alBuscar: (_) => resultado([_kennedy]));
        final cubit = BuscarLugarCubit(repo);

        cubit.alCambiarTexto('Par');
        reloj.elapse(_espera);
        cubit.alCambiarTexto('Parq');
        reloj.elapse(_espera);

        expect(repo.pedidos.map((p) => p.q), ['Par', 'Parq']);
        cubit.close();
      });
    });

    test('fewer than 2 chars never call the repository and stay Inicial', () {
      fakeAsync((reloj) {
        final repo = RepoLugarFalso(alBuscar: (_) => resultado([_kennedy]));
        final cubit = BuscarLugarCubit(repo);

        cubit.alCambiarTexto('P');
        reloj.elapse(const Duration(seconds: 2));
        cubit.alCambiarTexto(' a ');
        reloj.elapse(const Duration(seconds: 2));
        cubit.alCambiarTexto('');
        reloj.elapse(const Duration(seconds: 2));

        expect(repo.pedidos, isEmpty);
        expect(cubit.state, const BuscarInicial());
        cubit.close();
      });
    });

    test('the query is trimmed before it is sent', () {
      fakeAsync((reloj) {
        final repo = RepoLugarFalso(alBuscar: (_) => resultado([_kennedy]));
        final cubit = BuscarLugarCubit(repo);

        cubit.alCambiarTexto('  Par ');
        reloj.elapse(_espera);

        expect(repo.pedidos.single.q, 'Par');
        cubit.close();
      });
    });

    test('deleting back below 2 chars cancels the pending call', () {
      fakeAsync((reloj) {
        final repo = RepoLugarFalso(alBuscar: (_) => resultado([_kennedy]));
        final cubit = BuscarLugarCubit(repo);

        cubit.alCambiarTexto('Par');
        reloj.elapse(const Duration(milliseconds: 200));
        cubit.alCambiarTexto('P');
        reloj.elapse(const Duration(seconds: 1));

        expect(repo.pedidos, isEmpty);
        cubit.close();
      });
    });

    test('closing the cubit cancels a pending call', () {
      fakeAsync((reloj) {
        final repo = RepoLugarFalso(alBuscar: (_) => resultado([_kennedy]));
        final cubit = BuscarLugarCubit(repo);

        cubit.alCambiarTexto('Par');
        cubit.close();
        reloj.elapse(const Duration(seconds: 1));

        expect(repo.pedidos, isEmpty);
      });
    });
  });

  group('results', () {
    test('goes Buscando then Resultados with the places and the query', () {
      fakeAsync((reloj) {
        final cubit = BuscarLugarCubit(
          RepoLugarFalso(alBuscar: (_) => resultado([_kennedy, _exposicion])),
        );
        final estados = <BuscarLugarState>[];
        cubit.stream.listen(estados.add);

        cubit.alCambiarTexto('Parque');
        reloj.elapse(_espera);
        reloj.flushMicrotasks();

        expect(estados, const [
          BuscarBuscando(),
          BuscarResultados([_kennedy, _exposicion], consulta: 'Parque'),
        ]);
        cubit.close();
      });
    });

    test('no match is SinResultados with the HU message for that query', () {
      fakeAsync((reloj) {
        final cubit = BuscarLugarCubit(
          RepoLugarFalso(alBuscar: (_) => resultado([])),
        );

        cubit.alCambiarTexto('Zoológico');
        reloj.elapse(_espera);
        reloj.flushMicrotasks();

        expect(cubit.state, const BuscarSinResultados('Zoológico'));
        expect(
          (cubit.state as BuscarSinResultados).mensaje,
          'No encontramos lugares para “Zoológico”. Prueba con otro nombre.',
        );
        cubit.close();
      });
    });

    test(
      'a failure is Error with code and offline flag, and retry searches again',
      () {
        fakeAsync((reloj) {
          var falla = true;
          final repo = RepoLugarFalso(
            alBuscar: (_) async {
              if (falla) throw const ApiException.sinConexion();
              return ResultadoLista(mensaje: '', items: [_kennedy]);
            },
          );
          final cubit = BuscarLugarCubit(repo);

          cubit.alCambiarTexto('Par');
          reloj.elapse(_espera);
          reloj.flushMicrotasks();
          expect(
            cubit.state,
            const BuscarError(
              BuscarLugarCubit.mensajeError,
              consulta: 'Par',
              esSinConexion: true,
            ),
          );

          falla = false;
          cubit.reintentar();
          reloj.flushMicrotasks();

          expect(repo.pedidos.map((p) => p.q), ['Par', 'Par']);
          expect(
            cubit.state,
            const BuscarResultados([_kennedy], consulta: 'Par'),
          );
          cubit.close();
        });
      },
    );

    test('retry without a previous query does nothing', () {
      fakeAsync((reloj) {
        final repo = RepoLugarFalso();
        final cubit = BuscarLugarCubit(repo);

        cubit.reintentar();
        reloj.flushMicrotasks();

        expect(repo.pedidos, isEmpty);
        cubit.close();
      });
    });
  });

  group('stale responses', () {
    test('an older answer arriving after a newer search is discarded', () {
      fakeAsync((reloj) {
        final lenta = Completer<ResultadoLista<LugarResumen>>();
        final repo = RepoLugarFalso(
          alBuscar: (p) =>
              p.q == 'Par' ? lenta.future : resultado([_exposicion]),
        );
        final cubit = BuscarLugarCubit(repo);

        cubit.alCambiarTexto('Par');
        reloj.elapse(_espera);
        cubit.alCambiarTexto('Parq');
        reloj.elapse(_espera);
        reloj.flushMicrotasks();
        lenta.complete(ResultadoLista(mensaje: '', items: [_kennedy]));
        reloj.flushMicrotasks();

        expect(
          cubit.state,
          const BuscarResultados([_exposicion], consulta: 'Parq'),
        );
        cubit.close();
      });
    });

    test(
      'an answer arriving after the text dropped below 2 chars is discarded',
      () {
        fakeAsync((reloj) {
          final lenta = Completer<ResultadoLista<LugarResumen>>();
          final cubit = BuscarLugarCubit(
            RepoLugarFalso(alBuscar: (_) => lenta.future),
          );

          cubit.alCambiarTexto('Par');
          reloj.elapse(_espera);
          cubit.alCambiarTexto('P');
          lenta.complete(ResultadoLista(mensaje: '', items: [_kennedy]));
          reloj.flushMicrotasks();

          expect(cubit.state, const BuscarInicial());
          cubit.close();
        });
      },
    );
  });
}

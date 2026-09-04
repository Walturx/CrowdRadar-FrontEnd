import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:crowdradar/core/models/user_model.dart';
import 'package:crowdradar/core/network/api_exception.dart';
import 'package:crowdradar/features/perfil/data/perfil_repository.dart';
import 'package:crowdradar/features/perfil/editar/editar_perfil_cubit.dart';
import 'package:crowdradar/features/perfil/editar/editar_perfil_state.dart';
import 'package:crowdradar/features/perfil/ver/perfil_cubit.dart';
import 'package:crowdradar/features/perfil/ver/perfil_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _PerfilRepoMock extends Mock implements PerfilRepository {}

const _user = UserModel(id: 1, nombre: 'Ana');
const _editado = UserModel(id: 1, nombre: 'Beatriz');

void main() {
  late _PerfilRepoMock repo;
  setUp(() => repo = _PerfilRepoMock());

  group('PerfilCubit', () {
    test('starts in Cargando', () {
      expect(PerfilCubit(repo).state, const PerfilCargando());
    });

    blocTest<PerfilCubit, PerfilState>(
      'S8.4 cargar success -> Cargando, Cargado(usuario)',
      build: () {
        when(() => repo.obtener()).thenAnswer((_) async => _user);
        return PerfilCubit(repo);
      },
      act: (c) => c.cargar(),
      expect: () => [const PerfilCargando(), const PerfilCargado(_user)],
    );

    blocTest<PerfilCubit, PerfilState>(
      'no session -> Error("No hay sesión activa")',
      build: () {
        when(() => repo.obtener()).thenThrow(
            const ApiException(status: 401, message: 'No hay sesión activa'));
        return PerfilCubit(repo);
      },
      act: (c) => c.cargar(),
      expect: () =>
          [const PerfilCargando(), const PerfilError('No hay sesión activa')],
    );

    blocTest<PerfilCubit, PerfilState>(
      'S8.5 network failure -> Error(sinConexion)',
      build: () {
        when(() => repo.obtener()).thenThrow(const ApiException.sinConexion());
        return PerfilCubit(repo);
      },
      act: (c) => c.cargar(),
      expect: () => [
        const PerfilCargando(),
        const PerfilError('No se pudo conectar con el servidor',
            esSinConexion: true),
      ],
    );

    blocTest<PerfilCubit, PerfilState>(
      'R4-101 unexpected error -> generic message',
      build: () {
        when(() => repo.obtener()).thenThrow(StateError('boom'));
        return PerfilCubit(repo);
      },
      act: (c) => c.cargar(),
      expect: () =>
          [
            const PerfilCargando(),
            const PerfilError('Ocurrió un error inesperado'),
          ],
    );
  });

  blocTest<EditarPerfilCubit, EditarPerfilState>(
    'R4-101 sinConexion and codigo are exposed',
    build: () {
      when(() => repo.actualizar(any())).thenThrow(
          const ApiException(status: 0, message: 'x', code: 'C1'));
      return EditarPerfilCubit(repo);
    },
    act: (c) => c.guardar({}),
    verify: (c) {
      final e = c.state as EditarPerfilFallido;
      expect(e.codigo, 'C1');
      expect(e.esSinConexion, isTrue);
    },
  );

  group('EditarPerfilCubit', () {
    test('starts in Editando', () {
      expect(EditarPerfilCubit(repo).state, const EditarPerfilEditando());
    });

    blocTest<EditarPerfilCubit, EditarPerfilState>(
      'S8.4 guardar success -> Guardando, Guardado(usuario)',
      build: () {
        when(() => repo.actualizar({'nombre': 'Beatriz'}))
            .thenAnswer((_) async => _editado);
        return EditarPerfilCubit(repo);
      },
      act: (c) => c.guardar({'nombre': 'Beatriz'}),
      expect: () =>
          [const EditarPerfilGuardando(), const EditarPerfilGuardado(_editado)],
    );

    blocTest<EditarPerfilCubit, EditarPerfilState>(
      'guardar failure -> Fallido(message)',
      build: () {
        when(() => repo.actualizar(any())).thenThrow(const ApiException(
            status: 500, message: 'Error al actualizar el perfil'));
        return EditarPerfilCubit(repo);
      },
      act: (c) => c.guardar({'nombre': 'x'}),
      expect: () => [
        const EditarPerfilGuardando(),
        const EditarPerfilFallido('Error al actualizar el perfil'),
      ],
    );

    blocTest<EditarPerfilCubit, EditarPerfilState>(
      'R4-101 unexpected error -> generic message',
      build: () {
        when(() => repo.actualizar(any())).thenThrow(StateError('boom'));
        return EditarPerfilCubit(repo);
      },
      act: (c) => c.guardar({'nombre': 'x'}),
      expect: () => [
        const EditarPerfilGuardando(),
        const EditarPerfilFallido('Ocurrió un error inesperado'),
      ],
    );
  });

  group('R3-109 a second submit while a request is in flight is ignored', () {
    test('PerfilCubit.cargar sends one request for a double call', () async {
      final pendiente = Completer<UserModel>();
      when(() => repo.obtener()).thenAnswer((_) => pendiente.future);
      final cubit = PerfilCubit(repo);

      final primero = cubit.cargar();
      final segundo = cubit.cargar();
      pendiente.complete(_user);
      await Future.wait([primero, segundo]);

      verify(() => repo.obtener()).called(1);
      expect(cubit.state, const PerfilCargado(_user));
    });

    test('PerfilCubit.cargar can retry after an error', () async {
      when(() => repo.obtener()).thenThrow(const ApiException.sinConexion());
      final cubit = PerfilCubit(repo);

      await cubit.cargar();
      await cubit.cargar();

      verify(() => repo.obtener()).called(2);
    });

    test('EditarPerfilCubit.guardar sends one request for a double tap',
        () async {
      final pendiente = Completer<UserModel>();
      when(() => repo.actualizar(any())).thenAnswer((_) => pendiente.future);
      final cubit = EditarPerfilCubit(repo);

      final primero = cubit.guardar({'nombre': 'x'});
      final segundo = cubit.guardar({'nombre': 'x'});
      pendiente.complete(_editado);
      await Future.wait([primero, segundo]);

      verify(() => repo.actualizar(any())).called(1);
    });
  });
}

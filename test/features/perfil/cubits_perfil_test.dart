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
        const PerfilError('No se pudo conectar con el servidor'),
      ],
    );

    blocTest<PerfilCubit, PerfilState>(
      'unexpected error -> Error(e.toString())',
      build: () {
        when(() => repo.obtener()).thenThrow(StateError('boom'));
        return PerfilCubit(repo);
      },
      act: (c) => c.cargar(),
      expect: () =>
          [const PerfilCargando(), PerfilError(StateError('boom').toString())],
    );
  });

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
      'unexpected error -> Fallido(e.toString())',
      build: () {
        when(() => repo.actualizar(any())).thenThrow(StateError('boom'));
        return EditarPerfilCubit(repo);
      },
      act: (c) => c.guardar({'nombre': 'x'}),
      expect: () => [
        const EditarPerfilGuardando(),
        EditarPerfilFallido(StateError('boom').toString()),
      ],
    );
  });
}

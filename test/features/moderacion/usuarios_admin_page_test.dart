import 'package:crowdradar/app/fakes/comportamiento_fake.dart';
import 'package:crowdradar/app/fakes/moderacion_repository_fake.dart';
import 'package:crowdradar/core/models/moderacion.dart';
import 'package:crowdradar/core/network/api_exception.dart';
import 'package:crowdradar/core/network/respuesta_api.dart';
import 'package:crowdradar/core/widgets/lista_perezosa.dart';
import 'package:crowdradar/features/moderacion/data/moderacion_repository.dart';
import 'package:crowdradar/features/moderacion/usuarios/usuarios_admin_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  String? abierto;

  Future<void> abrir(WidgetTester tester, ModeracionRepository repo) async {
    abierto = null;
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      RepositoryProvider<ModeracionRepository>.value(
        value: repo,
        child: MaterialApp.router(
          routerConfig: GoRouter(
            routes: [
              GoRoute(path: '/', builder: (_, _) => const UsuariosAdminPage()),
              GoRoute(
                path: '/admin/usuarios/:id',
                builder: (_, s) {
                  abierto = s.pathParameters['id'];
                  return const Scaffold(body: Text('detalle'));
                },
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets('HU 7.2 c1 lists users with their account status', (
    tester,
  ) async {
    await abrir(tester, ModeracionRepositoryFake());

    expect(find.text('Usuarios registrados'), findsOneWidget);
    expect(find.text('Buscar por nombre o correo'), findsOneWidget);
    expect(find.text('5 USUARIOS'), findsOneWidget);
    expect(find.text('Carlos Méndez'), findsOneWidget);
    expect(find.text('carlos.mendez@correo.pe'), findsOneWidget);
    expect(find.text('Activo'), findsWidgets);
    expect(find.text('Suspendido'), findsWidgets);
  });

  testWidgets('HU 7.4 c1 suspended rows say how many days are left', (
    tester,
  ) async {
    await abrir(tester, ModeracionRepositoryFake());

    expect(find.text('Suspendido · faltan 5 días'), findsOneWidget);
    expect(find.text('Suspendido · faltan 2 días'), findsOneWidget);
  });

  testWidgets('HU 7.4 c1 the Suspendidos chip shows only suspended accounts', (
    tester,
  ) async {
    await abrir(tester, ModeracionRepositoryFake());

    await tester.tap(find.text('Suspendidos'));
    await tester.pump();
    await tester.pump();

    expect(find.text('2 CUENTAS SUSPENDIDAS'), findsOneWidget);
    expect(find.text('Lucía Paredes'), findsOneWidget);
    expect(find.text('Carlos Méndez'), findsNothing);
  });

  testWidgets('HU 7.2 c2 searching shows only the matches', (tester) async {
    await abrir(tester, ModeracionRepositoryFake());

    await tester.enterText(find.byType(TextField), 'lucía');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    expect(find.text('1 COINCIDENCIAS'), findsOneWidget);
    expect(find.text('Lucía Paredes'), findsOneWidget);
    expect(find.text('Carlos Méndez'), findsNothing);
  });

  testWidgets('a search without matches shows the empty state', (tester) async {
    await abrir(tester, ModeracionRepositoryFake());

    await tester.enterText(find.byType(TextField), 'zzzz');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    expect(find.text('Sin resultados'), findsOneWidget);
  });

  testWidgets('tapping a user opens its detail', (tester) async {
    await abrir(tester, ModeracionRepositoryFake());

    await tester.tap(find.text('Carlos Méndez'));
    await tester.pumpAndSettle();

    expect(abierto, '11');
    expect(find.text('detalle'), findsOneWidget);
  });

  testWidgets('an offline load shows the error with a retry', (tester) async {
    await abrir(
      tester,
      ModeracionRepositoryFake(
        comportamiento: const ComportamientoFake(
          fallo: ApiException.sinConexion(),
        ),
      ),
    );

    expect(find.text(ApiException.mensajeSinConexion), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
  });

  testWidgets('R3-009 Cargar más at the end of the list appends a page', (
    tester,
  ) async {
    final repo = _UsuariosPaginados(25);
    await abrir(tester, repo);
    final lista = find.descendant(
      of: find.byType(ListaPerezosa),
      matching: find.byType(Scrollable),
    );
    expect(find.text('25 USUARIOS'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Cargar más'),
      300,
      scrollable: lista,
    );
    await tester.tap(find.text('Cargar más'));
    await tester.pump();
    await tester.pump();
    await tester.scrollUntilVisible(
      find.text('Usuario 25'),
      300,
      scrollable: lista,
    );

    expect(repo.llamadas, 2);
    expect(find.text('Usuario 25'), findsOneWidget);
    expect(find.text('Cargar más'), findsNothing);
  });
}

/// Serves [total] generated users in pages, counting the calls.
class _UsuariosPaginados extends ModeracionRepositoryFake {
  final int total;
  int llamadas = 0;

  _UsuariosPaginados(this.total);

  @override
  Future<Pagina<UsuarioAdmin>> usuarios({
    String? q,
    EstadoCuenta? status,
    OrdenUsuarios? orden,
    int page = 1,
    int size = 20,
  }) async {
    llamadas++;
    return Pagina(
      items: [
        for (var i = (page - 1) * size + 1; i <= total && i <= page * size; i++)
          UsuarioAdmin(
            id: i,
            nombre: 'Usuario',
            apellido: '$i',
            email: 'u$i@correo.pe',
          ),
      ],
      page: page,
      size: size,
      total: total,
      totalPaginas: (total + size - 1) ~/ size,
    );
  }
}

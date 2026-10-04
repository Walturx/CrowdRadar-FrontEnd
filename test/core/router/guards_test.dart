import 'package:crowdradar/app/app.dart';
import 'package:crowdradar/app/guards.dart';
import 'package:crowdradar/app/dependencias.dart';
import 'package:crowdradar/app/rutas.dart';
import 'package:crowdradar/core/config/entorno.dart';
import 'package:crowdradar/core/session/motivo_cierre.dart';
import 'package:crowdradar/core/session/sesion_state.dart';
import 'package:crowdradar/core/session/session_service.dart';
import 'package:crowdradar/core/storage/memoria_token_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/jwt_falso.dart';

const _usuario = SesionAutenticada(usuario: usuarioPrueba, esAdmin: false);
const _admin = SesionAutenticada(usuario: adminPrueba, esAdmin: true);
const _anonimo = SesionNoAutenticada();

void main() {
  group('redirigirPorSesion', () {
    test('S5.1 unauthenticated on a protected route goes to /login', () {
      expect(redirigirPorSesion(_anonimo, '/mapa'), Rutas.login);
      expect(redirigirPorSesion(_anonimo, '/perfil/editar'), Rutas.login);
      expect(redirigirPorSesion(_anonimo, '/admin/usuarios'), Rutas.login);
    });

    test('S5.1 public routes stay reachable while unauthenticated', () {
      for (final ruta in [Rutas.login, Rutas.registro, Rutas.recuperar]) {
        expect(redirigirPorSesion(_anonimo, ruta), isNull);
      }
    });

    test('S5.2 authenticated USUARIO on a public route goes to /mapa', () {
      expect(redirigirPorSesion(_usuario, Rutas.login), Rutas.mapa);
      expect(redirigirPorSesion(_usuario, Rutas.registro), Rutas.mapa);
    });

    test('S5.2 authenticated ADMIN on a public route goes to /admin/reportes',
        () {
      expect(redirigirPorSesion(_admin, Rutas.login), Rutas.adminReportes);
    });

    test('S5.3 USUARIO on /admin/* goes to /mapa', () {
      expect(redirigirPorSesion(_usuario, '/admin/reportes'), Rutas.mapa);
      expect(redirigirPorSesion(_usuario, '/admin/usuarios/4'), Rutas.mapa);
    });

    test('R3-005 public routes match exactly, ignoring a trailing slash', () {
      expect(redirigirPorSesion(_anonimo, '/login/'), isNull);
      expect(redirigirPorSesion(_anonimo, '/loginx'), Rutas.login);
      expect(redirigirPorSesion(_usuario, '/login/'), Rutas.mapa);
    });

    test('R3-005 admin check respects the segment boundary', () {
      expect(redirigirPorSesion(_usuario, '/administrador'), isNull);
      expect(redirigirPorSesion(_usuario, '/admin'), Rutas.mapa);
      expect(redirigirPorSesion(_usuario, '/admin/'), Rutas.mapa);
      expect(redirigirPorSesion(_usuario, '/admin/reportes'), Rutas.mapa);
      expect(redirigirPorSesion(_admin, '/admin/reportes'), isNull);
    });

    test('authorized access is left untouched', () {
      expect(redirigirPorSesion(_usuario, '/favoritos'), isNull);
      expect(redirigirPorSesion(_admin, '/admin/usuarios/4'), isNull);
    });
  });

  group('router wired to the session', () {
    late SessionService sesion;

    setUp(() {
      sesion = SessionService.instance..reiniciar();
      sesion.configurar(MemoriaTokenStorage());
    });

    tearDown(() => sesion.reiniciar());

    Widget app(String inicial) => CrowdRadarApp(
          dependencias: Dependencias.crear(const Entorno(usarFakes: true), sesion),
          ubicacionInicial: inicial,
        );

    testWidgets('S5.1 opening a protected route unauthenticated shows login',
        (tester) async {
      await tester.pumpWidget(app(Rutas.favoritos));
      await tester.pumpAndSettle();

      expect(find.text('Iniciar sesión'), findsWidgets);
      expect(find.text('Sin favoritos aún'), findsNothing);
    });

    testWidgets('authenticated user reaches the protected route',
        (tester) async {
      await sesion.iniciar('t', usuarioPrueba);
      await tester.pumpWidget(app(Rutas.favoritos));
      await tester.pumpAndSettle();

      expect(find.text('Sin favoritos aún'), findsOneWidget);
      expect(find.text('Favoritos'), findsWidgets);
    });

    testWidgets('S5.4 session expiry on a shell route redirects to /login',
        (tester) async {
      await sesion.iniciar('t', usuarioPrueba);
      await tester.pumpWidget(app(Rutas.favoritos));
      await tester.pumpAndSettle();

      await tester.runAsync(() => sesion.expirar(MotivoCierre.sesionExpirada));
      await tester.pumpAndSettle();

      expect(find.text('Iniciar sesión'), findsWidgets);
      expect(find.text('Sin favoritos aún'), findsNothing);
    });
  });
}

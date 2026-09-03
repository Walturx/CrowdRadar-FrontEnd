import 'package:go_router/go_router.dart';

import '../core/models/user_model.dart';

import '../features/auth/login/login_page.dart';
import '../features/auth/registro/register_page.dart';
import '../features/lugares/mapa/map_page.dart';
import '../features/validacion/pendientes/validar_page.dart';
import '../features/favoritos/lista/favoritos_page.dart';
import '../features/perfil/ver/profile_page.dart';
import '../features/perfil/editar/edit_profile_page.dart';

final appRouter = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterPage(),
    ),
    GoRoute(
      path: '/map',
      builder: (context, state) => const MapPage(),
    ),
    GoRoute(
      path: '/validar',
      builder: (context, state) => const ValidarPage(),
    ),
    GoRoute(
      path: '/favoritos',
      builder: (context, state) => const FavoritosPage(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfilePage(),
    ),
    GoRoute(
      path: '/profile/edit',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return EditProfilePage(
          user: extra != null ? UserModel.fromJson(extra) : null,
        );
      },
    ),
  ],
);

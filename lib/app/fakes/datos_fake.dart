import '../../core/models/categoria_lugar.dart';
import '../../core/models/lugar_resumen.dart';
import '../../core/models/nivel_saturacion.dart';
import '../../core/models/usuario.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/respuesta_api.dart';

/// Credentials accepted by the fakes.
const String emailFake = 'ana@test.com';
const String passwordFake = 'Secreta1';

const Usuario usuarioFake = Usuario(
  id: 1,
  nombre: 'Ana',
  apellido: 'Paz',
  email: emailFake,
  rol: 'USUARIO',
  distrito: 'Miraflores',
  status: 'ACTIVO',
);

const List<LugarResumen> lugaresFake = [
  LugarResumen(
    id: 1,
    nombre: 'Parque Kennedy',
    categoria: CategoriaLugar.parque,
    latitud: -12.1219,
    longitud: -77.0297,
    saturacion: NivelSaturacion.tranquilo,
  ),
  LugarResumen(
    id: 2,
    nombre: 'Mercado de Surquillo',
    categoria: CategoriaLugar.mercado,
    latitud: -12.1114,
    longitud: -77.0156,
    saturacion: NivelSaturacion.saturado,
  ),
  LugarResumen(
    id: 3,
    nombre: 'Playa Costa Verde',
    categoria: CategoriaLugar.playa,
    latitud: -12.1500,
    longitud: -77.0300,
    saturacion: NivelSaturacion.moderado,
  ),
];

ApiException errorFake(int status, String code, String message) =>
    ApiException(status: status, message: message, code: code);

/// 1-based page of [todos] in the API's paginated envelope.
///
/// Like the API, `page <= 0` or `size <= 0` is a 400; a page past the end is empty.
Pagina<T> paginar<T>(List<T> todos, int page, int size) {
  if (page <= 0 || size <= 0) {
    throw errorFake(
      400,
      'PAGINACION_INVALIDA',
      'page y size deben ser mayores que cero',
    );
  }
  final desde = (page - 1) * size;
  return Pagina(
    items: todos.skip(desde).take(size).toList(),
    page: page,
    size: size,
    total: todos.length,
    totalPaginas: (todos.length / size).ceil(),
  );
}

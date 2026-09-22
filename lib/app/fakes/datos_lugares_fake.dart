import '../../core/models/categoria_lugar.dart';
import '../../core/models/lugar_resumen.dart';
import '../../core/models/nivel_saturacion.dart';

/// Seed place of the in-memory fake; the 45 entries mirror the backend seed
/// (Lima, 6 categories). Saturation freshness and report counts are derived
/// from the id so every run is deterministic.
class LugarFake {
  static const _t = NivelSaturacion.tranquilo;
  static const _m = NivelSaturacion.moderado;
  static const _s = NivelSaturacion.saturado;
  static const _n = NivelSaturacion.sinInformacion;

  final int id;
  final String nombre;
  final CategoriaLugar categoria;
  final double latitud;
  final double longitud;
  final String direccion;
  final NivelSaturacion nivel;
  final String? horario;

  const LugarFake(
    this.id,
    this.nombre,
    this.categoria,
    this.latitud,
    this.longitud,
    this.direccion,
    this.nivel, [
    this.horario,
  ]);

  /// Minutes since the last report that set [nivel] (always inside the 60 min window).
  int get minutosDesdeActualizacion => 3 + (id * 7) % 50;

  int get reportesRecientes => nivel == _n ? 0 : 3 + id % 15;

  LugarResumen get resumen => LugarResumen(
    id: id,
    nombre: nombre,
    categoria: categoria,
    latitud: latitud,
    longitud: longitud,
    saturacion: nivel,
  );
}

const _p = CategoriaLugar.parque;
const _c = CategoriaLugar.centroComercial;
const _k = CategoriaLugar.mercado;
const _x = CategoriaLugar.transporte;
const _z = CategoriaLugar.plaza;
const _y = CategoriaLugar.playa;
const _t = LugarFake._t;
const _m = LugarFake._m;
const _s = LugarFake._s;
const _n = LugarFake._n;

const List<LugarFake> datosLugaresFake = [
  LugarFake(1, 'Parque Kennedy', _p, -12.1219, -77.0297, 'Av. Larco 345, Miraflores', _t),
  LugarFake(2, 'Mercado de Surquillo', _k, -12.1114, -77.0156, 'Av. Angamos Este 1000, Surquillo', _s, '06:00-18:00'),
  LugarFake(3, 'Playa Costa Verde', _y, -12.1500, -77.0300, 'Circuito de Playas, Barranco', _m),
  LugarFake(4, 'Parque de la Exposición', _p, -12.0690, -77.0360, 'Av. 28 de Julio, Cercado de Lima', _m, '06:00-22:00'),
  LugarFake(5, 'Parque El Olivar', _p, -12.0990, -77.0345, 'Calle La Rosa, San Isidro', _t, '06:00-20:00'),
  LugarFake(6, 'Parque de la Reserva', _p, -12.0700, -77.0335, 'Av. Petit Thouars, Cercado de Lima', _s, '17:00-23:00'),
  LugarFake(7, 'Parque del Amor', _p, -12.1262, -77.0338, 'Malecón Cisneros, Miraflores', _s),
  LugarFake(8, 'Parque Reducto', _p, -12.1275, -77.0350, 'Av. Benavides, Miraflores', _n),
  LugarFake(9, 'Parque Salazar', _p, -12.1318, -77.0308, 'Malecón de la Reserva, Miraflores', _m),
  LugarFake(10, 'Parque de las Leyendas', _p, -12.0702, -77.0916, 'Av. La Marina, San Miguel', _m, '09:00-17:00'),
  LugarFake(11, 'Parque Ricardo Palma', _p, -12.1180, -77.0268, 'Av. Ricardo Palma, Miraflores', _t),
  LugarFake(12, 'Mercado Central', _k, -12.0455, -77.0235, 'Jr. Ucayali, Cercado de Lima', _s, '06:00-19:00'),
  LugarFake(13, 'Mercado de Magdalena', _k, -12.0905, -77.0725, 'Av. Brasil, Magdalena del Mar', _m, '06:00-17:00'),
  LugarFake(14, 'Mercado de Barranco', _k, -12.1495, -77.0210, 'Av. Grau, Barranco', _t, '06:00-16:00'),
  LugarFake(15, 'Mercado de Lince', _k, -12.0840, -77.0345, 'Av. Arequipa, Lince', _n),
  LugarFake(16, 'Mercado de San Isidro', _k, -12.0985, -77.0470, 'Calle Juan de Arona, San Isidro', _t, '06:00-17:00'),
  LugarFake(17, 'Mercado de Jesús María', _k, -12.0702, -77.0510, 'Av. Brasil, Jesús María', _m, '06:00-17:00'),
  LugarFake(18, 'Playa Waikiki', _y, -12.1370, -77.0420, 'Costa Verde, Miraflores', _m),
  LugarFake(19, 'Playa Los Yuyos', _y, -12.1475, -77.0270, 'Costa Verde, Barranco', _t),
  LugarFake(20, 'Playa Agua Dulce', _y, -12.1658, -77.0225, 'Costa Verde, Chorrillos', _s),
  LugarFake(21, 'Playa La Herradura', _y, -12.1840, -77.0275, 'Costa Verde, Chorrillos', _n),
  LugarFake(22, 'Playa Makaha', _y, -12.1330, -77.0415, 'Costa Verde, Miraflores', _t),
  LugarFake(23, 'Larcomar', _c, -12.1318, -77.0300, 'Malecón de la Reserva 610, Miraflores', _s, '10:00-22:00'),
  LugarFake(24, 'Jockey Plaza', _c, -12.0845, -76.9750, 'Av. Javier Prado Este 4200, Santiago de Surco', _m, '10:00-22:00'),
  LugarFake(25, 'Real Plaza Salaverry', _c, -12.0890, -77.0535, 'Av. Felipe Salaverry 2370, Jesús María', _t, '10:00-22:00'),
  LugarFake(26, 'Plaza San Miguel', _c, -12.0777, -77.0825, 'Av. La Marina 2000, San Miguel', _m, '10:00-22:00'),
  LugarFake(27, 'Plaza Norte', _c, -12.0060, -77.0580, 'Av. Alfredo Mendiola 1400, Independencia', _s, '10:00-22:00'),
  LugarFake(28, 'Caminos del Inca', _c, -12.1090, -76.9955, 'Av. El Derby, Santiago de Surco', _t, '10:00-22:00'),
  LugarFake(29, 'Real Plaza Centro Cívico', _c, -12.0560, -77.0370, 'Av. Garcilaso de la Vega, Cercado de Lima', _n, '10:00-22:00'),
  LugarFake(30, 'La Rambla San Borja', _c, -12.0910, -77.0010, 'Av. Javier Prado Este, San Borja', _m, '10:00-22:00'),
  LugarFake(31, 'Estación Central', _x, -12.0560, -77.0357, 'Av. Alfonso Ugarte, Cercado de Lima', _s, '05:00-23:00'),
  LugarFake(32, 'Estación Javier Prado', _x, -12.0910, -77.0300, 'Av. Paseo de la República, San Isidro', _m, '05:00-23:00'),
  LugarFake(33, 'Estación Benavides', _x, -12.1280, -77.0235, 'Av. Paseo de la República, Miraflores', _t, '05:00-23:00'),
  LugarFake(34, 'Estación Plaza de Flores', _x, -12.1470, -77.0230, 'Av. Paseo de la República, Barranco', _n, '05:00-23:00'),
  LugarFake(35, 'Estación Villa El Salvador', _x, -12.2060, -76.9370, 'Av. Pachacútec, Villa El Salvador', _t, '05:00-23:00'),
  LugarFake(36, 'Estación Gamarra', _x, -12.0675, -77.0105, 'Av. Aviación, La Victoria', _s, '05:00-23:00'),
  LugarFake(37, 'Aeropuerto Jorge Chávez', _x, -12.0219, -77.1143, 'Av. Elmer Faucett, Callao', _m),
  LugarFake(38, 'Plaza de Armas de Lima', _z, -12.0464, -77.0300, 'Jr. de la Unión, Cercado de Lima', _s),
  LugarFake(39, 'Plaza San Martín', _z, -12.0518, -77.0350, 'Jr. de la Unión, Cercado de Lima', _m),
  LugarFake(40, 'Plaza Dos de Mayo', _z, -12.0555, -77.0430, 'Av. Nicolás de Piérola, Cercado de Lima', _t),
  LugarFake(41, 'Plaza Bolognesi', _z, -12.0525, -77.0455, 'Av. Alfonso Ugarte, Cercado de Lima', _n),
  LugarFake(42, 'Plaza Francia', _z, -12.0572, -77.0400, 'Av. Wilson, Cercado de Lima', _t),
  LugarFake(43, 'Plaza de Barranco', _z, -12.1482, -77.0214, 'Av. Grau, Barranco', _m),
  LugarFake(44, 'Plaza Manco Cápac', _z, -12.0630, -77.0140, 'Av. Aviación, La Victoria', _n),
  LugarFake(45, 'Plaza de Armas de Chorrillos', _z, -12.1690, -77.0185, 'Jr. Zepita, Chorrillos', _t),
];

/// Resumen view of [datosLugaresFake], used by fakes that only need ids and names.
final List<LugarResumen> lugaresFake = [
  for (final l in datosLugaresFake) l.resumen,
];

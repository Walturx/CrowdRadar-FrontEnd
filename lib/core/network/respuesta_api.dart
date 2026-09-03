/// Successful API envelope `{message, data}` with parsed data.
class RespuestaApi<T> {
  final String mensaje;
  final T datos;

  const RespuestaApi({required this.mensaje, required this.datos});
}

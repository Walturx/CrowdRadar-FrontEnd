import 'api_exception.dart';

/// Contract stub: every method fails with 501 until its stream implements it.
///
/// Mix into a `<X>RepositoryHttp implements <X>Repository` class and delete the
/// mixin once all methods have real bodies.
mixin RepositorioNoImplementado {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw const ApiException(
        status: 501,
        message: 'Funcionalidad no implementada',
        code: 'NO_IMPLEMENTADO',
      );
}

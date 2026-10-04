import 'package:crowdradar/core/network/cliente_http_factory.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  test('ClienteHttpFactory.crear returns a fresh http.Client each time', () {
    const fabrica = ClienteHttpFactory();
    final a = fabrica.crear();
    final b = fabrica.crear();

    expect(a, isA<http.Client>());
    expect(identical(a, b), isFalse);
    a.close();
    b.close();
  });
}

import 'package:consulta_placas/data/model/vehicle_type.dart';
import 'package:consulta_placas/data/repository/photo_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockDio extends Mock implements Dio {}

Response<dynamic> _response(dynamic data) {
  return Response(requestOptions: RequestOptions(path: ''), data: data, statusCode: 200);
}

Map<String, dynamic> _queryParamsOf(Invocation invocation) {
  return invocation.namedArguments[#queryParameters] as Map<String, dynamic>;
}

Response<dynamic> _searchResult(String? title) {
  return _response({
    'query': {
      'search': title == null ? [] : [{'title': title}],
    },
  });
}

Response<dynamic> _thumbnailResult(String? url) {
  return _response({
    'query': {
      'pages': {
        '1': url == null ? <String, dynamic>{} : <String, dynamic>{'thumbnail': {'source': url}},
      },
    },
  });
}

void main() {
  const ptUrl = 'https://pt.wikipedia.org/w/api.php';
  const enUrl = 'https://en.wikipedia.org/w/api.php';

  late MockDio dio;
  late PhotoRepository repository;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    dio = MockDio();
    repository = PhotoRepository(dio);
  });

  void stubHost(String host, {required String? title, required String? thumbnailUrl}) {
    when(() => dio.get(host, queryParameters: any(named: 'queryParameters'))).thenAnswer((invocation) async {
      final params = _queryParamsOf(invocation);
      if (params['list'] == 'search') return _searchResult(title);
      return _thumbnailResult(thumbnailUrl);
    });
  }

  test('returns the photo found on Portuguese Wikipedia', () async {
    stubHost(ptUrl, title: 'Fiat Pulse', thumbnailUrl: 'https://example.com/pulse.jpg');

    final photoUrl = await repository.searchPhoto('Fiat', 'PULSE DRIVE 1.3 8V Flex Mec. ', VehicleType.carros);

    expect(photoUrl, 'https://example.com/pulse.jpg');
  });

  test('uses only the base model name in the search query, ignoring trim details', () async {
    String? capturedQuery;
    when(() => dio.get(ptUrl, queryParameters: any(named: 'queryParameters'))).thenAnswer((invocation) async {
      final params = _queryParamsOf(invocation);
      if (params['list'] == 'search') {
        capturedQuery = params['srsearch'] as String;
        return _searchResult(null);
      }
      return _thumbnailResult(null);
    });
    stubHost(enUrl, title: null, thumbnailUrl: null);

    await repository.searchPhoto('Fiat', 'PULSE DRIVE 1.3 8V Flex Mec. ', VehicleType.carros);

    expect(capturedQuery, 'Fiat PULSE');
  });

  test('falls back to English Wikipedia when Portuguese has no thumbnail', () async {
    stubHost(ptUrl, title: 'Lista de automóveis da Honda', thumbnailUrl: null);
    stubHost(enUrl, title: 'List of Honda motorcycles', thumbnailUrl: 'https://example.com/honda-moto.jpg');

    final photoUrl = await repository.searchPhoto('HONDA', 'POP 110i', VehicleType.motos);

    expect(photoUrl, 'https://example.com/honda-moto.jpg');
  });

  test('adds a vehicle-type hint to disambiguate motorcycle searches', () async {
    String? capturedQuery;
    when(() => dio.get(ptUrl, queryParameters: any(named: 'queryParameters'))).thenAnswer((invocation) async {
      final params = _queryParamsOf(invocation);
      if (params['list'] == 'search') {
        capturedQuery = params['srsearch'] as String;
        return _searchResult('Honda Pop');
      }
      return _thumbnailResult('https://example.com/pop.jpg');
    });

    await repository.searchPhoto('HONDA', 'POP 110i', VehicleType.motos);

    expect(capturedQuery, contains('motocicleta'));
  });

  test('does not add a vehicle-type hint for cars', () async {
    String? capturedQuery;
    when(() => dio.get(ptUrl, queryParameters: any(named: 'queryParameters'))).thenAnswer((invocation) async {
      final params = _queryParamsOf(invocation);
      if (params['list'] == 'search') {
        capturedQuery = params['srsearch'] as String;
        return _searchResult('Volkswagen Gol');
      }
      return _thumbnailResult('https://example.com/gol.jpg');
    });

    await repository.searchPhoto('Volkswagen', 'Gol 1.6', VehicleType.carros);

    expect(capturedQuery, 'Volkswagen Gol');
  });

  test('returns null when no host has a matching photo', () async {
    stubHost(ptUrl, title: null, thumbnailUrl: null);
    stubHost(enUrl, title: null, thumbnailUrl: null);

    final photoUrl = await repository.searchPhoto('Marca', 'Inexistente', VehicleType.carros);

    expect(photoUrl, isNull);
  });

  test('returns the cached photo without hitting the network again', () async {
    stubHost(ptUrl, title: 'Fiat Pulse', thumbnailUrl: 'https://example.com/pulse.jpg');

    final first = await repository.searchPhoto('Fiat', 'PULSE DRIVE 1.3 8V Flex Mec. ', VehicleType.carros);
    clearInteractions(dio);
    final second = await repository.searchPhoto('Fiat', 'PULSE DRIVE 1.3 8V Flex Mec. ', VehicleType.carros);

    expect(second, first);
    verifyNever(() => dio.get(any(), queryParameters: any(named: 'queryParameters')));
  });

  test('returns null and does not throw when the request fails', () async {
    when(() => dio.get(any(), queryParameters: any(named: 'queryParameters')))
        .thenThrow(DioException(requestOptions: RequestOptions(path: '')));

    final photoUrl = await repository.searchPhoto('Fiat', 'Pulse', VehicleType.carros);

    expect(photoUrl, isNull);
  });
}

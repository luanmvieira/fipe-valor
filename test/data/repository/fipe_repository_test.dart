import 'package:consulta_placas/data/model/vehicle_type.dart';
import 'package:consulta_placas/data/repository/fipe_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

Response<dynamic> _response(dynamic data) {
  return Response(requestOptions: RequestOptions(path: ''), data: data, statusCode: 200);
}

void main() {
  late MockDio dio;
  late FipeRepository repository;

  const baseUrl = 'https://parallelum.com.br/fipe/api/v1';

  setUp(() {
    dio = MockDio();
    repository = FipeRepository(dio);
  });

  test('getBrands returns brands parsed from the marcas endpoint', () async {
    when(() => dio.get('$baseUrl/carros/marcas')).thenAnswer(
      (_) async => _response([
        {'codigo': '21', 'nome': 'Fiat'},
        {'codigo': '6', 'nome': 'Audi'},
      ]),
    );

    final brands = await repository.getBrands(VehicleType.carros);

    expect(brands, hasLength(2));
    expect(brands.first.code, '21');
    expect(brands.first.name, 'Fiat');
  });

  test('getModels returns models from the nested modelos list', () async {
    when(() => dio.get('$baseUrl/carros/marcas/21/modelos')).thenAnswer(
      (_) async => _response({
        'modelos': [
          {'codigo': 9648, 'nome': 'PULSE DRIVE 1.3 8V Flex Mec. '},
        ],
        'anos': [],
      }),
    );

    final models = await repository.getModels(VehicleType.carros, '21');

    expect(models, hasLength(1));
    expect(models.first.code, '9648');
    expect(models.first.name, 'PULSE DRIVE 1.3 8V Flex Mec. ');
  });

  test('getYears returns years from the anos endpoint', () async {
    when(() => dio.get('$baseUrl/carros/marcas/21/modelos/9648/anos')).thenAnswer(
      (_) async => _response([
        {'codigo': '2023-5', 'nome': '2023 Flex'},
      ]),
    );

    final years = await repository.getYears(VehicleType.carros, '21', '9648');

    expect(years, hasLength(1));
    expect(years.first.code, '2023-5');
    expect(years.first.name, '2023 Flex');
  });

  test('getValue parses the full FIPE value response', () async {
    when(() => dio.get('$baseUrl/carros/marcas/21/modelos/9648/anos/2023-5')).thenAnswer(
      (_) async => _response({
        'Valor': 'R\$ 85.206,00',
        'Marca': 'Fiat',
        'Modelo': 'PULSE DRIVE 1.3 8V Flex Mec. ',
        'AnoModelo': 2023,
        'Combustivel': 'Flex',
        'CodigoFipe': '001545-8',
        'MesReferencia': 'julho de 2026',
      }),
    );

    final value = await repository.getValue(VehicleType.carros, '21', '9648', '2023-5');

    expect(value.brand, 'Fiat');
    expect(value.model, 'PULSE DRIVE 1.3 8V Flex Mec. ');
    expect(value.modelYear, 2023);
    expect(value.fuel, 'Flex');
    expect(value.fipeCode, '001545-8');
    expect(value.price, 'R\$ 85.206,00');
  });

  test('getBrands uses the vehicle type path in the URL', () async {
    when(() => dio.get('$baseUrl/motos/marcas')).thenAnswer(
      (_) async => _response([
        {'codigo': '80', 'nome': 'HONDA'},
      ]),
    );

    final brands = await repository.getBrands(VehicleType.motos);

    expect(brands.single.name, 'HONDA');
    verify(() => dio.get('$baseUrl/motos/marcas')).called(1);
  });
}

import 'package:dio/dio.dart';

import '../model/fipe_option.dart';
import '../model/fipe_value.dart';
import '../model/vehicle_type.dart';

class FipeRepository {
  static const _baseUrl = 'https://parallelum.com.br/fipe/api/v1';

  final Dio _dio;

  FipeRepository(this._dio);

  Future<List<FipeOption>> getBrands(VehicleType type) async {
    final response = await _dio.get('$_baseUrl/${type.path}/marcas');
    return (response.data as List).map((e) => FipeOption.fromJson(e)).toList();
  }

  Future<List<FipeOption>> getModels(VehicleType type, String brandCode) async {
    final response = await _dio.get('$_baseUrl/${type.path}/marcas/$brandCode/modelos');
    final modelos = response.data['modelos'] as List;
    return modelos.map((e) => FipeOption.fromJson(e)).toList();
  }

  Future<List<FipeOption>> getYears(VehicleType type, String brandCode, String modelCode) async {
    final response = await _dio.get('$_baseUrl/${type.path}/marcas/$brandCode/modelos/$modelCode/anos');
    return (response.data as List).map((e) => FipeOption.fromJson(e)).toList();
  }

  Future<FipeValue> getValue(VehicleType type, String brandCode, String modelCode, String yearCode) async {
    final response = await _dio.get('$_baseUrl/${type.path}/marcas/$brandCode/modelos/$modelCode/anos/$yearCode');
    return FipeValue.fromJson(response.data as Map<String, dynamic>);
  }
}

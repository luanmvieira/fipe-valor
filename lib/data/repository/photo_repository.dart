import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/util/text_normalizer.dart';
import '../model/vehicle_type.dart';

class PhotoRepository {
  static const _hintsByHost = {
    'pt.wikipedia.org': {
      VehicleType.motos: 'motocicleta',
      VehicleType.caminhoes: 'caminhão',
    },
    'en.wikipedia.org': {
      VehicleType.motos: 'motorcycle',
      VehicleType.caminhoes: 'truck',
    },
  };

  final Dio _dio;

  PhotoRepository(this._dio);

  Future<String?> searchPhoto(String brand, String model, VehicleType vehicleType) async {
    final baseModel = _baseModelName(model);
    final cacheKey = 'photo_${normalizeText('$brand $baseModel ${vehicleType.path}').replaceAll(' ', '_')}';

    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(cacheKey);
    if (cached != null) return cached;

    for (final host in _hintsByHost.keys) {
      final hint = _hintsByHost[host]?[vehicleType];
      final query = hint == null ? '$brand $baseModel' : '$brand $baseModel $hint';

      final photoUrl = await _searchOnWikipedia(host, query);
      if (photoUrl != null) {
        await prefs.setString(cacheKey, photoUrl);
        return photoUrl;
      }
    }
    return null;
  }

  String _baseModelName(String model) => model.trim().split(RegExp(r'\s+')).first;

  Future<String?> _searchOnWikipedia(String host, String query) async {
    try {
      final title = await _searchTitle(host, query);
      if (title == null) return null;
      return await _fetchThumbnail(host, title);
    } on DioException {
      return null;
    }
  }

  Future<String?> _searchTitle(String host, String query) async {
    final response = await _dio.get('https://$host/w/api.php', queryParameters: {
      'action': 'query',
      'list': 'search',
      'srsearch': query,
      'format': 'json',
      'srlimit': 1,
    });

    final results = response.data['query']['search'] as List;
    if (results.isEmpty) return null;
    return results.first['title'] as String;
  }

  Future<String?> _fetchThumbnail(String host, String title) async {
    final response = await _dio.get('https://$host/w/api.php', queryParameters: {
      'action': 'query',
      'titles': title,
      'prop': 'pageimages',
      'format': 'json',
      'pithumbsize': 800,
    });

    final pages = response.data['query']['pages'] as Map<String, dynamic>;
    final page = pages.values.first as Map<String, dynamic>;
    final thumbnail = page['thumbnail'] as Map<String, dynamic>?;
    return thumbnail?['source'] as String?;
  }
}

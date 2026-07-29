import 'dart:convert';
import 'dart:typed_data';

import '../core/cache/memory_cache_store.dart';
import '../core/network/api_client.dart';

class DigitalIdCard {
  final Uint8List frontPng;
  final Uint8List backPng;
  final String mime;
  final String studentNumber;
  final String fullName;

  const DigitalIdCard({
    required this.frontPng,
    required this.backPng,
    required this.mime,
    required this.studentNumber,
    required this.fullName,
  });
}

class IdCardService {
  static final IdCardService _instance = IdCardService._internal();

  factory IdCardService() => _instance;

  IdCardService._internal();

  final ApiClient _apiClient = ApiClient();
  final MemoryCacheStore _cache = MemoryCacheStore.instance;

  Future<DigitalIdCard> getDigitalId({bool refresh = false}) async {
    return _cache.getOrFetch<DigitalIdCard>(
      'mobile:id-card',
      ttl: const Duration(minutes: 5),
      refresh: refresh,
      fetch: () async {
        final response = await _apiClient.get('/id-card');
        final data = _asMap(response['data']);

        final front = base64Decode(
          data['front_png_base64']?.toString() ?? '',
        );
        final back = base64Decode(
          data['back_png_base64']?.toString() ?? '',
        );

        if (front.isEmpty || back.isEmpty) {
          throw const FormatException('Digital ID images were empty.');
        }

        return DigitalIdCard(
          frontPng: front,
          backPng: back,
          mime: data['mime']?.toString() ?? 'image/png',
          studentNumber: data['student_number']?.toString() ?? '',
          fullName: data['full_name']?.toString() ?? '',
        );
      },
    );
  }

  void invalidateCache() {
    _cache.remove('mobile:id-card');
  }

  Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, value) => MapEntry(key.toString(), value));
    }
    return const {};
  }
}

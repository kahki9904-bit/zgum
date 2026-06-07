import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';
import '../../core/app_config.dart';
import '../models/cultural_event.dart';
import 'api_cultural_event_repository.dart' show CulturalEventApiException;
import 'cultural_event_repository.dart';

/// 소상공인시장진흥공단 상가(상권)정보 API — 반경 내 상가를 파트너 이벤트로 반환.
///
/// 엔드포인트: https://apis.data.go.kr/B553077/api/open/sdsc2/storeListInRadius
/// 반경 최대: 1,000m (API 제한)
class SdscStoreRepository implements CulturalEventRepository {
  final Dio _dio;

  SdscStoreRepository({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 15),
              responseType: ResponseType.plain,
            ));

  @override
  Future<List<CulturalEvent>> fetchNearbyEvents({
    required LatLng center,
    required double radiusKm,
    required bool isIdentityVerified,
  }) async {
    // API 반경 상한: 1,000m
    final radiusM = (radiusKm * 1000).round().clamp(100, 1000);

    final url = '${AppConfig.sdscApiBaseUrl}/storeListInRadius'
        '?serviceKey=${AppConfig.sdscApiKey}'
        '&radius=$radiusM'
        '&cx=${center.longitude}'
        '&cy=${center.latitude}'
        '&numOfRows=50'
        '&pageNo=1'
        '&type=json';

    try {
      final response = await _dio.get<String>(url);
      if (response.statusCode != 200) {
        throw CulturalEventApiException('SDSC HTTP ${response.statusCode}');
      }

      final body = response.data ?? '';
      if (body.trimLeft().startsWith('<')) {
        throw const CulturalEventApiException('SDSC API XML 오류 응답');
      }

      final json = jsonDecode(body) as Map<String, dynamic>;
      return _parse(json);
    } on CulturalEventApiException {
      rethrow;
    } on DioException catch (e) {
      throw CulturalEventApiException('SDSC 네트워크 오류: ${e.message ?? e.type.name}');
    } on FormatException catch (e) {
      throw CulturalEventApiException('SDSC 파싱 오류: $e');
    }
  }

  List<CulturalEvent> _parse(Map<String, dynamic> json) {
    final header = json['header'] as Map<String, dynamic>? ?? {};
    final resultCode = header['resultCode']?.toString() ?? '';
    if (resultCode.isNotEmpty && resultCode != '00') {
      throw CulturalEventApiException(
          'SDSC 오류: ${header['resultMsg'] ?? '알 수 없는 오류'} ($resultCode)');
    }

    final body = json['body'] as Map<String, dynamic>? ?? {};
    final items = body['items'];
    if (items == null) return [];

    final list = items is List
        ? items.cast<Map<String, dynamic>>()
        : (items is Map ? [items as Map<String, dynamic>] : <Map<String, dynamic>>[]);

    final now = DateTime.now();
    final todayClose = DateTime(now.year, now.month, now.day, 22, 0);
    final endDateTime = now.isAfter(todayClose)
        ? now.add(const Duration(hours: 2))
        : todayClose;

    final events = <CulturalEvent>[];
    for (final item in list) {
      final event = _toEvent(item, now, endDateTime);
      if (event != null) events.add(event);
    }
    return events;
  }

  CulturalEvent? _toEvent(
      Map<String, dynamic> item, DateTime now, DateTime endDateTime) {
    try {
      final lat = (item['lat'] as num?)?.toDouble();
      final lon = (item['lon'] as num?)?.toDouble();
      if (lat == null || lon == null || lat == 0.0 || lon == 0.0) return null;

      final name = item['bizesNm']?.toString().trim() ?? '';
      if (name.isEmpty) return null;

      final branch = item['brchNm']?.toString().trim() ?? '';
      final title = branch.isNotEmpty ? '$name $branch' : name;

      final lclsNm = item['indsLclsNm']?.toString().trim() ?? '';
      final mclsNm = item['indsMclsNm']?.toString().trim() ?? '';
      final sclsNm = item['indsSclsNm']?.toString().trim() ?? '';
      final description = [lclsNm, mclsNm, sclsNm]
          .where((s) => s.isNotEmpty)
          .join(' · ');

      final address = item['rdnmAdr']?.toString().trim() ??
          item['lnoAdr']?.toString().trim() ?? '';

      return CulturalEvent(
        id: 'sdsc_${item['bizesId'] ?? name}',
        title: title,
        venue: name,
        address: address,
        description: description.isEmpty ? '소상공인 업소' : description,
        startDate: now,
        endDateTime: endDateTime,
        location: LatLng(lat, lon),
        category: _mapCategory(item['indsLclsCd']?.toString()),
        isFree: false,
        source: EventSource.partner,
      );
    } catch (_) {
      return null;
    }
  }

  EventCategory _mapCategory(String? lclsCd) {
    return switch (lclsCd) {
      'Q' => EventCategory.partner,   // 음식점업
      'O' => EventCategory.partner,   // 생활서비스
      'G1' => EventCategory.partner,  // 도소매
      'G2' => EventCategory.partner,  // 소매
      'N' => EventCategory.partner,   // 숙박
      'R1' => EventCategory.show,     // 스포츠/레저
      _ => EventCategory.partner,
    };
  }
}

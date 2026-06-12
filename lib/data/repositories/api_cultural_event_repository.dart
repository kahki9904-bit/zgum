import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import '../../core/app_config.dart';
import '../../core/constants.dart';
import '../models/cultural_event.dart';
import 'cultural_event_repository.dart';

/// 한국관광공사 Tour API (공공데이터포털) 기반 구현체.
///
/// ## 서비스키 설정
/// [AppConstants.tourApiServiceKey]에 포털 '인코딩된 키'를 그대로 붙여넣으세요.
/// 포털 발급 화면에서 인코딩/디코딩 두 가지를 제공하는데, **인코딩된 키**를 사용합니다.
///
/// ## 인증키 이중 인코딩 문제 해결
/// Dio의 `queryParameters`에 서비스키를 넣으면 Dio가 다시 인코딩하여
/// `SERVICE_KEY_IS_NOT_REGISTERED_ERROR`가 발생합니다.
/// 이 구현체는 URL 문자열을 직접 결합(`baseUrl + '?serviceKey=...'`)하여 우회합니다.
///
/// ## 반경·시간 필터
/// - 서버 측: Tour API `radius` 파라미터로 1차 필터링 (단위: m, 최대 20,000)
/// - 클라이언트 측: 카테고리 필터링
/// - 시간 필터링: MapScreen의 TimeService.shouldShowEvent() 에서 별도 수행
class ApiCulturalEventRepository implements CulturalEventRepository {
  final Dio _dio;

  ApiCulturalEventRepository({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 15),
              // ResponseType.plain: 응답을 문자열로 받아 XML 오류 여부를 먼저 확인
              responseType: ResponseType.plain,
            ));

  @override
  Future<List<CulturalEvent>> fetchNearbyEvents({
    required LatLng center,
    required double radiusKm,
    required bool isIdentityVerified,
  }) async {
    final key = AppConfig.tourApiKey.trim();

    // 키 상태 로그 (전체 출력 금지 — 앞 4자리/뒤 4자리만)
    if (kDebugMode) {
      if (key.isEmpty) {
        debugPrint('[TourAPI] 키 없음 — 건너뜀');
      } else {
        final masked = '${key.substring(0, key.length.clamp(0, 4))}...'
            '${key.substring((key.length - 4).clamp(0, key.length))}';
        debugPrint('[TourAPI] 키 길이: ${key.length}, $masked');
      }
    }

    if (key.isEmpty) return [];

    // Tour API radius 파라미터: m 단위, 상한 20,000m
    final radiusM = (radiusKm * 1000).round().clamp(1000, 20000);

    // ── URL 직접 결합 (이중 인코딩 방지) ──────────────────────────────────────
    // Dio의 queryParameters를 쓰면 serviceKey가 이중 인코딩되므로
    // StringBuffer로 전체 URL을 직접 구성합니다.
    final url = StringBuffer('${AppConfig.tourApiBaseUrl}/locationBasedList1')
      ..write('?serviceKey=$key')
      ..write('&MobileOS=ETC')
      ..write('&MobileApp=${Uri.encodeComponent(AppConstants.appName)}')
      ..write('&_type=json')
      ..write('&contentTypeId=15') // 축제·공연·행사
      ..write('&mapX=${center.longitude}')
      ..write('&mapY=${center.latitude}')
      ..write('&radius=$radiusM')
      ..write('&numOfRows=50')
      ..write('&pageNo=1');

    try {
      final response = await _dio.get<String>(url.toString());

      if (response.statusCode != 200) {
        throw CulturalEventApiException('HTTP ${response.statusCode}');
      }

      final body = response.data ?? '';

      // 공공데이터포털은 오류 시에도 HTTP 200을 반환하며 XML 본문을 돌려줌.
      // XML 감지 시 상세 오류 메시지를 파싱합니다.
      if (body.trimLeft().startsWith('<')) {
        _throwFromXml(body);
      }

      final json = jsonDecode(body) as Map<String, dynamic>;
      final events = _parseResponse(json);
      if (!isIdentityVerified) {
        return events.where((e) => !e.isAdultOnly).toList();
      }
      return events;
    } on CulturalEventApiException {
      rethrow;
    } on DioException catch (e) {
      throw CulturalEventApiException('네트워크 오류: ${e.message ?? e.type.name}');
    } on FormatException catch (e) {
      throw CulturalEventApiException('응답 파싱 오류: $e');
    }
  }

  // ── JSON → 모델 파싱 ──────────────────────────────────────────────────────────

  List<CulturalEvent> _parseResponse(Map<String, dynamic> json) {
    final header =
        (json['response']?['header']) as Map<String, dynamic>? ?? {};
    final resultCode = header['resultCode']?.toString() ?? '';

    if (resultCode.isNotEmpty && resultCode != '0000') {
      throw CulturalEventApiException(
          '${header['resultMsg'] ?? '알 수 없는 오류'} (code: $resultCode)');
    }

    final body = json['response']?['body'];
    if (body == null) return [];

    final items = body['items'];
    if (items == null || items == '' || items is! Map) return [];

    final rawItem = items['item'];
    if (rawItem == null) return [];

    final itemList = rawItem is List
        ? rawItem.cast<Map<String, dynamic>>()
        : [rawItem as Map<String, dynamic>];

    final events = <CulturalEvent>[];
    for (final item in itemList) {
      final event = _parseItem(item);
      if (event == null) continue;
      events.add(event);
    }
    return events;
  }

  CulturalEvent? _parseItem(Map<String, dynamic> item) {
    try {
      // ── 좌표 파싱: Tour API는 위도/경도를 String으로 반환 ──────────────────
      final lat = double.tryParse(item['mapy']?.toString().trim() ?? '');
      final lng = double.tryParse(item['mapx']?.toString().trim() ?? '');
      // 유효하지 않은 좌표는 조용히 제외
      if (lat == null || lng == null || lat == 0.0 || lng == 0.0) return null;

      // ── 날짜 파싱: YYYYMMDD 형식 ─────────────────────────────────────────
      final startDate =
          _parseYYYYMMDD(item['eventstartdate']?.toString()) ?? DateTime.now();
      final endDate = _parseYYYYMMDD(item['eventenddate']?.toString()) ??
          DateTime.now().add(const Duration(days: 1));

      // 관람 종료 시각 기본값 21:00 (list API는 상세 시각을 제공하지 않음).
      // 더 정확한 값이 필요하면 detailInfo1 API를 별도 호출하세요.
      final endDateTime = endDate.copyWith(hour: 21, minute: 0, second: 0);

      final title = item['title']?.toString().trim() ?? '제목 없음';
      final addr = item['addr1']?.toString().trim() ?? '';

      return CulturalEvent(
        id: item['contentid']?.toString() ??
            DateTime.now().microsecondsSinceEpoch.toString(),
        title: title,
        venue: addr.isNotEmpty ? addr : '장소 미상',
        address: addr,
        // list API에는 overview(설명)가 없음 — 상세 API 연동 전까지 placeholder
        description: item['overview']?.toString().trim().isNotEmpty == true
            ? item['overview']!.toString().trim()
            : '공연장에서 상세 정보를 확인하세요.',
        imageUrl: _nonEmpty(item['firstimage']?.toString()),
        startDate: startDate,
        endDateTime: endDateTime,
        location: LatLng(lat, lng),
        category: _mapCategory(
          item['cat1']?.toString(),
          item['cat2']?.toString(),
          item['cat3']?.toString(),
          title,
        ),
        isFree: false, // list API에 가격 정보 없음
        source: EventSource.public,
      );
    } catch (_) {
      return null; // 파싱 실패 항목은 건너뜀
    }
  }

  // ── 카테고리 매핑 ─────────────────────────────────────────────────────────────
  // Tour API 중분류(cat2) / 소분류(cat3) 코드 기반 매핑.
  // 미지정 코드는 제목 키워드로 fallback.

  EventCategory _mapCategory(
      String? cat1, String? cat2, String? cat3, String title) {
    if (cat2 == 'A0207') return EventCategory.exhibition; // 문화시설·전시

    switch (cat3) {
      case 'A02080600':
        return EventCategory.theater; // 연극
      case 'A02080400':
        return EventCategory.theater; // 뮤지컬
      case 'A02080500':
        return EventCategory.theater; // 무용·발레
      case 'A02080100':
        return EventCategory.concert; // 클래식음악
      case 'A02080200':
        return EventCategory.concert; // 대중음악
      case 'A02080300':
        return EventCategory.concert; // 국악
    }

    // 제목 키워드 fallback
    final t = title.toLowerCase();
    if (t.contains('영화') || t.contains('시네마') || t.contains('film')) {
      return EventCategory.movie;
    }
    if (t.contains('연극') || t.contains('뮤지컬') || t.contains('무용')) {
      return EventCategory.theater;
    }
    if (t.contains('전시') || t.contains('미술') || t.contains('박물관') ||
        t.contains('갤러리')) {
      return EventCategory.exhibition;
    }
    if (t.contains('콘서트') || t.contains('클래식') || t.contains('국악') ||
        t.contains('오케스트라') || t.contains('오페라')) {
      return EventCategory.concert;
    }
    return EventCategory.show;
  }

  // ── XML 오류 감지 ─────────────────────────────────────────────────────────────
  // 공공데이터포털 특유의 XML 오류 응답에서 메시지를 추출합니다.

  Never _throwFromXml(String xml) {
    if (xml.contains('SERVICE_KEY_IS_NOT_REGISTERED_ERROR')) {
      throw const CulturalEventApiException(
          '서비스키 오류: AppConstants.tourApiServiceKey를 포털 발급 키로 교체하세요.\n'
          '포털 > 마이페이지 > 인증키 관리에서 "인코딩된 키"를 복사하세요.');
    }
    if (xml.contains('LIMITED_NUMBER_OF_SERVICE_REQUESTS_EXCEEDS_ERROR')) {
      throw const CulturalEventApiException('API 일일 호출 한도 초과. 내일 다시 시도하세요.');
    }
    if (xml.contains('INVALID_REQUEST_PARAMETER_ERROR')) {
      throw const CulturalEventApiException('요청 파라미터 오류. 좌표 값을 확인하세요.');
    }
    // 알 수 없는 XML 응답 — 앞부분만 잘라서 던집니다.
    throw CulturalEventApiException(
        'API XML 응답 오류: ${xml.substring(0, xml.length.clamp(0, 200))}');
  }

  // ── 유틸 ─────────────────────────────────────────────────────────────────────

  /// YYYYMMDD 문자열 → DateTime
  DateTime? _parseYYYYMMDD(String? s) {
    if (s == null || s.length != 8) return null;
    try {
      return DateTime(
        int.parse(s.substring(0, 4)),
        int.parse(s.substring(4, 6)),
        int.parse(s.substring(6, 8)),
      );
    } catch (_) {
      return null;
    }
  }

  String? _nonEmpty(String? s) =>
      (s == null || s.trim().isEmpty) ? null : s.trim();
}

// ── 도메인 예외 ───────────────────────────────────────────────────────────────

class CulturalEventApiException implements Exception {
  final String message;
  const CulturalEventApiException(this.message);

  @override
  String toString() => 'CulturalEventApiException: $message';
}

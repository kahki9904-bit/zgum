import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import '../../core/app_config.dart';
import '../../core/geo_utils.dart';
import '../models/cultural_event.dart';
import 'cultural_event_repository.dart';

/// KOPIS 공연예술통합전산망 기반 구현체.
///
/// 3개 엔드포인트 사용:
///  1. /pblprfr          — 공연 목록 조회 (mt20id 획득)
///  2. /pblprfr/{mt20id} — 공연 상세 조회 (mt10id 획득)
///  3. /prfplc/{mt10id}  — 공연시설 상세 조회 (좌표 획득)
///
/// KOPIS 응답은 XML. 내부에서 RegExp 기반 간이 파싱 사용.
/// API 실패 시 예외를 throw — 호출 측에서 catch하여 빈 목록 처리.
class KopisRepository implements CulturalEventRepository {
  final Dio _dio;

  // 공연시설 좌표 캐시 — 앱 세션 동안 mt10id 기준으로 재호출 방지
  static final Map<String, (LatLng, String)> _facilityCache = {};

  KopisRepository({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 15),
              responseType: ResponseType.plain,
            ));

  // ── 1. 공연 목록 → 상세 → 시설 좌표 → 반경 내 CulturalEvent 목록 ─────────────

  @override
  Future<List<CulturalEvent>> fetchNearbyEvents({
    required LatLng center,
    required double radiusKm,
    required bool isIdentityVerified,
  }) async {
    final key = AppConfig.kopisApiKey.trim();
    if (key.isEmpty) return [];

    if (kDebugMode) {
      final masked = '${key.substring(0, key.length.clamp(0, 4))}...'
          '${key.substring((key.length - 4).clamp(0, key.length))}';
      debugPrint('[KOPIS] 키 길이: ${key.length}, $masked');
    }

    // 공연 목록: 30일 전 ~ 60일 후 범위, 공연중(02)만, 최대 15개
    final now = DateTime.now();
    final stdate = _fmtDate(now.subtract(const Duration(days: 30)));
    final eddate = _fmtDate(now.add(const Duration(days: 60)));
    final listUrl = '${AppConfig.kopisApiBaseUrl}/pblprfr'
        '?service=$key'
        '&stdate=$stdate'
        '&eddate=$eddate'
        '&rows=15'
        '&cpage=1'
        '&prfstate=02'
        '&newsql=Y';

    final listRes = await _dio.get<String>(listUrl);
    final performances = _parseDbList(listRes.data ?? '');
    if (performances.isEmpty) return [];

    debugPrint('[KOPIS] 목록 ${performances.length}개 수신');

    // 공연 상세 → mt10id 획득 (병렬)
    final mt10ids = <String, String>{}; // mt20id → mt10id
    await Future.wait(
      performances.map((p) async {
        final mt20id = p['mt20id']!;
        try {
          final mt10id = await _fetchMt10id(key, mt20id);
          if (mt10id.isNotEmpty) mt10ids[mt20id] = mt10id;
        } catch (_) {}
      }),
      eagerError: false,
    );

    // 시설 좌표 획득 — 캐시 우선, 없으면 API 호출 (병렬)
    final uniqueMt10ids = mt10ids.values.toSet();
    await Future.wait(
      uniqueMt10ids.map((mt10id) async {
        if (_facilityCache.containsKey(mt10id)) return;
        try {
          final result = await _fetchFacilityCoord(key, mt10id);
          if (result != null) _facilityCache[mt10id] = result;
        } catch (_) {}
      }),
      eagerError: false,
    );

    // 거리 필터 → CulturalEvent 변환 (좌표 있는 것만)
    final events = <CulturalEvent>[];
    for (final p in performances) {
      final mt20id = p['mt20id']!;
      final mt10id = mt10ids[mt20id];
      if (mt10id == null) continue;
      final cached = _facilityCache[mt10id];
      if (cached == null) continue;
      final coord = cached.$1;
      final addr = cached.$2;
      if (haversineKm(center, coord) > radiusKm) continue;
      final event = _toEvent(p, coord, addr);
      if (event != null) events.add(event);
    }

    debugPrint('[KOPIS] ${events.length}개 이벤트 로드');
    return events;
  }

  // ── 2. 공연 상세 → mt10id 획득 ──────────────────────────────────────────────

  Future<String> _fetchMt10id(String key, String mt20id) async {
    final url =
        '${AppConfig.kopisApiBaseUrl}/pblprfr/$mt20id?service=$key&newsql=Y';
    final res = await _dio.get<String>(url);
    final db = _firstDb(res.data ?? '');
    return _tag(db, 'mt10id');
  }

  // ── 3. 공연시설 상세 → 좌표 획득 ────────────────────────────────────────────

  Future<(LatLng, String)?> _fetchFacilityCoord(String key, String mt10id) async {
    final url =
        '${AppConfig.kopisApiBaseUrl}/prfplc/$mt10id?service=$key&newsql=Y';
    final res = await _dio.get<String>(url);
    final db = _firstDb(res.data ?? '');
    final la = double.tryParse(_tag(db, 'la'));
    final lo = double.tryParse(_tag(db, 'lo'));
    if (la == null || lo == null || la == 0 || lo == 0) return null;
    return (LatLng(la, lo), _tag(db, 'adres'));
  }

  // ── 4. 공연 상세 조회 (마커 탭 시 on-demand 호출 가능) ──────────────────────

  Future<Map<String, String>?> fetchPerformanceDetail(String mt20id) async {
    final key = AppConfig.kopisApiKey.trim();
    if (key.isEmpty) return null;
    try {
      final url =
          '${AppConfig.kopisApiBaseUrl}/pblprfr/$mt20id?service=$key&newsql=Y';
      final res = await _dio.get<String>(url);
      final db = _firstDb(res.data ?? '');
      if (db.isEmpty) return null;
      return {
        'sty': _tag(db, 'sty'),
        'pcseguidance': _tag(db, 'pcseguidance'),
        'relates': _tag(db, 'relates'),
      };
    } catch (_) {
      return null;
    }
  }

  // ── XML 파싱 유틸 ────────────────────────────────────────────────────────────

  String _firstDb(String xml) =>
      RegExp(r'<db>(.*?)</db>', dotAll: true).firstMatch(xml)?.group(1)?.trim() ??
      '';

  List<Map<String, String>> _parseDbList(String xml) {
    final results = <Map<String, String>>[];
    for (final m in RegExp(r'<db>(.*?)</db>', dotAll: true).allMatches(xml)) {
      final db = m.group(1) ?? '';
      final item = {
        'mt20id': _tag(db, 'mt20id'),
        'prfnm': _tag(db, 'prfnm'),
        'prfpdfrom': _tag(db, 'prfpdfrom'),
        'prfpdto': _tag(db, 'prfpdto'),
        'fcltynm': _tag(db, 'fcltynm'),
        'poster': _tag(db, 'poster'),
        'genrenm': _tag(db, 'genrenm'),
      };
      if (item['mt20id']!.isNotEmpty) results.add(item);
    }
    return results;
  }

  String _tag(String xml, String tag) {
    final m = RegExp('<$tag>(.*?)</$tag>', dotAll: true).firstMatch(xml);
    return m?.group(1)?.trim() ?? '';
  }

  // ── 모델 변환 ────────────────────────────────────────────────────────────────

  CulturalEvent? _toEvent(
      Map<String, String> p, LatLng coord, String address) {
    final mt20id = p['mt20id']!;
    if (mt20id.isEmpty) return null;
    final start = _parseKopisDate(p['prfpdfrom'] ?? '') ?? DateTime.now();
    final end = _parseKopisDate(p['prfpdto'] ?? '') ??
        DateTime.now().add(const Duration(days: 30));
    final poster = p['poster']?.isNotEmpty == true ? p['poster'] : null;
    return CulturalEvent(
      id: 'kopis_$mt20id',
      title: p['prfnm'] ?? '제목 없음',
      venue: p['fcltynm'] ?? '장소 미상',
      address: address,
      description: '공연장에서 상세 정보를 확인하세요.',
      imageUrl: poster,
      startDate: start,
      endDateTime: end.copyWith(hour: 22, minute: 0, second: 0),
      location: coord,
      category: _mapGenre(p['genrenm']),
      isFree: false,
      source: EventSource.public,
    );
  }

  EventCategory _mapGenre(String? genre) {
    if (genre == null) return EventCategory.show;
    if (genre.contains('뮤지컬') || genre.contains('연극')) {
      return EventCategory.theater;
    }
    if (genre.contains('음악') || genre.contains('클래식') ||
        genre.contains('국악') || genre.contains('오페라')) {
      return EventCategory.concert;
    }
    if (genre.contains('무용') || genre.contains('발레')) {
      return EventCategory.theater;
    }
    if (genre.contains('전시') || genre.contains('미술')) {
      return EventCategory.exhibition;
    }
    return EventCategory.show;
  }

  // ── 날짜 유틸 ────────────────────────────────────────────────────────────────

  DateTime? _parseKopisDate(String s) {
    final parts = s.split('.');
    if (parts.length != 3) return null;
    return DateTime.tryParse('${parts[0]}-${parts[1]}-${parts[2]}');
  }

  String _fmtDate(DateTime d) =>
      '${d.year}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';
}

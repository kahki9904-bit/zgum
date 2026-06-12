import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../../../data/models/check_in_record.dart';
import '../../../data/repositories/check_in_repository.dart';
import '../../../data/repositories/local_check_in_repository.dart';

class CheckInNotifier extends StateNotifier<List<CheckInRecord>> {
  final CheckInRepository _repo;

  CheckInNotifier(this._repo) : super([]) {
    _load();
  }

  Future<void> _load() async {
    state = await _repo.getAll();
  }

  Future<void> save(CheckInRecord record) async {
    await _repo.save(record);
    state = [record, ...state];
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    state = state.where((r) => r.id != id).toList();
  }

  Set<String> get checkedInEventIds =>
      state.map((r) => r.eventId).toSet();

  Future<void> seedPreviewData() async {
    // 기존 preview 기록 전부 제거 후 새로 심기
    final existing = state.where((r) => r.id.startsWith('preview_')).toList();
    for (final r in existing) {
      await delete(r.id);
    }

    final dir = await getApplicationDocumentsDirectory();

    Future<String> makeImage(
        String name, ui.Color c1, ui.Color c2) async {
      const w = 400, h = 400;
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      final paint = ui.Paint()
        ..shader = ui.Gradient.linear(
          ui.Offset.zero,
          ui.Offset(0, h.toDouble()),
          [c1, c2],
        );
      canvas.drawRect(
        ui.Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
        paint,
      );
      final pic = recorder.endRecording();
      final img = await pic.toImage(w, h);
      final bd = await img.toByteData(format: ui.ImageByteFormat.png);
      final path = '${dir.path}/$name';
      await File(path).writeAsBytes(bd!.buffer.asUint8List());
      return path;
    }

    final imgs = await Future.wait([
      makeImage('trace_0.png', const ui.Color(0xFF3A5FCD), const ui.Color(0xFF16213E)),
      makeImage('trace_1.png', const ui.Color(0xFF27AE60), const ui.Color(0xFF1A5C33)),
      makeImage('trace_2.png', const ui.Color(0xFFE67E22), const ui.Color(0xFF7D3C00)),
      makeImage('trace_3.png', const ui.Color(0xFF8E44AD), const ui.Color(0xFF3B1A5C)),
      makeImage('trace_4.png', const ui.Color(0xFFE74C3C), const ui.Color(0xFF6B1A14)),
      makeImage('trace_5.png', const ui.Color(0xFF1ABC9C), const ui.Color(0xFF0A4A3E)),
    ]);

    final now = DateTime.now();
    final data = [
      ('현대미술 특별전: 빛과 공간', '국립현대미술관 서울', '전시', 1, 0, '빛이 공간을 가득 채우는 작품 앞에서 한참을 서 있었다.'),
      ('뮤지컬: 레미제라블', '예술의전당 오페라하우스', '공연', 3, 1, null),
      ('북토크: 밤의 도서관', '교보문고 광화문점', '강연', 5, -1, '작가와 직접 이야기를 나눴다. 책보다 더 깊은 대화였다.'),
      ('재즈 나이트 with 윈터필드', '올림픽공원 88잔디마당', '공연', 7, 2, '야외에서 듣는 재즈는 또 다른 차원이었다.'),
      ('피아노 소품집 — 쇼팽 & 드뷔시', '롯데콘서트홀', '공연', 10, -1, '빗소리와 피아노 소리가 섞이는 저녁이었다.'),
      ('사진전: 서울의 골목', '인사아트센터', '전시', 14, 3, '잊고 있던 골목들을 사진으로 다시 만났다.'),
      ('영화음악 갈라 콘서트', 'KBS홀', '공연', 17, 4, null),
      ('클래식 기타 독주회', '세종문화회관', '공연', 20, 5, '손끝에서 나오는 소리가 이렇게 깊을 수 있다니.'),
      ('현대무용: 경계선', '아르코예술극장', '공연', 22, 0, null),
      ('조각전: 물질과 기억', '소마미술관', '전시', 25, 1, '조각 하나하나에 시간이 담겨 있는 느낌이었다.'),
      ('인디 밴드 페스티벌', '홍대 무브홀', '공연', 28, 2, null),
      ('서예전: 먹과 여백', '국립중앙박물관', '전시', 30, -1, '여백이 말하는 방식이 있다.'),
      ('영상미술전: 무한 루프', '디뮤지엄', '전시', 33, 3, null),
      ('어쿠스틱 라이브: 봄날', '벨로드롬', '공연', 36, 4, '노래 한 곡이 계절을 불러왔다.'),
      ('도예전: 흙의 언어', '이화아트센터', '전시', 38, 5, null),
      ('오페라: 마술피리', '국립오페라단', '공연', 40, 0, '마지막 장면에서 눈물이 났다.'),
      ('드로잉전: 선의 기억', '갤러리현대', '전시', 42, 1, null),
      ('스탠드업 코미디 나이트', '홍대 롤링홀', '공연', 44, 2, '배가 아플 정도로 웃었다.'),
      ('일러스트레이션 페어', 'DDP 살림터', '전시', 46, -1, null),
      ('현악 사중주: 베토벤', '예술의전당 IBK챔버홀', '공연', 48, 3, '실내악의 밀도가 이런 것이구나.'),
      ('거리 예술 축제', '광화문광장', '전시', 50, 4, null),
      ('발레: 잠자는 숲속의 미녀', '국립발레단', '공연', 52, 5, '무대 위 중력이 다른 세계였다.'),
      ('미디어아트: 빛의 정원', '63아트', '전시', 54, 0, null),
      ('음악극: 별의 노래', '정동극장', '공연', 56, 1, '소극장의 따뜻함이 좋았다.'),
      ('설치미술전: 공간과 빛', '아모레퍼시픽미술관', '전시', 58, 2, null),
      ('해금 독주회', '국립국악원', '공연', 60, -1, '해금 소리가 마음을 흔들었다.'),
      ('회화전: 도시의 표정', '가나아트센터', '전시', 62, 3, null),
      ('퓨전 국악 공연', '세종문화회관 M씨어터', '공연', 64, 4, '전통과 현대가 만나는 지점이 선명했다.'),
      ('그래픽 노블 전시', '성수 언더스탠드에비뉴', '전시', 66, 5, null),
      ('재즈 & 블루스 세션', '이태원 재즈바', '공연', 68, 0, '새벽 두 시까지 자리를 뜰 수가 없었다.'),
    ];

    for (var i = 0; i < data.length; i++) {
      final (title, venue, cat, days, imgIdx, memo) = data[i];
      final photoPath = imgIdx >= 0 ? imgs[imgIdx] : null;
      await save(CheckInRecord(
        id: 'preview_$i',
        eventId: 'evt_p$i',
        eventTitle: title,
        venue: venue,
        categoryLabel: cat,
        checkedInAt: now.subtract(Duration(days: days, hours: i % 12)),
        photoPath: photoPath,
        memo: memo,
      ));
    }
  }
}

final checkInRepositoryProvider = Provider<CheckInRepository>(
  (_) => LocalCheckInRepository(),
);

final checkInProvider =
    StateNotifierProvider<CheckInNotifier, List<CheckInRecord>>(
  (ref) => CheckInNotifier(ref.read(checkInRepositoryProvider)),
);

import '../models/check_in_record.dart';

/// 체크인 기록 저장소 추상 인터페이스.
///
/// 현재: [LocalCheckInRepository] (SharedPreferences + 로컬 파일)
/// 추후: ApiCheckInRepository (서버 REST API + 클라우드 스토리지) 로 교체
abstract class CheckInRepository {
  Future<List<CheckInRecord>> getAll();
  Future<void> save(CheckInRecord record);
  Future<void> delete(String id);
}

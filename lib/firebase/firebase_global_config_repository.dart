// Firestore 연동 포인트: 문서 'config/global'
// 전환 시: server_transition_providers.dart 에서 MockGlobalConfigRepository → FirebaseGlobalConfigRepository 교체
import '../data/models/admin/global_config.dart';
import '../data/repositories/admin/global_config_repository.dart';

class FirebaseGlobalConfigRepository implements GlobalConfigRepository {
  @override
  Future<GlobalConfig> fetch() =>
      throw UnimplementedError('Firestore 연동 후 구현');

  @override
  Future<void> save(GlobalConfig config) =>
      throw UnimplementedError('Firestore 연동 후 구현');

  @override
  Stream<GlobalConfig> watch() =>
      throw UnimplementedError('Firestore 연동 후 구현');
}

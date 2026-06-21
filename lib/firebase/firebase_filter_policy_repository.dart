// Firestore 연동 포인트: 문서 'config/filter_policy'
// 전환 시: server_transition_providers.dart 에서 MockFilterPolicyRepository → FirebaseFilterPolicyRepository 교체
import '../data/models/admin/filter_policy.dart';
import '../data/repositories/admin/filter_policy_repository.dart';

class FirebaseFilterPolicyRepository implements FilterPolicyRepository {
  @override
  Future<FilterPolicy> fetch() =>
      throw UnimplementedError('Firestore 연동 후 구현');

  @override
  Future<void> save(FilterPolicy policy) =>
      throw UnimplementedError('Firestore 연동 후 구현');

  @override
  Stream<FilterPolicy> watch() =>
      throw UnimplementedError('Firestore 연동 후 구현');
}

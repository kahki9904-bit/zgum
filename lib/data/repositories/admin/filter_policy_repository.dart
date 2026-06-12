import '../../models/admin/filter_policy.dart';

abstract interface class FilterPolicyRepository {
  Future<FilterPolicy> fetch();
  Future<void> save(FilterPolicy policy);
  Stream<FilterPolicy> watch();
}

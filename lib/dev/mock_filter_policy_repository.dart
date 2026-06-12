import 'dart:async';
import '../data/models/admin/filter_policy.dart';
import '../data/repositories/admin/filter_policy_repository.dart';

class MockFilterPolicyRepository implements FilterPolicyRepository {
  FilterPolicy _current = FilterPolicy.defaults();
  final _controller = StreamController<FilterPolicy>.broadcast();

  @override
  Future<FilterPolicy> fetch() async => _current;

  @override
  Future<void> save(FilterPolicy policy) async {
    _current = policy;
    _controller.add(_current);
  }

  @override
  Stream<FilterPolicy> watch() => _controller.stream;
}

import 'dart:async';
import '../data/models/admin/global_config.dart';
import '../data/repositories/admin/global_config_repository.dart';

class MockGlobalConfigRepository implements GlobalConfigRepository {
  GlobalConfig _current = GlobalConfig.defaults();
  final _controller = StreamController<GlobalConfig>.broadcast();

  @override
  Future<GlobalConfig> fetch() async => _current;

  @override
  Future<void> save(GlobalConfig config) async {
    _current = config;
    _controller.add(_current);
  }

  @override
  Stream<GlobalConfig> watch() => _controller.stream;
}

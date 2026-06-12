import '../../models/admin/global_config.dart';

abstract interface class GlobalConfigRepository {
  Future<GlobalConfig> fetch();
  Future<void> save(GlobalConfig config);
  Stream<GlobalConfig> watch();
}

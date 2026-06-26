import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/trace_repository.dart';
import '../../data/repositories/trace_sync_queue.dart';
import '../../data/repositories/admin/audit_log_repository.dart';
import '../../data/repositories/admin/global_config_repository.dart';
import '../../data/repositories/admin/filter_policy_repository.dart';
import '../../data/repositories/admin/account_management_repository.dart';
import '../../features/partner_room/data/repositories/partner_repository.dart';
import '../../services/push_service.dart';
import '../../firebase/firebase_auth_repository.dart';
import '../../firebase/firebase_trace_repository.dart';
import '../../firebase/firebase_trace_sync_queue.dart';
import '../../firebase/firebase_partner_repository.dart';
import '../../firebase/firebase_push_service.dart';
import '../../dev/mock_global_config_repository.dart';
import '../../dev/mock_audit_log_repository.dart';
import '../../dev/mock_filter_policy_repository.dart';

// ── 서버 전환 시 교체할 Provider 목록 ─────────────────────────────────────────
//
// 실서비스 전환 방법:
//   1. lib/data/repositories/ 또는 lib/services/ 에 Api* 구현체 작성
//   2. 아래 Mock* 를 Api* 로 교체
//   3. UI 코드 변경 없음

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => FirebaseAuthRepository(),
);

final traceRepositoryProvider = Provider<TraceRepository>(
  (ref) => FirebaseTraceRepository(),
);

final traceSyncQueueProvider = Provider<TraceSyncQueue>(
  (ref) => FirebaseTraceSyncQueue(),
);

final partnerRepositoryProvider = Provider<PartnerRepository>(
  (ref) => FirebasePartnerRepository(),
);

final pushServiceProvider = Provider<PushService>(
  (ref) {
    final service = FirebasePushService();
    ref.onDispose(service.dispose);
    return service;
  },
);

// ── 관리자 구조 Provider ────────────────────────────────────────────────────────

final globalConfigRepositoryProvider = Provider<GlobalConfigRepository>(
  (ref) => MockGlobalConfigRepository(),
);

final auditLogRepositoryProvider = Provider<AuditLogRepository>(
  (ref) => MockAuditLogRepository(),
);

// FilterPolicy, AccountManagement: Firebase 전환 시 Mock→Api* 교체
// (Mock 구현체 없음 — 인터페이스 교체 포인트만 선언)
final filterPolicyRepositoryProvider = Provider<FilterPolicyRepository>(
  (ref) => MockFilterPolicyRepository(),
);

final accountManagementRepositoryProvider = Provider<AccountManagementRepository>(
  (ref) => throw UnimplementedError('AccountManagementRepository not yet implemented'),
);

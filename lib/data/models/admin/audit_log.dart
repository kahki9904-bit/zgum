class AuditLog {
  final String id;
  final String adminId;
  final String adminName;
  final String targetId;
  final AuditTargetType targetType;
  final String fieldName;
  final String? previousValue;
  final String newValue;
  final DateTime timestamp;
  final String? note;

  const AuditLog({
    required this.id,
    required this.adminId,
    required this.adminName,
    required this.targetId,
    required this.targetType,
    required this.fieldName,
    this.previousValue,
    required this.newValue,
    required this.timestamp,
    this.note,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'adminId': adminId,
        'adminName': adminName,
        'targetId': targetId,
        'targetType': targetType.name,
        'fieldName': fieldName,
        'previousValue': previousValue,
        'newValue': newValue,
        'timestamp': timestamp.toIso8601String(),
        'note': note,
      };

  factory AuditLog.fromJson(Map<String, dynamic> json) => AuditLog(
        id: json['id'] as String,
        adminId: json['adminId'] as String,
        adminName: json['adminName'] as String,
        targetId: json['targetId'] as String,
        targetType: AuditTargetType.values.firstWhere(
          (e) => e.name == json['targetType'],
          orElse: () => AuditTargetType.other,
        ),
        fieldName: json['fieldName'] as String,
        previousValue: json['previousValue'] as String?,
        newValue: json['newValue'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        note: json['note'] as String?,
      );
}

enum AuditTargetType {
  event,       // 이벤트
  user,        // 사용자 계정
  partner,     // 파트너 계정
  globalConfig, // 글로벌 설정
  filterPolicy, // 필터 정책
  permission,  // 권한
  other,
}

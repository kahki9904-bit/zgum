class GlobalConfig {
  final bool emergencyMode;
  final bool cachePriorityMode;
  final Map<NotificationChannel, bool> notificationKillSwitches;
  final int? apiRateLimit;
  final bool searchEnabled;
  final DateTime updatedAt;
  final String updatedBy;

  const GlobalConfig({
    this.emergencyMode = false,
    this.cachePriorityMode = false,
    this.notificationKillSwitches = const {},
    this.apiRateLimit,
    this.searchEnabled = true,
    required this.updatedAt,
    required this.updatedBy,
  });

  factory GlobalConfig.defaults() => GlobalConfig(
        updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
        updatedBy: 'system',
      );

  GlobalConfig copyWith({
    bool? emergencyMode,
    bool? cachePriorityMode,
    Map<NotificationChannel, bool>? notificationKillSwitches,
    int? apiRateLimit,
    bool? searchEnabled,
    DateTime? updatedAt,
    String? updatedBy,
  }) =>
      GlobalConfig(
        emergencyMode: emergencyMode ?? this.emergencyMode,
        cachePriorityMode: cachePriorityMode ?? this.cachePriorityMode,
        notificationKillSwitches:
            notificationKillSwitches ?? this.notificationKillSwitches,
        apiRateLimit: apiRateLimit ?? this.apiRateLimit,
        searchEnabled: searchEnabled ?? this.searchEnabled,
        updatedAt: updatedAt ?? this.updatedAt,
        updatedBy: updatedBy ?? this.updatedBy,
      );

  bool isNotificationEnabled(NotificationChannel channel) =>
      notificationKillSwitches[channel] ?? true;

  Map<String, dynamic> toJson() => {
        'emergencyMode': emergencyMode,
        'cachePriorityMode': cachePriorityMode,
        'notificationKillSwitches': notificationKillSwitches
            .map((k, v) => MapEntry(k.name, v)),
        'apiRateLimit': apiRateLimit,
        'searchEnabled': searchEnabled,
        'updatedAt': updatedAt.toIso8601String(),
        'updatedBy': updatedBy,
      };

  factory GlobalConfig.fromJson(Map<String, dynamic> json) => GlobalConfig(
        emergencyMode: json['emergencyMode'] as bool? ?? false,
        cachePriorityMode: json['cachePriorityMode'] as bool? ?? false,
        notificationKillSwitches: (json['notificationKillSwitches']
                    as Map<String, dynamic>?)
                ?.map((k, v) => MapEntry(
                      NotificationChannel.values.firstWhere(
                        (e) => e.name == k,
                        orElse: () => NotificationChannel.general,
                      ),
                      v as bool,
                    )) ??
            {},
        apiRateLimit: json['apiRateLimit'] as int?,
        searchEnabled: json['searchEnabled'] as bool? ?? true,
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        updatedBy: json['updatedBy'] as String,
      );
}

enum NotificationChannel {
  trace,    // 흔적 알림
  friend,   // 이음 알림
  partner,  // 파트너 알림
  general,  // 일반 공지
}

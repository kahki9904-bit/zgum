import 'dart:convert';

class Friend {
  final String id;
  final String friendUserId; // 서버만 알고 있음, UI에 노출 안 함
  final DateTime createdAt;
  final DateTime expiresAt;
  final DateTime? lastNotifiedAt;

  const Friend({
    required this.id,
    required this.friendUserId,
    required this.createdAt,
    required this.expiresAt,
    this.lastNotifiedAt,
  });

  bool get isActive => DateTime.now().isBefore(expiresAt);

  bool get canNotify {
    if (lastNotifiedAt == null) return true;
    return DateTime.now().difference(lastNotifiedAt!) >=
        const Duration(hours: 12);
  }

  Friend copyWith({
    DateTime? expiresAt,
    DateTime? lastNotifiedAt,
  }) =>
      Friend(
        id: id,
        friendUserId: friendUserId,
        createdAt: createdAt,
        expiresAt: expiresAt ?? this.expiresAt,
        lastNotifiedAt: lastNotifiedAt ?? this.lastNotifiedAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'friendUserId': friendUserId,
        'createdAt': createdAt.toIso8601String(),
        'expiresAt': expiresAt.toIso8601String(),
        'lastNotifiedAt': lastNotifiedAt?.toIso8601String(),
      };

  factory Friend.fromJson(Map<String, dynamic> json) => Friend(
        id: json['id'] as String,
        friendUserId: json['friendUserId'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        expiresAt: DateTime.parse(json['expiresAt'] as String),
        lastNotifiedAt: json['lastNotifiedAt'] != null
            ? DateTime.parse(json['lastNotifiedAt'] as String)
            : null,
      );

  static List<Friend> listFromJson(String raw) {
    final list = jsonDecode(raw) as List;
    return list.map((e) => Friend.fromJson(e as Map<String, dynamic>)).toList();
  }

  static String listToJson(List<Friend> friends) =>
      jsonEncode(friends.map((f) => f.toJson()).toList());
}

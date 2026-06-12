class FilterPolicy {
  final List<String> blockedKeywords;
  final List<String> blockedCategories;
  final List<String> allowedRegions; // 빈 목록 = 전체 허용
  final int? maxSearchResults;
  final bool strictMode;
  final DateTime updatedAt;
  final String updatedBy;

  const FilterPolicy({
    this.blockedKeywords = const [],
    this.blockedCategories = const [],
    this.allowedRegions = const [],
    this.maxSearchResults,
    this.strictMode = false,
    required this.updatedAt,
    required this.updatedBy,
  });

  factory FilterPolicy.defaults() => FilterPolicy(
        updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
        updatedBy: 'system',
      );

  bool isKeywordAllowed(String keyword) =>
      !blockedKeywords.any((k) => keyword.toLowerCase().contains(k.toLowerCase()));

  bool isCategoryAllowed(String category) =>
      !blockedCategories.contains(category);

  FilterPolicy copyWith({
    List<String>? blockedKeywords,
    List<String>? blockedCategories,
    List<String>? allowedRegions,
    int? maxSearchResults,
    bool? strictMode,
    DateTime? updatedAt,
    String? updatedBy,
  }) =>
      FilterPolicy(
        blockedKeywords: blockedKeywords ?? this.blockedKeywords,
        blockedCategories: blockedCategories ?? this.blockedCategories,
        allowedRegions: allowedRegions ?? this.allowedRegions,
        maxSearchResults: maxSearchResults ?? this.maxSearchResults,
        strictMode: strictMode ?? this.strictMode,
        updatedAt: updatedAt ?? this.updatedAt,
        updatedBy: updatedBy ?? this.updatedBy,
      );

  Map<String, dynamic> toJson() => {
        'blockedKeywords': blockedKeywords,
        'blockedCategories': blockedCategories,
        'allowedRegions': allowedRegions,
        'maxSearchResults': maxSearchResults,
        'strictMode': strictMode,
        'updatedAt': updatedAt.toIso8601String(),
        'updatedBy': updatedBy,
      };

  factory FilterPolicy.fromJson(Map<String, dynamic> json) => FilterPolicy(
        blockedKeywords: List<String>.from(json['blockedKeywords'] as List? ?? []),
        blockedCategories: List<String>.from(json['blockedCategories'] as List? ?? []),
        allowedRegions: List<String>.from(json['allowedRegions'] as List? ?? []),
        maxSearchResults: json['maxSearchResults'] as int?,
        strictMode: json['strictMode'] as bool? ?? false,
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        updatedBy: json['updatedBy'] as String,
      );
}

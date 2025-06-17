class FilterConfig {
  final String? nameKeyword;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? uncontactedDays;
  final List<String> selectedTags;

  FilterConfig({
    this.nameKeyword,
    this.startDate,
    this.endDate,
    this.uncontactedDays,
    List<String>? selectedTags,
  }) : selectedTags = selectedTags ?? [];

  Map<String, dynamic> toJson() {
    return {
      'nameKeyword': nameKeyword,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'uncontactedDays': uncontactedDays,
      'selectedTags': selectedTags,
    };
  }

  factory FilterConfig.fromJson(Map<String, dynamic> json) {
    return FilterConfig(
      nameKeyword: json['nameKeyword'] as String?,
      startDate:
          json['startDate'] != null
              ? DateTime.tryParse(json['startDate'] as String? ?? '')
              : null,
      endDate:
          json['endDate'] != null
              ? DateTime.tryParse(json['endDate'] as String? ?? '')
              : null,
      uncontactedDays: json['uncontactedDays'] as int?,
      selectedTags: List<String>.from(json['selectedTags'] as List? ?? []),
    );
  }
}

enum SortType { name, createdTime, lastContactTime, contactCount }

class SortConfig {
  final SortType type;
  final bool isReverse;

  const SortConfig({this.type = SortType.name, this.isReverse = false});

  Map<String, dynamic> toJson() {
    return {'type': type.index, 'isReverse': isReverse};
  }

  factory SortConfig.fromJson(Map<String, dynamic> json) {
    return SortConfig(
      type:
          json['type'] != null
              ? SortType.values[json['type'] as int]
              : SortType.name,
      isReverse: json['isReverse'] as bool? ?? false,
    );
  }
}

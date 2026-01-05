import 'package:flutter/foundation.dart';

@immutable
class DatabaseField {
  final String id;
  final String name;
  final String type;
  final bool isRequired;
  final Map<String, dynamic>? metadata;

  const DatabaseField({
    required this.id,
    required this.name,
    required this.type,
    this.isRequired = false,
    this.metadata,
  });

  factory DatabaseField.fromMap(Map<String, dynamic> map) {
    return DatabaseField(
      id: map['id'],
      name: map['name'],
      type: map['type'],
      isRequired: map['isRequired'] ?? false,
      metadata: map['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'isRequired': isRequired,
      if (metadata != null) 'metadata': metadata,
    };
  }

  DatabaseField copyWith({
    String? id,
    String? name,
    String? type,
    bool? isRequired,
    Map<String, dynamic>? metadata,
  }) {
    return DatabaseField(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      isRequired: isRequired ?? this.isRequired,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DatabaseField &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          type == other.type &&
          isRequired == other.isRequired &&
          mapEquals(metadata, other.metadata);

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      type.hashCode ^
      isRequired.hashCode ^
      metadata.hashCode;
}

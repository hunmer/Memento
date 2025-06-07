import 'package:flutter/foundation.dart';

@immutable
class DatabaseField {
  final String id;
  final String name;
  final String type;
  final bool isRequired;

  const DatabaseField({
    required this.id,
    required this.name,
    required this.type,
    this.isRequired = false,
  });

  factory DatabaseField.fromMap(Map<String, dynamic> map) {
    return DatabaseField(
      id: map['id'],
      name: map['name'],
      type: map['type'],
      isRequired: map['isRequired'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'type': type, 'isRequired': isRequired};
  }

  DatabaseField copyWith({
    String? id,
    String? name,
    String? type,
    bool? isRequired,
  }) {
    return DatabaseField(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      isRequired: isRequired ?? this.isRequired,
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
          isRequired == other.isRequired;

  @override
  int get hashCode =>
      id.hashCode ^ name.hashCode ^ type.hashCode ^ isRequired.hashCode;
}

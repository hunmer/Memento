class Record {
  final String id;
  final String tableId;
  final Map<String, dynamic> fields;
  final DateTime createdAt;
  final DateTime updatedAt;

  Record({
    required this.id,
    required this.tableId,
    required this.fields,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Record.fromMap(Map<String, dynamic> map) {
    return Record(
      id: map['id'],
      tableId: map['tableId'],
      fields: Map<String, dynamic>.from(map['fields']),
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tableId': tableId,
      'fields': fields,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Record copyWith({
    String? id,
    String? tableId,
    Map<String, dynamic>? fields,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Record(
      id: id ?? this.id,
      tableId: tableId ?? this.tableId,
      fields: fields ?? this.fields,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

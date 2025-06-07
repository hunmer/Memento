class FieldModel {
  final String id;
  final String name;
  final String type;
  final String? description;

  FieldModel({
    required this.id,
    required this.name,
    required this.type,
    this.description,
  });

  FieldModel copyWith({
    String? id,
    String? name,
    String? type,
    String? description,
  }) {
    return FieldModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      description: description ?? this.description,
    );
  }
}

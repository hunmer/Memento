class CustomField {
  final String key;
  final String value;

  CustomField({
    required this.key,
    required this.value,
  });

  factory CustomField.fromJson(Map<String, dynamic> json) {
    return CustomField(
      key: json['key'] as String,
      value: json['value'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'value': value,
    };
  }
}
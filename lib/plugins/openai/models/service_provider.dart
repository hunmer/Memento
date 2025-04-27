class ServiceProvider {
  String id;
  String label;
  String baseUrl;
  Map<String, String> headers;

  ServiceProvider({
    required this.id,
    required this.label,
    required this.baseUrl,
    Map<String, String>? headers,
  }) : headers = headers ?? {};

  // 从JSON构造
  factory ServiceProvider.fromJson(Map<String, dynamic> json) {
    return ServiceProvider(
      id: json['id'] as String,
      label: json['label'] as String,
      baseUrl: json['baseUrl'] as String,
      headers: Map<String, String>.from(json['headers'] as Map),
    );
  }

  // 转换为JSON
  Map<String, dynamic> toJson() {
    return {'id': id, 'label': label, 'baseUrl': baseUrl, 'headers': headers};
  }

  // 复制对象并修改指定字段
  ServiceProvider copyWith({
    String? id,
    String? label,
    String? baseUrl,
    Map<String, String>? headers,
  }) {
    return ServiceProvider(
      id: id ?? this.id,
      label: label ?? this.label,
      baseUrl: baseUrl ?? this.baseUrl,
      headers: headers ?? Map<String, String>.from(this.headers),
    );
  }
}

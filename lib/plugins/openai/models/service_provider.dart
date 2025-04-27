class ServiceProvider {
  final String name;
  final String apiKey;
  final String baseUrl;
  final Map<String, String> headers;
  final Map<String, dynamic> config;

  const ServiceProvider({
    required this.name,
    required this.apiKey,
    this.baseUrl = 'https://api.openai.com/v1',
    this.headers = const {},
    this.config = const {},
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'apiKey': apiKey,
    'baseUrl': baseUrl,
    'headers': headers,
    'config': config,
  };

  factory ServiceProvider.fromJson(Map<String, dynamic> json) =>
      ServiceProvider(
        name: json['name'] as String,
        apiKey: json['apiKey'] as String,
        baseUrl: json['baseUrl'] as String? ?? 'https://api.openai.com/v1',
        headers:
            (json['headers'] as Map<String, dynamic>?)
                ?.cast<String, String>() ??
            {},
        config: json['config'] as Map<String, dynamic>? ?? {},
      );
}

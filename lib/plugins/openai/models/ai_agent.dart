class Prompt {
  String type;
  String content;

  Prompt({required this.type, required this.content});

  Map<String, dynamic> toJson() => {'type': type, 'content': content};

  factory Prompt.fromJson(Map<String, dynamic> json) =>
      Prompt(type: json['type'] as String, content: json['content'] as String);
}

class AIAgent {
  final String id;
  final String name;
  final String description;
  final String systemPrompt;
  final List<String> tags;
  final String serviceProviderId;
  final String baseUrl;
  final Map<String, String> headers;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String model;

  const AIAgent({
    required this.id,
    required this.name,
    required this.description,
    required this.systemPrompt,
    required this.tags,
    required this.serviceProviderId,
    required this.baseUrl,
    required this.headers,
    required this.createdAt,
    required this.updatedAt,
    required this.model,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'systemPrompt': systemPrompt,
    'tags': tags,
    'serviceProviderId': serviceProviderId,
    'baseUrl': baseUrl,
    'headers': headers,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'model': model,
  };

  factory AIAgent.fromJson(Map<String, dynamic> json) => AIAgent(
    id: json['id'] as String,
    name: json['name'] as String,
    description: json['description'] as String,
    systemPrompt: json['systemPrompt'] as String,
    tags: (json['tags'] as List).cast<String>(),
    serviceProviderId: json['serviceProviderId'] as String,
    baseUrl: json['baseUrl'] as String,
    headers: Map<String, String>.from(json['headers'] as Map),
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
    model: json['model'] as String? ?? 'gpt-3.5-turbo',
  );
}

import 'package:flutter/material.dart';

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
  final double temperature;
  final int maxLength;
  final double topP;
  final double frequencyPenalty;
  final double presencePenalty;
  final List<String>? stop;
  final DateTime updatedAt;
  final String model;
  final IconData? icon;
  final Color? iconColor;
  final String? avatarUrl;

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
    this.temperature = 0.7,
    this.maxLength = 2000,
    this.topP = 1.0,
    this.frequencyPenalty = 0.0,
    this.presencePenalty = 0.0,
    this.stop,
    required this.updatedAt,
    required this.model,
    this.icon,
    this.iconColor,
    this.avatarUrl,
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
    'temperature': temperature,
    'maxLength': maxLength,
    'topP': topP,
    'frequencyPenalty': frequencyPenalty,
    'presencePenalty': presencePenalty,
    'stop': stop,
    'updatedAt': updatedAt.toIso8601String(),
    'model': model,
    'icon': icon?.codePoint,
    'iconColor': iconColor?.value,
    'avatarUrl': avatarUrl,
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
    temperature: (json['temperature'] as num?)?.toDouble() ?? 0.7,
    maxLength: json['maxLength'] as int? ?? 2000,
    topP: (json['topP'] as num?)?.toDouble() ?? 1.0,
    frequencyPenalty: (json['frequencyPenalty'] as num?)?.toDouble() ?? 0.0,
    presencePenalty: (json['presencePenalty'] as num?)?.toDouble() ?? 0.0,
    stop: (json['stop'] as List<dynamic>?)?.cast<String>(),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
    model: json['model'] as String? ?? 'gpt-3.5-turbo',
    icon: json['icon'] != null ? IconData(json['icon'] as int, fontFamily: 'MaterialIcons') : null,
    iconColor: json['iconColor'] != null ? Color(json['iconColor'] as int) : null,
    avatarUrl: json['avatarUrl'] as String?,
  );

  /// 创建一个新的 AIAgent 实例，可以选择性地更新某些字段
  AIAgent copyWith({
    String? id,
    String? name,
    String? description,
    String? systemPrompt,
    List<String>? tags,
    String? serviceProviderId,
    String? baseUrl,
    Map<String, String>? headers,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? model,
    IconData? icon,
    Color? iconColor,
    String? avatarUrl,
    double? temperature,
    int? maxLength,
    double? topP,
    double? frequencyPenalty,
    double? presencePenalty,
    List<String>? stop,
  }) {
    return AIAgent(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      systemPrompt: systemPrompt ?? this.systemPrompt,
      tags: tags ?? this.tags,
      serviceProviderId: serviceProviderId ?? this.serviceProviderId,
      baseUrl: baseUrl ?? this.baseUrl,
      headers: headers ?? this.headers,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      model: model ?? this.model,
      icon: icon ?? this.icon,
      iconColor: iconColor ?? this.iconColor,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      temperature: temperature ?? this.temperature,
      maxLength: maxLength ?? this.maxLength,
      topP: topP ?? this.topP,
      frequencyPenalty: frequencyPenalty ?? this.frequencyPenalty,
      presencePenalty: presencePenalty ?? this.presencePenalty,
      stop: stop ?? this.stop,
    );
  }
}

import 'package:uuid/uuid.dart';
import 'tts_service_type.dart';

/// TTS服务配置模型
class TTSServiceConfig {
  /// 唯一标识 (UUID)
  final String id;

  /// 服务名称 (如 "系统语音"、"Azure TTS")
  String name;

  /// 服务类型
  TTSServiceType type;

  /// 是否为默认服务
  bool isDefault;

  /// 是否启用
  bool isEnabled;

  // === HTTP 特有配置 ===

  /// API URL (支持占位符: {text}, {voice}, {pitch}, {speed}, {volume})
  String? url;

  /// 请求头
  Map<String, String>? headers;

  /// 请求体模板 (JSON字符串,支持占位符)
  String? requestBody;

  /// 音频格式 (mp3/wav/pcm/ogg)
  String? audioFormat;

  /// 响应类型 (audio: 直接返回音频字节, json: JSON包裹)
  String? responseType;

  /// JSON响应中音频字段路径 (如 "data.audio")
  String? audioFieldPath;

  /// 音频是否为base64编码
  bool? audioIsBase64;

  // === MiniMax 特有配置 ===

  /// MiniMax API Key
  String? apiKey;

  /// MiniMax 语音ID
  String? voiceId;

  /// MiniMax 情绪 (happy, sad, angry, fearful, disgusted, surprised, calm, fluent, whisper)
  String? emotion;

  /// MiniMax 模型 (speech-2.8-hd, speech-2.8-turbo, speech-2.6-hd, speech-2.6-turbo, etc.)
  String? model;

  // === 通用配置 ===

  /// 音调 (0.5-2.0, 默认1.0)
  double pitch;

  /// 语速 (0.5-2.0, 默认1.0)
  double speed;

  /// 音量 (0.0-1.0, 默认1.0)
  double volume;

  /// 语音名称/ID (系统TTS用语言代码如zh-CN, HTTP用自定义值)
  String? voice;

  /// 创建时间
  final DateTime createdAt;

  /// 更新时间
  DateTime updatedAt;

  TTSServiceConfig({
    String? id,
    required this.name,
    required this.type,
    this.isDefault = false,
    this.isEnabled = true,
    // HTTP配置
    this.url,
    this.headers,
    this.requestBody,
    this.audioFormat,
    this.responseType,
    this.audioFieldPath,
    this.audioIsBase64,
    // MiniMax配置
    this.apiKey,
    this.voiceId,
    this.emotion,
    this.model,
    // 通用配置
    this.pitch = 1.0,
    this.speed = 1.0,
    this.volume = 1.0,
    this.voice,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// 从JSON创建
  factory TTSServiceConfig.fromJson(Map<String, dynamic> json) {
    return TTSServiceConfig(
      id: json['id'] as String,
      name: json['name'] as String,
      type: TTSServiceTypeExtension.fromString(json['type'] as String),
      isDefault: json['isDefault'] as bool? ?? false,
      isEnabled: json['isEnabled'] as bool? ?? true,
      // HTTP配置
      url: json['url'] as String?,
      headers: json['headers'] != null
          ? Map<String, String>.from(json['headers'] as Map)
          : null,
      requestBody: json['requestBody'] as String?,
      audioFormat: json['audioFormat'] as String?,
      responseType: json['responseType'] as String?,
      audioFieldPath: json['audioFieldPath'] as String?,
      audioIsBase64: json['audioIsBase64'] as bool?,
      // MiniMax配置
      apiKey: json['apiKey'] as String?,
      voiceId: json['voiceId'] as String?,
      emotion: json['emotion'] as String?,
      model: json['model'] as String?,
      // 通用配置
      pitch: (json['pitch'] as num?)?.toDouble() ?? 1.0,
      speed: (json['speed'] as num?)?.toDouble() ?? 1.0,
      volume: (json['volume'] as num?)?.toDouble() ?? 1.0,
      voice: json['voice'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'isDefault': isDefault,
      'isEnabled': isEnabled,
      // HTTP配置
      if (url != null) 'url': url,
      if (headers != null) 'headers': headers,
      if (requestBody != null) 'requestBody': requestBody,
      if (audioFormat != null) 'audioFormat': audioFormat,
      if (responseType != null) 'responseType': responseType,
      if (audioFieldPath != null) 'audioFieldPath': audioFieldPath,
      if (audioIsBase64 != null) 'audioIsBase64': audioIsBase64,
      // MiniMax配置
      if (apiKey != null) 'apiKey': apiKey,
      if (voiceId != null) 'voiceId': voiceId,
      if (emotion != null) 'emotion': emotion,
      if (model != null) 'model': model,
      // 通用配置
      'pitch': pitch,
      'speed': speed,
      'volume': volume,
      if (voice != null) 'voice': voice,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// 复制并修改
  TTSServiceConfig copyWith({
    String? name,
    TTSServiceType? type,
    bool? isDefault,
    bool? isEnabled,
    String? url,
    Map<String, String>? headers,
    String? requestBody,
    String? audioFormat,
    String? responseType,
    String? audioFieldPath,
    bool? audioIsBase64,
    String? apiKey,
    String? voiceId,
    String? emotion,
    String? model,
    double? pitch,
    double? speed,
    double? volume,
    String? voice,
  }) {
    return TTSServiceConfig(
      id: id,
      name: name ?? this.name,
      type: type ?? this.type,
      isDefault: isDefault ?? this.isDefault,
      isEnabled: isEnabled ?? this.isEnabled,
      url: url ?? this.url,
      headers: headers ?? this.headers,
      requestBody: requestBody ?? this.requestBody,
      audioFormat: audioFormat ?? this.audioFormat,
      responseType: responseType ?? this.responseType,
      audioFieldPath: audioFieldPath ?? this.audioFieldPath,
      audioIsBase64: audioIsBase64 ?? this.audioIsBase64,
      apiKey: apiKey ?? this.apiKey,
      voiceId: voiceId ?? this.voiceId,
      emotion: emotion ?? this.emotion,
      model: model ?? this.model,
      pitch: pitch ?? this.pitch,
      speed: speed ?? this.speed,
      volume: volume ?? this.volume,
      voice: voice ?? this.voice,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  /// 验证配置是否完整
  bool validate() {
    if (name.isEmpty) return false;

    if (type == TTSServiceType.http) {
      // HTTP服务需要URL
      if (url == null || url!.isEmpty) return false;
      // 需要指定响应类型
      if (responseType == null) return false;
      // 如果是JSON响应,需要指定音频字段路径
      if (responseType == 'json' &&
          (audioFieldPath == null || audioFieldPath!.isEmpty)) {
        return false;
      }
    }

    if (type == TTSServiceType.minimax) {
      // MiniMax服务需要API Key和语音ID
      if (apiKey == null || apiKey!.isEmpty) return false;
      if (voiceId == null || voiceId!.isEmpty) return false;
    }

    return true;
  }

  @override
  String toString() => 'TTSServiceConfig(id: $id, name: $name, type: ${type.name})';
}

/// 语音通话配置
class VoiceCallConfig {
  /// TTS服务ID（null表示使用默认服务）
  final String? ttsServiceId;

  /// 自动开始下一轮对话
  final bool autoContinue;

  /// TTS播报完成后自动开始录音
  final bool autoRecordAfterSpeaking;

  /// 最大连续对话轮数（0表示无限制）
  final int maxTurns;

  /// 录音超时时间（秒）
  final int recordingTimeout;

  /// 自动发送超时时间（秒，距离上一个单词后自动发送）
  final int autoSendTimeout;

  /// 是否播报欢迎语
  final bool enableWelcomeMessage;

  /// 欢迎语
  final String welcomeMessage;

  /// 背景图路径
  final String? backgroundImagePath;

  const VoiceCallConfig({
    this.ttsServiceId,
    this.autoContinue = true,
    this.autoRecordAfterSpeaking = true,
    this.maxTurns = 0,
    this.recordingTimeout = 30,
    this.autoSendTimeout = 3,
    this.enableWelcomeMessage = false,
    this.welcomeMessage = '您好，我是AI助手，请开始说话',
    this.backgroundImagePath,
  });

  VoiceCallConfig copyWith({
    String? ttsServiceId,
    bool? autoContinue,
    bool? autoRecordAfterSpeaking,
    int? maxTurns,
    int? recordingTimeout,
    int? autoSendTimeout,
    bool? enableWelcomeMessage,
    String? welcomeMessage,
    String? backgroundImagePath,
  }) {
    return VoiceCallConfig(
      ttsServiceId: ttsServiceId ?? this.ttsServiceId,
      autoContinue: autoContinue ?? this.autoContinue,
      autoRecordAfterSpeaking: autoRecordAfterSpeaking ?? this.autoRecordAfterSpeaking,
      maxTurns: maxTurns ?? this.maxTurns,
      recordingTimeout: recordingTimeout ?? this.recordingTimeout,
      autoSendTimeout: autoSendTimeout ?? this.autoSendTimeout,
      enableWelcomeMessage: enableWelcomeMessage ?? this.enableWelcomeMessage,
      welcomeMessage: welcomeMessage ?? this.welcomeMessage,
      backgroundImagePath: backgroundImagePath ?? this.backgroundImagePath,
    );
  }

  /// 从 JSON 创建
  factory VoiceCallConfig.fromJson(Map<String, dynamic> json) {
    return VoiceCallConfig(
      ttsServiceId: json['ttsServiceId'] as String?,
      autoContinue: json['autoContinue'] as bool? ?? true,
      autoRecordAfterSpeaking: json['autoRecordAfterSpeaking'] as bool? ?? true,
      maxTurns: json['maxTurns'] as int? ?? 0,
      recordingTimeout: json['recordingTimeout'] as int? ?? 30,
      autoSendTimeout: json['autoSendTimeout'] as int? ?? 3,
      enableWelcomeMessage: json['enableWelcomeMessage'] as bool? ?? false,
      welcomeMessage: json['welcomeMessage'] as String? ?? '您好，我是AI助手，请开始说话',
      backgroundImagePath: json['backgroundImagePath'] as String?,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'ttsServiceId': ttsServiceId,
      'autoContinue': autoContinue,
      'autoRecordAfterSpeaking': autoRecordAfterSpeaking,
      'maxTurns': maxTurns,
      'recordingTimeout': recordingTimeout,
      'autoSendTimeout': autoSendTimeout,
      'enableWelcomeMessage': enableWelcomeMessage,
      'welcomeMessage': welcomeMessage,
      'backgroundImagePath': backgroundImagePath,
    };
  }
}

/// TTS 自动朗读配置
class TTSConfig {
  /// 是否启用自动朗读
  final bool enabled;

  /// TTS 服务 ID（null 表示使用默认服务）
  final String? serviceId;

  const TTSConfig({
    this.enabled = false,
    this.serviceId,
  });

  TTSConfig copyWith({
    bool? enabled,
    String? serviceId,
  }) {
    return TTSConfig(
      enabled: enabled ?? this.enabled,
      serviceId: serviceId ?? this.serviceId,
    );
  }

  factory TTSConfig.fromJson(Map<String, dynamic> json) {
    return TTSConfig(
      enabled: json['enabled'] as bool? ?? false,
      serviceId: json['serviceId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'serviceId': serviceId,
    };
  }
}

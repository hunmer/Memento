/// TTS服务类型枚举
enum TTSServiceType {
  /// 系统TTS (使用flutter_tts)
  system,

  /// HTTP API服务
  http,

  /// MiniMax 语音合成服务
  minimax,
}

/// 扩展方法
extension TTSServiceTypeExtension on TTSServiceType {
  /// 获取类型名称
  String get name {
    switch (this) {
      case TTSServiceType.system:
        return 'system';
      case TTSServiceType.http:
        return 'http';
      case TTSServiceType.minimax:
        return 'minimax';
    }
  }

  /// 获取类型显示名称
  String get displayName {
    switch (this) {
      case TTSServiceType.system:
        return '系统语音';
      case TTSServiceType.http:
        return 'HTTP服务';
      case TTSServiceType.minimax:
        return 'MiniMax';
    }
  }

  /// 从字符串转换
  static TTSServiceType fromString(String value) {
    switch (value) {
      case 'system':
        return TTSServiceType.system;
      case 'http':
        return TTSServiceType.http;
      case 'minimax':
        return TTSServiceType.minimax;
      default:
        return TTSServiceType.system;
    }
  }
}

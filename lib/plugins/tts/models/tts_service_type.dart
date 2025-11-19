/// TTS服务类型枚举
enum TTSServiceType {
  /// 系统TTS (使用flutter_tts)
  system,

  /// HTTP API服务
  http,
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
    }
  }

  /// 从字符串转换
  static TTSServiceType fromString(String value) {
    switch (value) {
      case 'system':
        return TTSServiceType.system;
      case 'http':
        return TTSServiceType.http;
      default:
        return TTSServiceType.system;
    }
  }
}

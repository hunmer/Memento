import 'package:Memento/plugins/tts/models/tts_service_config.dart';
import 'package:Memento/plugins/tts/models/tts_voice.dart';

/// TTS服务回调
typedef TTSCallback = void Function();
typedef TTSErrorCallback = void Function(String error);

/// TTS服务抽象基类
abstract class TTSBaseService {
  /// 服务配置
  final TTSServiceConfig config;

  TTSBaseService(this.config);

  /// 初始化服务
  Future<void> initialize();

  /// 朗读文本
  ///
  /// [text] 要朗读的文本
  /// [onStart] 开始朗读回调
  /// [onComplete] 完成回调
  /// [onError] 错误回调
  Future<void> speak(
    String text, {
    TTSCallback? onStart,
    TTSCallback? onComplete,
    TTSErrorCallback? onError,
  });

  /// 停止朗读
  Future<void> stop();

  /// 暂停朗读
  Future<void> pause();

  /// 继续朗读
  Future<void> resume();

  /// 获取可用语音列表
  Future<List<TTSVoice>> getAvailableVoices();

  /// 测试服务连接 (HTTP服务用)
  Future<bool> testConnection();

  /// 释放资源
  Future<void> dispose();
}

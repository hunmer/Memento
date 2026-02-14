import 'package:flutter/foundation.dart';
import 'package:Memento/core/app_initializer.dart' show globalConfigManager;
import 'package:Memento/plugins/agent_chat/services/speech/speech_recognition_config.dart';

/// 语音识别配置服务
///
/// 全局单例服务，用于管理语音识别配置。
/// 配置存储在全局配置中，可被多个插件共享使用。
class SpeechRecognitionConfigService extends ChangeNotifier {
  static SpeechRecognitionConfigService? _instance;

  /// 获取单例实例
  static SpeechRecognitionConfigService get instance {
    _instance ??= SpeechRecognitionConfigService._();
    return _instance!;
  }

  SpeechRecognitionConfigService._();

  /// 配置存储键（作为特殊插件 ID）
  static const String _configPluginId = 'speechRecognition';

  /// 缓存的配置
  TencentASRConfig? _cachedConfig;

  /// 获取腾讯云 ASR 配置
  TencentASRConfig? get config => _cachedConfig;

  /// 检查是否已配置
  bool get isConfigured => _cachedConfig != null && _cachedConfig!.isValid();

  /// 初始化服务，加载配置
  Future<void> initialize() async {
    await _loadConfig();
  }

  /// 加载配置
  Future<void> _loadConfig() async {
    try {
      final configMap = await globalConfigManager.getPluginConfig(_configPluginId);
      debugPrint('🎤 [语音识别配置服务] 读取到的配置: $configMap');

      if (configMap != null && configMap.isNotEmpty) {
        final asrConfigMap = configMap['asrConfig'] as Map<String, dynamic>?;
        if (asrConfigMap != null) {
          _cachedConfig = TencentASRConfig.fromJson(asrConfigMap);
          debugPrint('🎤 [语音识别配置服务] 加载配置成功: appId=${_cachedConfig?.appId}');
        }
      }
    } catch (e) {
      debugPrint('🎤 [语音识别配置服务] 加载配置失败: $e');
      _cachedConfig = null;
    }
    notifyListeners();
  }

  /// 保存配置
  Future<void> saveConfig(TencentASRConfig config) async {
    try {
      await globalConfigManager.savePluginConfig(_configPluginId, {
        'asrConfig': config.toJson(),
      });

      _cachedConfig = config;
      debugPrint('🎤 [语音识别配置服务] 保存配置成功: appId=${config.appId}');

      notifyListeners();
    } catch (e) {
      debugPrint('🎤 [语音识别配置服务] 保存配置失败: $e');
      rethrow;
    }
  }

  /// 清除配置
  Future<void> clearConfig() async {
    try {
      await globalConfigManager.savePluginConfig(_configPluginId, {});
      _cachedConfig = null;
      debugPrint('🎤 [语音识别配置服务] 配置已清除');
      notifyListeners();
    } catch (e) {
      debugPrint('🎤 [语音识别配置服务] 清除配置失败: $e');
      rethrow;
    }
  }

  /// 重新加载配置
  Future<void> reload() async {
    await _loadConfig();
  }
}

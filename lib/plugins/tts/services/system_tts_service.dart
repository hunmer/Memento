import 'package:flutter_tts/flutter_tts.dart';
import 'package:logging/logging.dart';
import 'tts_base_service.dart';
import '../models/tts_voice.dart';
import '../models/tts_service_config.dart';

/// 系统TTS服务实现 (使用flutter_tts)
class SystemTTSService extends TTSBaseService {
  static final _log = Logger('SystemTTSService');
  late FlutterTts _flutterTts;

  TTSCallback? _onStart;
  TTSCallback? _onComplete;
  TTSErrorCallback? _onError;

  SystemTTSService(super.config);

  @override
  Future<void> initialize() async {
    try {
      _flutterTts = FlutterTts();

      // 设置参数
      await _flutterTts.setPitch(config.pitch);
      await _flutterTts.setSpeechRate(config.speed);
      await _flutterTts.setVolume(config.volume);

      // 设置语言/语音
      if (config.voice != null && config.voice!.isNotEmpty) {
        await _flutterTts.setLanguage(config.voice!);
      }

      // 设置回调
      _flutterTts.setStartHandler(() {
        _log.info('开始朗读');
        _onStart?.call();
      });

      _flutterTts.setCompletionHandler(() {
        _log.info('朗读完成');
        _onComplete?.call();
      });

      _flutterTts.setErrorHandler((msg) {
        _log.warning('朗读出错: $msg');
        _onError?.call(msg);
      });

      _log.info('系统TTS服务初始化成功: ${config.name}');
    } catch (e) {
      _log.severe('系统TTS服务初始化失败: $e');
      rethrow;
    }
  }

  @override
  Future<void> speak(
    String text, {
    TTSCallback? onStart,
    TTSCallback? onComplete,
    TTSErrorCallback? onError,
  }) async {
    try {
      _onStart = onStart;
      _onComplete = onComplete;
      _onError = onError;

      _log.info('朗读文本: ${text.substring(0, text.length > 50 ? 50 : text.length)}...');

      // 更新参数(可能在配置中已修改)
      await _flutterTts.setPitch(config.pitch);
      await _flutterTts.setSpeechRate(config.speed);
      await _flutterTts.setVolume(config.volume);

      if (config.voice != null && config.voice!.isNotEmpty) {
        await _flutterTts.setLanguage(config.voice!);
      }

      await _flutterTts.speak(text);
    } catch (e) {
      _log.severe('朗读失败: $e');
      onError?.call(e.toString());
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _flutterTts.stop();
      _log.info('停止朗读');
    } catch (e) {
      _log.warning('停止朗读失败: $e');
    }
  }

  @override
  Future<void> pause() async {
    try {
      await _flutterTts.pause();
      _log.info('暂停朗读');
    } catch (e) {
      _log.warning('暂停朗读失败: $e');
    }
  }

  @override
  Future<void> resume() async {
    // flutter_tts 不支持 resume,只能重新speak
    // 这里留空,由管理器处理
    _log.info('系统TTS不支持resume');
  }

  @override
  Future<List<TTSVoice>> getAvailableVoices() async {
    try {
      final languages = await _flutterTts.getLanguages;

      if (languages == null || languages.isEmpty) {
        _log.warning('未获取到可用语言列表');
        return [];
      }

      return languages.map((lang) {
        return TTSVoice(
          id: lang.toString(),
          name: lang.toString(),
          language: lang.toString(),
        );
      }).toList();
    } catch (e) {
      _log.warning('获取语音列表失败: $e');
      return [];
    }
  }

  @override
  Future<bool> testConnection() async {
    // 系统TTS始终可用
    return true;
  }

  @override
  Future<void> dispose() async {
    try {
      await _flutterTts.stop();
      _log.info('系统TTS服务已释放');
    } catch (e) {
      _log.warning('释放系统TTS服务失败: $e');
    }
  }
}

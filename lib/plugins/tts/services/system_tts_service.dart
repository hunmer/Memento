import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:universal_platform/universal_platform.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:logging/logging.dart';
import 'tts_base_service.dart';
import 'package:Memento/plugins/tts/models/tts_voice.dart';

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

      // ⚠️ 关键配置：等待语音完成后再返回
      await _flutterTts.awaitSpeakCompletion(true);

      // 平台特定配置
      if (!kIsWeb) {
        if (UniversalPlatform.isIOS) {
          // iOS 特定配置
          await _flutterTts.setSharedInstance(true);
          await _flutterTts.setIosAudioCategory(
            IosTextToSpeechAudioCategory.playback,
            [
              IosTextToSpeechAudioCategoryOptions.allowBluetooth,
              IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
              IosTextToSpeechAudioCategoryOptions.mixWithOthers,
              IosTextToSpeechAudioCategoryOptions.defaultToSpeaker,
            ],
            IosTextToSpeechAudioMode.defaultMode,
          );
        } else if (UniversalPlatform.isAndroid) {
          // Android 特定配置
          try {
            final engines = await _flutterTts.getEngines;
            if (engines != null && engines.isNotEmpty) {
              _log.info('可用 TTS 引擎: $engines');
            }

            // 获取可用语音列表（用于诊断）
            try {
              final voices = await _flutterTts.getVoices;
              if (voices != null && voices.isNotEmpty) {
                _log.info('Android 可用语音数量: ${voices.length}');
                // 记录前几个语音的详细信息
                for (var i = 0; i < voices.length && i < 5; i++) {
                  final voice = voices[i] as Map;
                  _log.info('语音 $i: name=${voice['name']}, locale=${voice['locale']}');
                }
                // 查找中文语音
                final chineseVoices = voices.where((v) {
                  final voice = v as Map;
                  final locale = voice['locale']?.toString() ?? '';
                  return locale.startsWith('zh');
                }).toList();
                if (chineseVoices.isNotEmpty) {
                  _log.info('找到 ${chineseVoices.length} 个中文语音');
                } else {
                  _log.warning('未找到中文语音！可能需要在系统设置中安装中文语音包');
                }
              }
            } catch (e) {
              _log.info('获取语音列表失败，尝试获取语言列表: $e');
              try {
                final languages = await _flutterTts.getLanguages;
                if (languages != null) {
                  _log.info('可用语言: $languages');
                }
              } catch (e2) {
                _log.warning('获取语言列表也失败: $e2');
              }
            }
          } catch (e) {
            _log.warning('获取 Android TTS 引擎失败: $e');
          }
        } else if (UniversalPlatform.isWindows) {
          // Windows 特定配置
          try {
            // Windows 使用 UWP 语音，确保设置默认语言
            final voices = await _flutterTts.getVoices;
            if (voices != null && voices.isNotEmpty) {
              _log.info('Windows 可用语音数量: ${voices.length}');
              // 记录前几个语音的详细信息
              for (var i = 0; i < voices.length && i < 3; i++) {
                final voice = voices[i] as Map;
                _log.info('语音 $i: name=${voice['name']}, locale=${voice['locale']}, gender=${voice['gender']}');
              }
            } else {
              _log.warning('Windows 未检测到可用语音，请安装 Windows 语音包');
            }
          } catch (e) {
            _log.warning('获取 Windows 语音列表失败: $e');
          }
        }
      }

      // 设置参数
      await _flutterTts.setPitch(config.pitch);
      await _flutterTts.setSpeechRate(config.speed);
      await _flutterTts.setVolume(config.volume);

      // 设置语言/语音
      if (config.voice != null && config.voice!.isNotEmpty) {
        await _flutterTts.setLanguage(config.voice!);
      }

      // 设置回调 - 使用 scheduleMicrotask 确保在正确的线程上执行
      _flutterTts.setStartHandler(() {
        scheduleMicrotask(() {
          _log.info('开始朗读');
          _onStart?.call();
        });
      });

      _flutterTts.setCompletionHandler(() {
        scheduleMicrotask(() {
          _log.info('朗读完成');
          _onComplete?.call();
        });
      });

      _flutterTts.setCancelHandler(() {
        scheduleMicrotask(() {
          _log.info('朗读已取消');
        });
      });

      _flutterTts.setPauseHandler(() {
        scheduleMicrotask(() {
          _log.info('朗读已暂停');
        });
      });

      _flutterTts.setContinueHandler(() {
        scheduleMicrotask(() {
          _log.info('朗读已继续');
        });
      });

      _flutterTts.setErrorHandler((msg) {
        scheduleMicrotask(() {
          _log.warning('朗读出错: $msg');
          _onError?.call(msg);
        });
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

      // 确保文本不为空
      if (text.trim().isEmpty) {
        _log.warning('朗读文本为空');
        onError?.call('朗读文本为空');
        return;
      }

      _log.info('朗读文本: ${text.substring(0, text.length > 50 ? 50 : text.length)}...');

      // 每次朗读前重新设置参数（参考官方示例）
      await _flutterTts.setVolume(config.volume);
      await _flutterTts.setSpeechRate(config.speed);
      await _flutterTts.setPitch(config.pitch);

      // 设置语音/语言
      if (config.voice != null && config.voice!.isNotEmpty) {
        if (!kIsWeb && UniversalPlatform.isWindows) {
          // Windows 需要使用 setVoice 方法设置具体的语音
          try {
            await _flutterTts.setVoice({'name': config.voice!, 'locale': config.voice!});
            _log.info('Windows 设置语音: ${config.voice}');
          } catch (e) {
            _log.warning('Windows 设置语音失败，尝试使用 setLanguage: $e');
            await _flutterTts.setLanguage(config.voice!);
          }
        } else if (!kIsWeb && UniversalPlatform.isAndroid) {
          // Android 平台：先尝试使用 setVoice，失败则使用 setLanguage
          _log.info('Android 设置语音: ${config.voice}');

          try {
            // 尝试查找匹配的语音
            final voices = await _flutterTts.getVoices;
            if (voices != null && voices.isNotEmpty) {
              // 查找完全匹配的语音（按 name 或 locale）
              var matchedVoice = voices.firstWhere(
                (v) {
                  final voice = v as Map;
                  final name = voice['name']?.toString() ?? '';
                  final locale = voice['locale']?.toString() ?? '';
                  return name == config.voice || locale == config.voice;
                },
                orElse: () => null,
              );

              // 如果没有完全匹配，尝试前缀匹配（如 zh-CN 匹配 zh-CN-*）
              if (matchedVoice == null && config.voice!.contains('-')) {
                final prefix = config.voice!.split('-').take(2).join('-'); // zh-CN
                matchedVoice = voices.firstWhere(
                  (v) {
                    final voice = v as Map;
                    final locale = voice['locale']?.toString() ?? '';
                    return locale.startsWith(prefix);
                  },
                  orElse: () => null,
                );
              }

              if (matchedVoice != null) {
                final voice = matchedVoice as Map;
                final voiceName = voice['name']?.toString() ?? '';
                final voiceLocale = voice['locale']?.toString() ?? '';

                _log.info('找到匹配的语音: name=$voiceName, locale=$voiceLocale');

                // 使用 setVoice 方法
                await _flutterTts.setVoice({'name': voiceName, 'locale': voiceLocale});
                _log.info('使用 setVoice 设置成功');
              } else {
                _log.warning('未找到匹配的语音，使用 setLanguage');
                final result = await _flutterTts.setLanguage(config.voice!);
                _log.info('setLanguage 返回结果: $result');
              }
            } else {
              // 无法获取语音列表，直接使用 setLanguage
              _log.info('无法获取语音列表，使用 setLanguage');
              final result = await _flutterTts.setLanguage(config.voice!);
              _log.info('setLanguage 返回结果: $result');
            }

            // 验证当前语言设置
            try {
              final currentLang = await _flutterTts.getDefaultVoice;
              _log.info('当前默认语音: $currentLang');
            } catch (e) {
              _log.warning('获取当前语音失败: $e');
            }
          } catch (e) {
            _log.warning('设置语音失败: $e，回退到 setLanguage');
            final result = await _flutterTts.setLanguage(config.voice!);
            _log.info('setLanguage 返回结果: $result');
          }
        } else {
          // 其他平台使用 setLanguage
          _log.info('设置语音/语言: ${config.voice}');
          final result = await _flutterTts.setLanguage(config.voice!);
          _log.info('setLanguage 返回结果: $result');
        }
      }

      // 开始朗读
      final result = await _flutterTts.speak(text);

      if (result == 1) {
        _log.info('朗读请求已发送');
      } else {
        _log.warning('朗读请求失败: $result');
        onError?.call('朗读请求失败: $result');
      }
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
      // 优先尝试获取详细的语音列表（iOS/Android/Windows）
      try {
        final voices = await _flutterTts.getVoices;
        if (voices != null && voices.isNotEmpty) {
          _log.info('获取到 ${voices.length} 个语音');
          // 显式指定类型转换，避免类型推断错误
          final voiceList = <TTSVoice>[];
          for (final voice in voices) {
            try {
              final voiceMap = voice as Map<dynamic, dynamic>;

              // Windows: name, locale, gender, identifier
              // iOS/macOS: name, locale, quality, gender, identifier
              // Android: name, locale, quality, latency, network_required, features

              final name = voiceMap['name']?.toString() ?? voiceMap['locale']?.toString() ?? '';
              final locale = voiceMap['locale']?.toString() ?? '';
              final gender = voiceMap['gender']?.toString();

              // Windows/iOS 使用 name 作为 ID，Android 可能需要用 locale
              final id = name.isNotEmpty ? name : locale;

              if (id.isNotEmpty) {
                voiceList.add(TTSVoice(
                  id: id,
                  name: name,
                  language: locale,
                  gender: gender,
                ));
              }
            } catch (e) {
              _log.warning('解析语音数据失败: $e, voice: $voice');
            }
          }

          if (voiceList.isNotEmpty) {
            return voiceList;
          }
        }
      } catch (e) {
        _log.info('getVoices 不可用，尝试使用 getLanguages: $e');
      }

      // 回退到语言列表
      final languages = await _flutterTts.getLanguages;
      if (languages == null || languages.isEmpty) {
        _log.warning('未获取到可用语言列表');
        return [];
      }

      _log.info('获取到 ${languages.length} 种语言');
      // 显式指定类型转换
      final languageList = <TTSVoice>[];
      for (final lang in languages) {
        final langStr = lang.toString();
        languageList.add(TTSVoice(
          id: langStr,
          name: langStr,
          language: langStr,
        ));
      }
      return languageList;
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

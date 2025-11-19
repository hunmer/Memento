import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'tts_localizations_zh.dart';
import 'tts_localizations_en.dart';

/// TTS插件国际化基类
abstract class TTSLocalizations {
  TTSLocalizations(String locale) : localeName = locale;

  final String localeName;

  static const LocalizationsDelegate<TTSLocalizations> delegate =
      _TTSLocalizationsDelegate();
  /// 插件名称
  String get name;

  /// 服务列表
  String get servicesList;

  /// 添加服务
  String get addService;

  /// 编辑服务
  String get editService;

  /// 删除服务
  String get deleteService;

  /// 服务名称
  String get serviceName;

  /// 服务类型
  String get serviceType;

  /// 系统TTS
  String get systemTts;

  /// HTTP服务
  String get httpService;

  /// 默认服务
  String get defaultService;

  /// 启用
  String get enabled;

  /// 禁用
  String get disabled;

  /// 音调
  String get pitch;

  /// 语速
  String get speed;

  /// 音量
  String get volume;

  /// 语音
  String get voice;

  /// API URL
  String get apiUrl;

  /// 请求头
  String get headers;

  /// 请求体
  String get requestBody;

  /// 测试
  String get test;

  /// 测试成功
  String get testSuccess;

  /// 测试失败
  String get testFailed;

  /// 保存
  String get save;

  /// 取消
  String get cancel;

  /// 确定删除吗?
  String get confirmDelete;

  /// 队列
  String get queue;

  /// 当前朗读
  String get currentReading;

  /// 等待中
  String get waiting;

  /// 清空队列
  String get clearQueue;

  /// 获取本地化实例
  static TTSLocalizations of(BuildContext context) {
    final localizations = Localizations.of<TTSLocalizations>(
      context,
      TTSLocalizations,
    );
    if (localizations == null) {
      throw FlutterError('No TTSLocalizations found in context');
    }
    return localizations;
  }

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = [
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  static const List<Locale> supportedLocales = [
    Locale('zh'),
    Locale('en'),
  ];
}

/// TTS国际化委托
class _TTSLocalizationsDelegate
    extends LocalizationsDelegate<TTSLocalizations> {
  const _TTSLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['zh', 'en'].contains(locale.languageCode);
  }

  @override
  Future<TTSLocalizations> load(Locale locale) {
    return SynchronousFuture<TTSLocalizations>(_loadLocale(locale));
  }

  TTSLocalizations _loadLocale(Locale locale) {
    switch (locale.languageCode) {
      case 'zh':
        return TTSLocalizationsZh(locale.toString());
      case 'en':
        return TTSLocalizationsEn(locale.toString());
      default:
        return TTSLocalizationsZh(locale.toString());
    }
  }

  @override
  bool shouldReload(_TTSLocalizationsDelegate old) => false;
}

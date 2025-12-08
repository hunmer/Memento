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

  /// 加载中
  String get loading;

  /// 设为默认朗读服务
  String get setAsDefaultTTSService;

  /// 音频Base64编码
  String get audioBase64Encoded;

  /// 音频数据是否为Base64编码
  String get audioIsBase64Encoded;

  /// 启用此服务
  String get enableThisService;

  /// 禁用此服务
  String get disableThisService;

  /// 基础配置
  String get basicConfig;

  /// 朗读参数
  String get readingParameters;

  /// HTTP 配置
  String get httpConfig;

  /// 直接返回音频
  String get directAudioReturn;

  /// JSON 包裹
  String get jsonWrapped;

  /// 加载语音列表失败
  String get loadVoiceListFailed;

  /// 请输入API URL
  String get pleaseEnterApiUrl;

  /// URL必须以http://或https://开头
  String get urlMustStartWithHttp;

  /// 配置验证失败，请检查必填项
  String get configValidationFailed;

  /// 保存失败
  String get saveFailed;

  /// 暂无服务
  String get noServicesAvailable;

  /// 设为默认
  String get setAsDefault;

  /// 加载服务失败
  String get loadServicesFailed;

  /// 服务已删除
  String get serviceDeleted;

  /// 删除失败
  String get deleteFailed;

  /// 更新失败
  String get updateFailed;

  /// 已设置为默认服务
  String get setAsDefaultService;

  /// 设置失败
  String get setDefaultFailed;

  /// 服务已添加
  String get serviceAdded;

  /// 添加失败
  String get addFailed;

  /// 服务已更新
  String get serviceUpdated;

  /// 语音测试文本
  String get voiceTestText;

  /// 测试失败
  String get testFailedPrefix;

  /// 刷新
  String get refresh;

  /// 正在加载语音列表
  String get loadingVoiceList;

  /// 共 {count} 个可用语音
  String availableVoiceCount(int count);

  /// 重新加载语音列表
  String get reloadVoiceList;

  /// 根据API要求填写
  String get fillAccordingToApi;

  /// 响应类型
  String get responseType;

  /// 音频字段路径
  String get audioFieldPath;

  /// 音频格式
  String get audioFormat;

  /// 请输入音频字段路径
  String get pleaseEnterAudioFieldPath;

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

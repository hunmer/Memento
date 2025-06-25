import 'package:flutter/material.dart';

class LocalVideoHandlerLocalizations {
  static const String videoFileNotExist = 'videoFileNotExist';
  static const String videoSent = 'videoSent';
  static const String videoProcessingFailed = 'videoProcessingFailed';
  static const String videoSelectionFailed = 'videoSelectionFailed';

  static Map<String, Map<String, String>> _localizedValues = {
    'en': {
      videoFileNotExist: 'Video file does not exist',
      videoSent: 'Video sent',
      videoProcessingFailed: 'Failed to process video: ',
      videoSelectionFailed: 'Failed to select video: ',
    },
    'zh': {
      videoFileNotExist: '视频文件不存在',
      videoSent: '已发送视频',
      videoProcessingFailed: '处理视频失败: ',
      videoSelectionFailed: '选择视频失败: ',
    },
  };

  static String getText(BuildContext context, String key, [String? error]) {
    final locale = Localizations.localeOf(context).languageCode;
    final text =
        _localizedValues[locale]?[key] ?? _localizedValues['en']![key]!;
    return error != null ? text + error : text;
  }
}

import 'package:flutter/material.dart';

class FilePreviewLocalizations {
  static const String fileNotExist = '文件不存在或无法访问';
  static const String filePathError = '文件路径解析错误: ';
  static const String fileInfo = '文件信息';
  static const String fileName = '文件名：';
  static const String filePath = '路径：';
  static const String fileSize = '大小：';
  static const String fileType = '类型：';
  static const String confirm = '确定';
  static const String operationFailed = '操作失败：';
  static const String cannotLoadFile = '无法加载文件';
  static const String imageLoadFailed = '图片加载失败';
  static const String videoLoadFailed = '视频加载失败';
  static const String tryOpenWithOtherApp = '尝试使用其他应用打开';
  static const String shareFailed = '分享失败：';
  static const String videoPlayFailed = '无法播放此视频，可能是格式不支持或文件损坏';

  static Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'fileNotExist': 'File does not exist or cannot be accessed',
      'filePathError': 'File path parsing error: ',
      'fileInfo': 'File Information',
      'fileName': 'Name: ',
      'filePath': 'Path: ',
      'fileSize': 'Size: ',
      'fileType': 'Type: ',
      'confirm': 'OK',
      'operationFailed': 'Operation failed: ',
      'cannotLoadFile': 'Cannot load file',
      'imageLoadFailed': 'Image load failed',
      'videoLoadFailed': 'Video load failed',
      'videoPlayFailed':
          'Cannot play this video, possibly due to unsupported format or corrupted file',
      'tryOpenWithOtherApp': 'Try to open with another app',
      'shareFailed': 'Share failed: ',
    },
    'zh': {
      'fileNotExist': '文件不存在或无法访问',
      'filePathError': '文件路径解析错误: ',
      'fileInfo': '文件信息',
      'fileName': '文件名：',
      'filePath': '路径：',
      'fileSize': '大小：',
      'fileType': '类型：',
      'confirm': '确定',
      'operationFailed': '操作失败：',
      'cannotLoadFile': '无法加载文件',
      'imageLoadFailed': '图片加载失败',
      'videoLoadFailed': '视频加载失败',
      'tryOpenWithOtherApp': '尝试使用其他应用打开',
      'shareFailed': '分享失败：',
      'videoPlayFailed': '无法播放此视频，可能是格式不支持或文件损坏',
    },
  };

  static String get(BuildContext context, String key, [String? param]) {
    final value =
        _localizedValues[Localizations.localeOf(context).languageCode]?[key] ??
        key;
    return param != null ? value + param : value;
  }
}

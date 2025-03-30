import 'package:flutter/foundation.dart';

/// 非Web平台的存储实现
class WebStorage {
  /// 保存数据
  static void saveData(String key, String value) {
    throw UnsupportedError('在非Web平台上请使用文件系统API');
  }

  /// 读取数据
  static String? loadData(String key) {
    throw UnsupportedError('在非Web平台上请使用文件系统API');
  }

  /// 删除数据
  static void removeData(String key) {
    throw UnsupportedError('在非Web平台上请使用文件系统API');
  }

  /// 检查数据是否存在
  static bool hasData(String key) {
    throw UnsupportedError('在非Web平台上请使用文件系统API');
  }

  /// 保存JSON对象
  static void saveJson(String key, dynamic data) {
    throw UnsupportedError('在非Web平台上请使用文件系统API');
  }

  /// 读取JSON对象
  static dynamic loadJson(String key) {
    throw UnsupportedError('在非Web平台上请使用文件系统API');
  }
}

// 导出所有需要的方法
void saveData(String key, String value) => WebStorage.saveData(key, value);
String? loadData(String key) => WebStorage.loadData(key);
void removeData(String key) => WebStorage.removeData(key);
void removeDataByPrefix(String prefix) {
  // 在非Web平台，这个方法不做任何操作，因为文件系统操作由StorageManager处理
  debugPrint('removeDataByPrefix在非Web平台不执行任何操作，请使用文件系统API');
}

bool hasData(String key) => WebStorage.hasData(key);
void saveJson(String key, dynamic data) => WebStorage.saveJson(key, data);
dynamic loadJson(String key) => WebStorage.loadJson(key);

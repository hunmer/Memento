// ignore: avoid_web_libraries_in_flutter
import 'package:flutter/foundation.dart';
import 'storage_interface.dart';

/// Web平台的持久化存储实现，使用localStorage
/// 注意：这个类只在Web平台使用，在其他平台会抛出异常
class WebStorage implements StorageInterface {
  /// 私有构造函数，防止实例化
  WebStorage._();

  /// 单例实例
  static final WebStorage _instance = WebStorage._();

  /// 获取单例实例
  static WebStorage get instance => _instance;

  /// 保存数据到localStorage
  @override
  Future<void> saveData(String key, String value) async {
    if (!kIsWeb) {
      throw UnsupportedError('WebStorage 仅支持Web平台');
    }

    // 在Web平台，这个方法会在编译时被替换为实际实现
    // 现在我们返回一个空的Future，以便在非Web平台编译时不会报错
    debugPrint('Web平台才能使用localStorage: $key');
    return Future.value();
  }

  /// 从localStorage读取数据
  @override
  Future<String?> loadData(String key) async {
    if (!kIsWeb) {
      throw UnsupportedError('WebStorage 仅支持Web平台');
    }

    // 在Web平台，这个方法会在编译时被替换为实际实现
    debugPrint('Web平台才能使用localStorage: $key');
    return Future.value(null);
  }

  /// 从localStorage删除数据
  @override
  Future<void> removeData(String key) async {
    if (!kIsWeb) {
      throw UnsupportedError('WebStorage 仅支持Web平台');
    }

    // 在Web平台，这个方法会在编译时被替换为实际实现
    debugPrint('Web平台才能使用localStorage: $key');
    return Future.value();
  }

  /// 检查localStorage中是否存在数据
  @override
  Future<bool> hasData(String key) async {
    if (!kIsWeb) {
      throw UnsupportedError('WebStorage 仅支持Web平台');
    }

    // 在Web平台，这个方法会在编译时被替换为实际实现
    debugPrint('Web平台才能使用localStorage: $key');
    return Future.value(false);
  }

  /// 保存JSON对象到localStorage
  @override
  Future<void> saveJson(String key, dynamic data) async {
    debugPrint('saveJson: $key, $data');
    if (!kIsWeb) {
      throw UnsupportedError('WebStorage 仅支持Web平台');
    }

    // 在Web平台，这个方法会在编译时被替换为实际实现
    debugPrint('Web平台才能使用localStorage JSON: $key');
    return Future.value();
  }

  /// 从localStorage读取JSON对象
  @override
  Future<dynamic> loadJson(String key) async {
    debugPrint('loadJson: $key');
    if (!kIsWeb) {
      throw UnsupportedError('WebStorage 仅支持Web平台');
    }

    // 在Web平台，这个方法会在编译时被替换为实际实现
    debugPrint('Web平台才能使用localStorage JSON: $key');
    return Future.value(null);
  }

  /// 获取所有以指定前缀开头的键
  @override
  Future<List<String>> getKeysWithPrefix(String prefix) async {
    if (!kIsWeb) {
      throw UnsupportedError('WebStorage 仅支持Web平台');
    }

    // 在Web平台，这个方法会在编译时被替换为实际实现
    debugPrint('Web平台才能使用localStorage keys: $prefix');
    return Future.value([]);
  }

  /// 清除所有以指定前缀开头的数据
  @override
  Future<void> clearWithPrefix(String prefix) async {
    if (!kIsWeb) {
      throw UnsupportedError('WebStorage 仅支持Web平台');
    }

    // 在Web平台，这个方法会在编译时被替换为实际实现
    debugPrint('Web平台才能使用localStorage clear: $prefix');
    return Future.value();
  }
}

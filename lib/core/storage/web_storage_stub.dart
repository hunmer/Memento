import 'package:flutter/foundation.dart';
import 'storage_interface.dart';

/// Web存储的存根实现，用于在非Web平台编译时提供空实现
class WebStorage implements StorageInterface {
  /// 私有构造函数，防止实例化
  WebStorage._();

  /// 单例实例
  static final WebStorage _instance = WebStorage._();

  /// 获取单例实例
  static WebStorage get instance => _instance;

  @override
  Future<void> saveData(String key, String value) async {
    debugPrint('WebStorage stub: saveData 不可用于非Web平台');
    return Future.value();
  }

  @override
  Future<String?> loadData(String key) async {
    debugPrint('WebStorage stub: loadData 不可用于非Web平台');
    return Future.value(null);
  }

  @override
  Future<void> removeData(String key) async {
    debugPrint('WebStorage stub: removeData 不可用于非Web平台');
    return Future.value();
  }

  @override
  Future<bool> hasData(String key) async {
    debugPrint('WebStorage stub: hasData 不可用于非Web平台');
    return Future.value(false);
  }

  @override
  Future<void> saveJson(String key, dynamic data) async {
    debugPrint('WebStorage stub: saveJson 不可用于非Web平台');
    return Future.value();
  }

  @override
  Future<dynamic> loadJson(String key) async {
    debugPrint('WebStorage stub: loadJson 不可用于非Web平台');
    return Future.value(null);
  }

  @override
  Future<List<String>> getKeysWithPrefix(String prefix) async {
    debugPrint('WebStorage stub: getKeysWithPrefix 不可用于非Web平台');
    return Future.value([]);
  }

  @override
  Future<void> clearWithPrefix(String prefix) async {
    debugPrint('WebStorage stub: clearWithPrefix 不可用于非Web平台');
    return Future.value();
  }
}

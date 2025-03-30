/// 模拟 window 对象
class Window {
  final LocalStorage localStorage = LocalStorage();
}

/// 模拟 localStorage 对象
class LocalStorage {
  void operator []=(String key, String value) {
    throw UnsupportedError('LocalStorage 仅支持Web平台');
  }

  String? operator [](String key) {
    throw UnsupportedError('LocalStorage 仅支持Web平台');
  }

  void remove(String key) {
    throw UnsupportedError('LocalStorage 仅支持Web平台');
  }

  bool containsKey(String key) {
    throw UnsupportedError('LocalStorage 仅支持Web平台');
  }

  void forEach(void Function(String key, String value) action) {
    throw UnsupportedError('LocalStorage 仅支持Web平台');
  }
}

/// 提供 window 实例
final window = Window();

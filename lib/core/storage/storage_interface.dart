import 'dart:typed_data';

abstract class StorageInterface {
  Future<void> saveData(String key, String value);
  Future<String?> loadData(String key);
  Future<void> removeData(String key);
  Future<bool> hasData(String key);
  Future<void> saveJson(String key, dynamic data);
  Future<dynamic> loadJson(String key, [dynamic defaultValue]);
  Future<List<String>> getKeysWithPrefix(String prefix);
  Future<void> clearWithPrefix(String prefix);

  Future<void> createDirectory(String path);
  Future<String> readString(String path);
  Future<void> writeString(String path, String content);
  Future<void> deleteFile(String path);

  // 二进制文件读写方法
  Future<Uint8List?> readBytes(String path);
  Future<void> writeBytes(String path, Uint8List bytes);
}

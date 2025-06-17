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
}

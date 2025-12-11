import 'dart:convert';
import 'package:crypto/crypto.dart';

/// MD5 工具类 - 用于数据版本控制
class Md5Utils {
  /// 计算字符串的 MD5
  static String computeString(String input) {
    final bytes = utf8.encode(input);
    final digest = md5.convert(bytes);
    return digest.toString();
  }

  /// 计算 JSON Map 的 MD5
  /// 注意: JSON 会先规范化 (key 排序) 以确保一致性
  static String computeJson(Map<String, dynamic> json) {
    final normalizedJson = _normalizeJson(json);
    final jsonString = jsonEncode(normalizedJson);
    return computeString(jsonString);
  }

  /// 计算字节数组的 MD5
  static String computeBytes(List<int> bytes) {
    final digest = md5.convert(bytes);
    return digest.toString();
  }

  /// 规范化 JSON (递归排序所有 key)
  /// 确保相同数据生成相同的 JSON 字符串
  static dynamic _normalizeJson(dynamic value) {
    if (value is Map<String, dynamic>) {
      final sortedMap = <String, dynamic>{};
      final sortedKeys = value.keys.toList()..sort();
      for (final key in sortedKeys) {
        sortedMap[key] = _normalizeJson(value[key]);
      }
      return sortedMap;
    } else if (value is List) {
      return value.map(_normalizeJson).toList();
    } else {
      return value;
    }
  }

  /// 验证 MD5 是否匹配
  static bool verify(String data, String expectedMd5) {
    return computeString(data) == expectedMd5;
  }

  /// 验证 JSON 的 MD5 是否匹配
  static bool verifyJson(Map<String, dynamic> json, String expectedMd5) {
    return computeJson(json) == expectedMd5;
  }
}

/// 密码哈希工具类
class PasswordHashUtils {
  /// 生成密码哈希 (SHA256)
  /// 注意: 这不是用于加密的密钥，仅用于服务器验证密码
  static String hashPassword(String password, String salt) {
    final combined = '$password$salt';
    final bytes = utf8.encode(combined);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// 验证密码
  static bool verifyPassword(
      String password, String salt, String expectedHash) {
    return hashPassword(password, salt) == expectedHash;
  }

  /// 生成随机 Salt
  static String generateSalt() {
    final random = DateTime.now().microsecondsSinceEpoch.toString();
    final digest = sha256.convert(utf8.encode(random));
    return digest.toString().substring(0, 32);
  }
}

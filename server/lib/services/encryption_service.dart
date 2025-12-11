import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

/// 服务端加密/解密服务 - 使用 AES-256-GCM
///
/// 与客户端 EncryptionService 兼容，用于解密同步的加密数据
/// 服务端需要用户传递的加密密钥才能解密数据
class ServerEncryptionService {
  /// 用户加密密钥缓存 (userId -> encrypter)
  final Map<String, encrypt.Encrypter> _userEncrypters = {};

  /// 用户密钥原始数据 (userId -> base64Key)
  final Map<String, String> _userKeys = {};

  /// 检查用户是否已设置密钥
  bool hasUserKey(String userId) => _userEncrypters.containsKey(userId);

  /// 设置用户的加密密钥
  ///
  /// [userId] 用户ID
  /// [base64Key] Base64 编码的 256-bit 密钥
  void setUserKey(String userId, String base64Key) {
    final keyBytes = base64Decode(base64Key);
    if (keyBytes.length != 32) {
      throw ArgumentError('密钥长度必须为 32 字节 (256-bit)');
    }

    final key = encrypt.Key(Uint8List.fromList(keyBytes));
    final encrypter = encrypt.Encrypter(
      encrypt.AES(key, mode: encrypt.AESMode.gcm),
    );

    _userEncrypters[userId] = encrypter;
    _userKeys[userId] = base64Key;
  }

  /// 获取用户的密钥 (用于持久化)
  String? getUserKey(String userId) => _userKeys[userId];

  /// 移除用户的加密密钥
  void removeUserKey(String userId) {
    _userEncrypters.remove(userId);
    _userKeys.remove(userId);
  }

  /// 解密数据为 JSON
  ///
  /// [userId] 用户ID
  /// [encryptedString] 加密字符串，格式: base64(iv).base64(ciphertext)
  Map<String, dynamic> decryptData(String userId, String encryptedString) {
    final decrypted = decryptString(userId, encryptedString);
    return jsonDecode(decrypted) as Map<String, dynamic>;
  }

  /// 解密数据为字符串
  String decryptString(String userId, String encryptedString) {
    final encrypter = _userEncrypters[userId];
    if (encrypter == null) {
      throw StateError('用户 $userId 的加密密钥未设置');
    }

    final parts = encryptedString.split('.');
    if (parts.length != 2) {
      throw FormatException('无效的加密数据格式，期望: iv.ciphertext');
    }

    final iv = encrypt.IV.fromBase64(parts[0]);
    final encrypted = encrypt.Encrypted.fromBase64(parts[1]);

    return encrypter.decrypt(encrypted, iv: iv);
  }

  /// 加密 JSON 数据
  ///
  /// [userId] 用户ID
  /// [data] 要加密的 JSON 数据
  /// 返回格式: base64(iv).base64(ciphertext)
  String encryptData(String userId, Map<String, dynamic> data) {
    final jsonString = jsonEncode(data);
    return encryptString(userId, jsonString);
  }

  /// 加密字符串
  String encryptString(String userId, String data) {
    final encrypter = _userEncrypters[userId];
    if (encrypter == null) {
      throw StateError('用户 $userId 的加密密钥未设置');
    }

    final iv = encrypt.IV.fromSecureRandom(16);
    final encrypted = encrypter.encrypt(data, iv: iv);

    return '${iv.base64}.${encrypted.base64}';
  }

  /// 计算数据的 MD5 (加密前的原始数据)
  String computeMd5(Map<String, dynamic> data) {
    final normalizedJson = _normalizeJson(data);
    final jsonString = jsonEncode(normalizedJson);
    return md5.convert(utf8.encode(jsonString)).toString();
  }

  /// 计算字符串的 MD5
  String computeStringMd5(String data) {
    return md5.convert(utf8.encode(data)).toString();
  }

  /// 规范化 JSON (递归排序所有 key)
  dynamic _normalizeJson(dynamic value) {
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

  /// 从密码和 Salt 派生密钥 (与客户端兼容)
  ///
  /// 用于客户端传递密码而非密钥的场景（不推荐）
  static String deriveKeyFromPassword(String password, String salt) {
    final hmacSha256 = Hmac(sha256, utf8.encode(salt));

    List<int> key = utf8.encode(password);
    for (var i = 0; i < 10000; i++) {
      final digest = hmacSha256.convert(key);
      key = digest.bytes;
    }

    return base64Encode(key.take(32).toList());
  }
}

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

/// 端到端加密服务 - 使用 AES-256-GCM
///
/// 此服务负责:
/// - 从用户密码派生加密密钥 (PBKDF2)
/// - 加密/解密 JSON 数据
/// - 计算数据 MD5 (用于版本控制)
///
/// 安全说明:
/// - 加密密钥永不发送到服务器
/// - 服务器只存储加密后的密文
/// - 每次加密使用随机 IV
class EncryptionService {
  encrypt.Key? _key;
  encrypt.Encrypter? _encrypter;
  bool _initialized = false;

  /// 是否已初始化
  bool get isInitialized => _initialized;

  /// 获取加密密钥的 Base64 编码
  ///
  /// 用于管理后台配置 API 访问
  /// ⚠️ 警告: 密钥是保护用户数据的唯一凭证，请妥善保管
  String? get encryptionKeyBase64 {
    if (!_initialized || _key == null) {
      return null;
    }
    return _key!.base64;
  }

  /// 从用户密码和 Salt 派生加密密钥 (PBKDF2)
  ///
  /// [password] 用户密码
  /// [salt] 服务器为用户生成的唯一 Salt
  Future<void> initializeFromPassword(String password, String salt) async {
    final keyBytes = _deriveKey(password, salt);
    _key = encrypt.Key(keyBytes);
    _encrypter = encrypt.Encrypter(
      encrypt.AES(_key!, mode: encrypt.AESMode.gcm),
    );
    _initialized = true;
  }

  /// PBKDF2 密钥派生
  ///
  /// 迭代 10000 次 HMAC-SHA256 以增强安全性
  Uint8List _deriveKey(String password, String salt) {
    final hmacSha256 = Hmac(sha256, utf8.encode(salt));

    // 初始密钥材料
    List<int> key = utf8.encode(password);

    // 迭代派生
    for (var i = 0; i < 10000; i++) {
      final digest = hmacSha256.convert(key);
      key = digest.bytes;
    }

    // 返回 256-bit (32 bytes) 密钥
    return Uint8List.fromList(key.take(32).toList());
  }

  /// 加密 JSON 数据
  ///
  /// 返回格式: base64(iv).base64(ciphertext)
  /// 每次加密使用随机 16 字节 IV
  String encryptData(Map<String, dynamic> data) {
    _checkInitialized();

    final jsonString = jsonEncode(data);
    final iv = encrypt.IV.fromSecureRandom(16);

    final encrypted = _encrypter!.encrypt(jsonString, iv: iv);

    // 格式: iv.ciphertext (都是 base64)
    return '${iv.base64}.${encrypted.base64}';
  }

  /// 加密字符串数据
  String encryptString(String data) {
    _checkInitialized();

    final iv = encrypt.IV.fromSecureRandom(16);
    final encrypted = _encrypter!.encrypt(data, iv: iv);

    return '${iv.base64}.${encrypted.base64}';
  }

  /// 解密数据为 JSON
  Map<String, dynamic> decryptData(String encryptedString) {
    _checkInitialized();

    final decrypted = decryptString(encryptedString);
    return jsonDecode(decrypted) as Map<String, dynamic>;
  }

  /// 解密数据为字符串
  String decryptString(String encryptedString) {
    _checkInitialized();

    final parts = encryptedString.split('.');
    if (parts.length != 2) {
      throw FormatException('无效的加密数据格式，期望: iv.ciphertext');
    }

    final iv = encrypt.IV.fromBase64(parts[0]);
    final encrypted = encrypt.Encrypted.fromBase64(parts[1]);

    return _encrypter!.decrypt(encrypted, iv: iv);
  }

  /// 计算原始数据的 MD5 (加密前)
  ///
  /// 用于乐观并发控制和版本比较
  /// JSON 会先规范化 (key 排序) 以确保一致性
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
  ///
  /// 确保相同数据生成相同的 JSON 字符串
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

  /// 验证 MD5 是否匹配
  bool verifyMd5(Map<String, dynamic> data, String expectedMd5) {
    return computeMd5(data) == expectedMd5;
  }

  /// 检查是否已初始化
  void _checkInitialized() {
    if (!_initialized) {
      throw StateError('EncryptionService 未初始化，请先调用 initializeFromPassword()');
    }
  }

  /// 重置服务 (登出时调用)
  void reset() {
    _key = null;
    _encrypter = null;
    _initialized = false;
  }

  /// 生成随机 Salt (用于注册时，通常由服务器生成)
  static String generateSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64Encode(bytes);
  }
}

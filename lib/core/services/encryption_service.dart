import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

import '../storage/storage_manager.dart';

/// 密钥验证文件名
const String _keyVerificationFileName = '.key_verification.json';

/// 密钥本地存储文件名
const String _keyStorageFileName = '.encryption_key.json';

/// 密钥验证文件内容
const String _keyVerificationContent = 'MEMENTO_KEY_VERIFICATION_v1';

/// 端到端加密服务 - 使用 AES-256-GCM
///
/// 此服务负责:
/// - 管理独立的加密密钥（与密码无关）
/// - 加密/解密 JSON 数据
/// - 计算数据 MD5 (用于版本控制)
/// - 创建和验证密钥验证文件
///
/// 安全说明:
/// - 加密密钥是独立生成的随机密钥，与用户密码无关
/// - 加密密钥永不发送到服务器
/// - 服务器只存储加密后的密文
/// - 每次加密使用随机 IV
class EncryptionService {
  encrypt.Key? _key;
  encrypt.Encrypter? _encrypter;
  bool _initialized = false;
  StorageManager? _storage;

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

  /// 获取密钥验证文件名
  String get keyVerificationFileName => _keyVerificationFileName;

  /// 设置存储管理器（用于保存密钥）
  void setStorage(StorageManager storage) {
    _storage = storage;
  }

  /// 从 Base64 字符串初始化密钥
  ///
  /// [keyBase64] Base64 编码的 32 字节密钥
  Future<void> initializeFromKey(String keyBase64) async {
    final keyBytes = base64Decode(keyBase64);
    if (keyBytes.length != 32) {
      throw ArgumentError('密钥长度必须为 32 字节 (256-bit)');
    }
    _key = encrypt.Key(keyBytes);
    _encrypter = encrypt.Encrypter(
      encrypt.AES(_key!, mode: encrypt.AESMode.gcm),
    );
    _initialized = true;
  }

  /// 从本地存储加载密钥
  ///
  /// 如果密钥不存在，返回 false
  Future<bool> loadKeyFromStorage() async {
    if (_storage == null) {
      throw StateError('存储管理器未设置，请先调用 setStorage()');
    }

    final content = await _storage!.readString(_keyStorageFileName);
    if (content == null) {
      return false;
    }

    try {
      final data = jsonDecode(content) as Map<String, dynamic>;
      final keyBase64 = data['key'] as String?;
      if (keyBase64 == null) {
        return false;
      }
      await initializeFromKey(keyBase64);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 保存密钥到本地存储
  Future<void> saveKeyToStorage() async {
    if (_storage == null) {
      throw StateError('存储管理器未设置，请先调用 setStorage()');
    }
    if (!_initialized || _key == null) {
      throw StateError('密钥未初始化');
    }

    final data = {
      'key': _key!.base64,
      'created_at': DateTime.now().toIso8601String(),
    };
    await _storage!.writeString(_keyStorageFileName, jsonEncode(data));
  }

  /// 生成新的随机密钥并初始化
  ///
  /// 生成后会自动保存到本地存储
  Future<void> generateNewKey() async {
    final random = Random.secure();
    final keyBytes = Uint8List.fromList(
      List<int>.generate(32, (_) => random.nextInt(256)),
    );
    _key = encrypt.Key(keyBytes);
    _encrypter = encrypt.Encrypter(
      encrypt.AES(_key!, mode: encrypt.AESMode.gcm),
    );
    _initialized = true;

    // 保存到本地存储
    await saveKeyToStorage();
  }

  /// 刷新密钥（生成新密钥）
  ///
  /// ⚠️ 警告: 此操作会使所有旧密钥加密的数据无法解密
  /// 调用此方法后需要重新加密所有数据
  Future<String> refreshKey() async {
    await generateNewKey();
    return _key!.base64;
  }

  /// 创建密钥验证文件内容
  ///
  /// 返回加密后的验证文件内容，用于保存到本地并同步到服务器
  Map<String, dynamic> createKeyVerificationData() {
    _checkInitialized();

    final verificationData = {
      'content': _keyVerificationContent,
      'created_at': DateTime.now().toIso8601String(),
    };

    final encryptedData = encryptData(verificationData);
    final md5Hash = computeMd5(verificationData);

    return {
      'encrypted_data': encryptedData,
      'md5': md5Hash,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  /// 验证密钥验证文件
  ///
  /// [encryptedData] 加密的验证文件数据
  /// 返回是否验证成功
  bool verifyKeyVerificationData(String encryptedData) {
    _checkInitialized();

    try {
      final decryptedData = decryptData(encryptedData);
      final content = decryptedData['content'] as String?;
      return content == _keyVerificationContent;
    } catch (e) {
      return false;
    }
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
      throw StateError('EncryptionService 未初始化，请先初始化密钥');
    }
  }

  /// 重置服务 (登出时调用)
  void reset() {
    _key = null;
    _encrypter = null;
    _initialized = false;
  }

  /// 生成随机 Base64 密钥（静态方法，用于外部使用）
  static String generateRandomKeyBase64() {
    final random = Random.secure();
    final keyBytes = Uint8List.fromList(
      List<int>.generate(32, (_) => random.nextInt(256)),
    );
    return base64Encode(keyBytes);
  }
}

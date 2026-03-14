import 'dart:convert';
import 'dart:io';

import 'package:uuid/uuid.dart';

/// API Key 过期选项
enum ApiKeyExpiry {
  sevenDays,
  thirtyDays,
  ninetyDays,
  oneYear,
  never,
}

/// API Key 过期选项扩展
extension ApiKeyExpiryExtension on ApiKeyExpiry {
  /// 获取显示名称
  String get displayName {
    switch (this) {
      case ApiKeyExpiry.sevenDays:
        return '7天';
      case ApiKeyExpiry.thirtyDays:
        return '30天';
      case ApiKeyExpiry.ninetyDays:
        return '90天';
      case ApiKeyExpiry.oneYear:
        return '1年';
      case ApiKeyExpiry.never:
        return '永不过期';
    }
  }

  /// 获取过期时间
  DateTime? getExpiresAt() {
    final now = DateTime.now();
    switch (this) {
      case ApiKeyExpiry.sevenDays:
        return now.add(const Duration(days: 7));
      case ApiKeyExpiry.thirtyDays:
        return now.add(const Duration(days: 30));
      case ApiKeyExpiry.ninetyDays:
        return now.add(const Duration(days: 90));
      case ApiKeyExpiry.oneYear:
        return now.add(const Duration(days: 365));
      case ApiKeyExpiry.never:
        return null;
    }
  }
}

/// API Key 数据模型
class ApiKey {
  /// 唯一标识符
  final String id;

  /// 所属用户 ID
  final String userId;

  /// API Key 名称
  final String name;

  /// API Key 值 (mk_ 前缀 + 32 字符)
  final String key;

  /// 关联的加密密钥 (Base64)
  final String encryptionKey;

  /// 创建时间
  final DateTime createdAt;

  /// 最后使用时间
  final DateTime? lastUsedAt;

  /// 过期时间 (null 表示永不过期)
  final DateTime? expiresAt;

  ApiKey({
    required this.id,
    required this.userId,
    required this.name,
    required this.key,
    required this.encryptionKey,
    required this.createdAt,
    this.lastUsedAt,
    this.expiresAt,
  });

  /// 检查是否已过期
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// 生成新的 API Key
  static ApiKey generate({
    required String userId,
    required String name,
    required String encryptionKey,
    ApiKeyExpiry expiry = ApiKeyExpiry.never,
  }) {
    const uuid = Uuid();
    final id = 'key_${uuid.v4().substring(0, 8)}';
    // 生成 mk_live_ 前缀 + 32 字符随机字符串
    final keyValue = 'mk_live_${uuid.v4().replaceAll('-', '')}';

    return ApiKey(
      id: id,
      userId: userId,
      name: name,
      key: keyValue,
      encryptionKey: encryptionKey,
      createdAt: DateTime.now(),
      expiresAt: expiry.getExpiresAt(),
    );
  }

  /// 从 JSON 创建
  factory ApiKey.fromJson(Map<String, dynamic> json) {
    return ApiKey(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      key: json['key'] as String,
      encryptionKey: json['encryption_key'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      lastUsedAt: json['last_used_at'] != null
          ? DateTime.parse(json['last_used_at'] as String)
          : null,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'key': key,
      'encryption_key': encryptionKey,
      'created_at': createdAt.toIso8601String(),
      'last_used_at': lastUsedAt?.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
      'is_expired': isExpired,
    };
  }

  /// 复制并更新
  ApiKey copyWith({
    String? id,
    String? userId,
    String? name,
    String? key,
    String? encryptionKey,
    DateTime? createdAt,
    DateTime? lastUsedAt,
    DateTime? expiresAt,
  }) {
    return ApiKey(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      key: key ?? this.key,
      encryptionKey: encryptionKey ?? this.encryptionKey,
      createdAt: createdAt ?? this.createdAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  /// 转换为安全的 JSON（不包含敏感信息）
  Map<String, dynamic> toSafeJson() {
    return {
      'id': id,
      'name': name,
      'created_at': createdAt.toIso8601String(),
      'last_used_at': lastUsedAt?.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
      'is_expired': isExpired,
      // 不返回完整的 key，只返回前缀和后4位
      'key_prefix': '${key.substring(0, 8)}...${key.substring(key.length - 4)}',
    };
  }

  @override
  String toString() {
    return 'ApiKey(id: $id, userId: $userId, name: $name)';
  }
}

/// API Key 存储管理
class ApiKeyStore {
  final String _dataDir;

  ApiKeyStore(this._dataDir);

  /// 获取 API Keys 文件路径
  String get _apiKeysPath => '$_dataDir/auth/api_keys.json';

  /// 读取所有 API Keys
  Future<Map<String, ApiKey>> loadAllKeys() async {
    final file = await _getKeysFile();
    if (!await file.exists()) {
      return {};
    }

    try {
      final content = await file.readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;
      final keys = data['api_keys'] as Map<String, dynamic>? ?? {};

      final result = <String, ApiKey>{};
      for (final entry in keys.entries) {
        final key = ApiKey.fromJson(entry.value as Map<String, dynamic>);
        result[key.key] = key; // 使用 key 值作为索引，便于快速查找
      }
      return result;
    } catch (e) {
      print('加载 API Keys 失败: $e');
      return {};
    }
  }

  /// 根据 key 值查找
  Future<ApiKey?> findByKey(String keyValue) async {
    final keys = await loadAllKeys();
    return keys[keyValue];
  }

  /// 获取用户的所有 API Keys
  Future<List<ApiKey>> findByUserId(String userId) async {
    final keys = await loadAllKeys();
    return keys.values.where((k) => k.userId == userId).toList();
  }

  /// 保存 API Key
  Future<void> saveKey(ApiKey apiKey) async {
    final file = await _getKeysFile();
    Map<String, dynamic> data = {'api_keys': <String, dynamic>{}};

    if (await file.exists()) {
      try {
        final content = await file.readAsString();
        data = jsonDecode(content) as Map<String, dynamic>;
        data['api_keys'] ??= <String, dynamic>{};
      } catch (e) {
        // 忽略解析错误，使用默认值
      }
    }

    (data['api_keys'] as Map<String, dynamic>)[apiKey.id] = apiKey.toJson();
    data['updated_at'] = DateTime.now().toIso8601String();

    await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(data));
  }

  /// 删除 API Key
  Future<bool> deleteKey(String keyId) async {
    final file = await _getKeysFile();
    if (!await file.exists()) return false;

    try {
      final content = await file.readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;
      final keys = data['api_keys'] as Map<String, dynamic>? ?? {};

      // 根据 ID 查找并删除
      String? keyToDelete;
      for (final entry in keys.entries) {
        final keyData = entry.value as Map<String, dynamic>;
        if (keyData['id'] == keyId) {
          keyToDelete = entry.key;
          break;
        }
      }

      if (keyToDelete != null) {
        keys.remove(keyToDelete);
        data['api_keys'] = keys;
        data['updated_at'] = DateTime.now().toIso8601String();
        await file.writeAsString(
            const JsonEncoder.withIndent('  ').convert(data));
        return true;
      }
      return false;
    } catch (e) {
      print('删除 API Key 失败: $e');
      return false;
    }
  }

  /// 更新最后使用时间
  Future<void> updateLastUsed(String keyValue) async {
    final file = await _getKeysFile();
    if (!await file.exists()) return;

    try {
      final content = await file.readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;
      final keys = data['api_keys'] as Map<String, dynamic>? ?? {};

      for (final entry in keys.entries) {
        final keyData = entry.value as Map<String, dynamic>;
        if (keyData['key'] == keyValue) {
          keyData['last_used_at'] = DateTime.now().toIso8601String();
          break;
        }
      }

      data['updated_at'] = DateTime.now().toIso8601String();
      await file.writeAsString(
          const JsonEncoder.withIndent('  ').convert(data));
    } catch (e) {
      print('更新 API Key 使用时间失败: $e');
    }
  }

  /// 获取 API Keys 文件
  Future<dynamic> _getKeysFile() async {
    final file = await File(_apiKeysPath).create(recursive: true);
    return file;
  }
}

import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

/// API 转发配置
class ApiForwardingConfig {
  static const String _keyEnabled = 'api_forwarding_enabled';
  static const String _keyServerUrl = 'api_forwarding_server_url';
  static const String _keyPairingKey = 'api_forwarding_pairing_key';
  static const String _keyDeviceName = 'api_forwarding_device_name';
  static const String _keyAutoConnect = 'api_forwarding_auto_connect';

  final bool enabled;
  final bool autoConnect;
  final String serverUrl;
  final String pairingKey;
  final String deviceName;

  const ApiForwardingConfig({
    this.enabled = false,
    this.autoConnect = false,
    this.serverUrl = 'ws://localhost:8654',
    this.pairingKey = 'ABCD-1234-EFGH-5678',
    this.deviceName = 'Memento Client',
  });

  /// 从 SharedPreferences 加载配置
  static Future<ApiForwardingConfig> load() async {
    final prefs = await SharedPreferences.getInstance();
    return ApiForwardingConfig(
      enabled: prefs.getBool(_keyEnabled) ?? false,
      autoConnect: prefs.getBool(_keyAutoConnect) ?? false,
      serverUrl: prefs.getString(_keyServerUrl) ?? '',
      pairingKey: prefs.getString(_keyPairingKey) ?? '',
      deviceName: prefs.getString(_keyDeviceName) ?? 'Memento Client',
    );
  }

  /// 保存配置
  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEnabled, enabled);
    await prefs.setBool(_keyAutoConnect, autoConnect);
    await prefs.setString(_keyServerUrl, serverUrl);
    await prefs.setString(_keyPairingKey, pairingKey);
    await prefs.setString(_keyDeviceName, deviceName);
  }

  /// 清除配置
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyEnabled);
    await prefs.remove(_keyAutoConnect);
    await prefs.remove(_keyServerUrl);
    await prefs.remove(_keyPairingKey);
    await prefs.remove(_keyDeviceName);
  }

  /// 复制并修改配置
  ApiForwardingConfig copyWith({
    bool? enabled,
    bool? autoConnect,
    String? serverUrl,
    String? pairingKey,
    String? deviceName,
  }) {
    return ApiForwardingConfig(
      enabled: enabled ?? this.enabled,
      autoConnect: autoConnect ?? this.autoConnect,
      serverUrl: serverUrl ?? this.serverUrl,
      pairingKey: pairingKey ?? this.pairingKey,
      deviceName: deviceName ?? this.deviceName,
    );
  }

  /// 验证配置是否有效
  bool get isValid {
    return enabled &&
        serverUrl.isNotEmpty &&
        pairingKey.isNotEmpty &&
        Uri.tryParse(serverUrl) != null;
  }

  /// 生成新的配对密钥
  static String generatePairingKey() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // 排除易混淆字符
    final random = Random.secure();
    final segments = <String>[];

    for (int i = 0; i < 4; i++) {
      final segment = StringBuffer();
      for (int j = 0; j < 4; j++) {
        segment.write(chars[random.nextInt(chars.length)]);
      }
      segments.add(segment.toString());
    }

    return segments.join('-');
  }

  @override
  String toString() {
    final maskedKey =
        pairingKey.isNotEmpty ? '${pairingKey.substring(0, 7)}...' : 'empty';
    return 'ApiForwardingConfig(enabled: $enabled, serverUrl: $serverUrl, pairingKey: $maskedKey, deviceName: $deviceName)';
  }
}

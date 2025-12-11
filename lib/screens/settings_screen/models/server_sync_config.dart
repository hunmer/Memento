import 'package:shared_preferences/shared_preferences.dart';

/// 服务器同步配置
class ServerSyncConfig {
  static const String _keyServer = 'sync_server';
  static const String _keyUsername = 'sync_username';
  static const String _keyPassword = 'sync_password';
  static const String _keyDeviceId = 'sync_device_id';
  static const String _keyDeviceName = 'sync_device_name';
  static const String _keyAutoSync = 'sync_auto_enabled';
  static const String _keySyncInterval = 'sync_interval';
  static const String _keySyncOnChange = 'sync_on_change';
  static const String _keyToken = 'sync_token';
  static const String _keyUserId = 'sync_user_id';
  static const String _keySalt = 'sync_salt';
  static const String _keySyncDirs = 'sync_dirs';

  String server;
  String username;
  String password;
  String deviceId;
  String deviceName;
  bool autoSync;
  int syncInterval; // 分钟
  bool syncOnChange;
  String? token;
  String? userId;
  String? salt;
  List<String> syncDirs;

  ServerSyncConfig({
    required this.server,
    required this.username,
    required this.password,
    this.deviceId = '',
    this.deviceName = '',
    this.autoSync = false,
    this.syncInterval = 30,
    this.syncOnChange = true,
    this.token,
    this.userId,
    this.salt,
    List<String>? syncDirs,
  }) : syncDirs = syncDirs ??
            [
              'diary',
              'chat',
              'notes',
              'todo',
              'activity',
              'bill',
              'tracker',
              'goods',
              'contact',
              'habits',
              'checkin'
            ];

  /// 从 SharedPreferences 加载配置
  static Future<ServerSyncConfig> load() async {
    final prefs = await SharedPreferences.getInstance();
    return ServerSyncConfig(
      server: prefs.getString(_keyServer) ?? '',
      username: prefs.getString(_keyUsername) ?? '',
      password: prefs.getString(_keyPassword) ?? '',
      deviceId: prefs.getString(_keyDeviceId) ?? '',
      deviceName: prefs.getString(_keyDeviceName) ?? '',
      autoSync: prefs.getBool(_keyAutoSync) ?? false,
      syncInterval: prefs.getInt(_keySyncInterval) ?? 30,
      syncOnChange: prefs.getBool(_keySyncOnChange) ?? true,
      token: prefs.getString(_keyToken),
      userId: prefs.getString(_keyUserId),
      salt: prefs.getString(_keySalt),
      syncDirs: prefs.getStringList(_keySyncDirs),
    );
  }

  /// 保存配置到 SharedPreferences
  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyServer, server);
    await prefs.setString(_keyUsername, username);
    await prefs.setString(_keyPassword, password);
    await prefs.setString(_keyDeviceId, deviceId);
    await prefs.setString(_keyDeviceName, deviceName);
    await prefs.setBool(_keyAutoSync, autoSync);
    await prefs.setInt(_keySyncInterval, syncInterval);
    await prefs.setBool(_keySyncOnChange, syncOnChange);
    await prefs.setStringList(_keySyncDirs, syncDirs);
    if (token != null) {
      await prefs.setString(_keyToken, token!);
    }
    if (userId != null) {
      await prefs.setString(_keyUserId, userId!);
    }
    if (salt != null) {
      await prefs.setString(_keySalt, salt!);
    }
  }

  /// 保存认证信息
  Future<void> saveAuthInfo({
    required String token,
    required String userId,
    required String salt,
  }) async {
    this.token = token;
    this.userId = userId;
    this.salt = salt;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
    await prefs.setString(_keyUserId, userId);
    await prefs.setString(_keySalt, salt);
  }

  /// 清除认证信息
  Future<void> clearAuthInfo() async {
    token = null;
    userId = null;
    salt = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyUserId);
    await prefs.remove(_keySalt);
  }

  /// 清除所有配置
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyServer);
    await prefs.remove(_keyUsername);
    await prefs.remove(_keyPassword);
    await prefs.remove(_keyDeviceId);
    await prefs.remove(_keyDeviceName);
    await prefs.remove(_keyAutoSync);
    await prefs.remove(_keySyncInterval);
    await prefs.remove(_keySyncOnChange);
    await prefs.remove(_keyToken);
    await prefs.remove(_keyUserId);
    await prefs.remove(_keySalt);
    await prefs.remove(_keySyncDirs);
  }

  /// 检查配置是否完整
  bool get isComplete {
    return server.isNotEmpty && username.isNotEmpty && password.isNotEmpty;
  }

  /// 是否已登录
  bool get isLoggedIn {
    return token != null && userId != null && salt != null;
  }

  /// 创建副本
  ServerSyncConfig copyWith({
    String? server,
    String? username,
    String? password,
    String? deviceId,
    String? deviceName,
    bool? autoSync,
    int? syncInterval,
    bool? syncOnChange,
    String? token,
    String? userId,
    String? salt,
    List<String>? syncDirs,
  }) {
    return ServerSyncConfig(
      server: server ?? this.server,
      username: username ?? this.username,
      password: password ?? this.password,
      deviceId: deviceId ?? this.deviceId,
      deviceName: deviceName ?? this.deviceName,
      autoSync: autoSync ?? this.autoSync,
      syncInterval: syncInterval ?? this.syncInterval,
      syncOnChange: syncOnChange ?? this.syncOnChange,
      token: token ?? this.token,
      userId: userId ?? this.userId,
      salt: salt ?? this.salt,
      syncDirs: syncDirs ?? List.from(this.syncDirs),
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'server': server,
      'username': username,
      'device_id': deviceId,
      'device_name': deviceName,
      'auto_sync': autoSync,
      'sync_interval': syncInterval,
      'sync_on_change': syncOnChange,
      'is_logged_in': isLoggedIn,
      'sync_dirs': syncDirs,
    };
  }

  /// 可用的同步目录列表
  static const List<String> availableSyncDirs = [
    'diary',
    'chat',
    'notes',
    'todo',
    'activity',
    'bill',
    'tracker',
    'goods',
    'contact',
    'habits',
    'checkin',
    'calendar',
    'day',
    'database',
    'nodes',
  ];
}

import 'package:shared_preferences/shared_preferences.dart';

class WebDAVConfig {
  static const String _keyServer = 'webdav_server';
  static const String _keyUsername = 'webdav_username';
  static const String _keyPassword = 'webdav_password';

  String server;
  String username;
  String password;

  WebDAVConfig({
    required this.server,
    required this.username,
    required this.password,
  });

  // 从SharedPreferences加载配置
  static Future<WebDAVConfig> load() async {
    final prefs = await SharedPreferences.getInstance();
    return WebDAVConfig(
      server: prefs.getString(_keyServer) ?? '',
      username: prefs.getString(_keyUsername) ?? '',
      password: prefs.getString(_keyPassword) ?? '',
    );
  }

  // 保存配置到SharedPreferences
  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyServer, server);
    await prefs.setString(_keyUsername, username);
    await prefs.setString(_keyPassword, password);
  }

  // 清除配置
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyServer);
    await prefs.remove(_keyUsername);
    await prefs.remove(_keyPassword);
  }

  // 检查配置是否完整
  bool get isComplete {
    return server.isNotEmpty && username.isNotEmpty && password.isNotEmpty;
  }

  // 创建一个副本
  WebDAVConfig copyWith({String? server, String? username, String? password}) {
    return WebDAVConfig(
      server: server ?? this.server,
      username: username ?? this.username,
      password: password ?? this.password,
    );
  }
}

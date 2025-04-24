import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import '../models/user.dart';
import '../chat_plugin.dart';

/// 负责管理用户相关的功能
class UserService {
  final ChatPlugin _plugin;

  // 当前用户
  User? _currentUser;
  User get currentUser {
    if (_currentUser == null) {
      // 创建一个默认用户，避免抛出异常
      _currentUser = User(id: 'default_user', username: 'Default User');
      debugPrint(
        'Warning: Using default user because ChatPlugin is not properly initialized.',
      );
    }
    return _currentUser!;
  }

  // 用于存储用户头像信息的Map
  final Map<String, String> _userAvatars = {};

  UserService(this._plugin);

  Future<void> initialize() async {
    // 确保头像目录存在
    await _plugin.storage.createDirectory('chat/avatars');

    // 设置默认用户（如果尚未设置）
    if (_currentUser == null) {
      // 尝试从存储中加载用户信息
      final userData = await _plugin.storage.read('chat/current_user');
      if (userData.isNotEmpty && userData.containsKey('user')) {
        _currentUser = User.fromJson(userData['user'] as Map<String, dynamic>);
      } else {
        // 如果没有存储的用户信息，创建默认用户
        _currentUser = User(id: 'default_user', username: 'Default User');
        // 保存默认用户信息
        await _plugin.storage.write('chat/current_user', {
          'user': _currentUser!.toJson(),
        });
      }
    }

    // 加载用户头像信息
    await _loadAvatars();
  }

  // 设置当前用户
  void setCurrentUser(User user) {
    _currentUser = user;
    _plugin.notifyListeners();
  }

  // 加载所有用户头像
  Future<void> _loadAvatars() async {
    try {
      if (kIsWeb) {
        // Web平台暂不支持列出目录文件
        debugPrint('Avatar loading not fully supported on Web platform');
        return;
      }

      // 获取应用文档目录
      final appDir = await getApplicationDocumentsDirectory();
      final avatarsDir = Directory(
        path.join(appDir.path, 'app_data/chat/avatars'),
      );

      // 检查目录是否存在
      if (!await avatarsDir.exists()) {
        await _plugin.storage.createDirectory('chat/avatars');
        debugPrint('Created avatars directory');
        return; // 目录刚创建，还没有文件
      }

      // 列出目录中的所有文件
      final avatarFiles = avatarsDir.listSync();
      for (var entity in avatarFiles) {
        if (entity is File) {
          final fileName = path.basename(entity.path);
          if (fileName.endsWith('.jpg')) {
            final username = fileName.substring(0, fileName.length - 4);
            _userAvatars[username] = './chat/avatars/$fileName';
          }
        }
      }
      debugPrint('Loaded ${_userAvatars.length} user avatars');
    } catch (e) {
      debugPrint('Error loading avatars: $e');
    }
  }

  // 获取用户头像路径
  String? getUserAvatar(String username) {
    return _userAvatars[username];
  }

  // 设置用户头像
  Future<void> setUserAvatar(String username, String avatarPath) async {
    _userAvatars[username] = avatarPath;
    _plugin.notifyListeners();
  }

  // 更新用户信息，包括头像
  Future<void> updateCurrentUser({String? username, String? avatarPath}) async {
    if (username != null || avatarPath != null) {
      final updatedUser = User(
        id: _currentUser!.id,
        username: username ?? _currentUser!.username,
        iconPath: avatarPath ?? _currentUser!.iconPath,
      );
      _currentUser = updatedUser;

      // 保存更新后的用户信息
      await _plugin.storage.write('chat/current_user', {
        'user': _currentUser!.toJson(),
      });

      // 如果更新了头像，同时更新头像映射
      if (avatarPath != null) {
        await setUserAvatar(_currentUser!.username, avatarPath);
      }

      _plugin.notifyListeners();
    }
  }

  // 获取头像的绝对路径
  Future<String> getAvatarPath(String relativePath) async {
    final appDir = await getApplicationDocumentsDirectory();
    return path.join(
      appDir.path,
      'app_data',
      relativePath.replaceFirst('./', ''),
    );
  }
}

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

    // 确保头像目录存在
    await _plugin.storage.createDirectory('chat/avatars');
  }

  // 设置当前用户
  void setCurrentUser(User user) {
    _currentUser = user;
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

      _plugin.notifyListeners();
    }
  }
  
  /// 更新任意用户信息
  Future<void> updateUser(User user) async {
    // 如果是当前用户，则使用updateCurrentUser方法
    if (user.id == _currentUser?.id) {
      await updateCurrentUser(
        username: user.username,
        avatarPath: user.iconPath,
      );
      return;
    }
    
    // 通知监听器更新
    _plugin.notifyListeners();
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

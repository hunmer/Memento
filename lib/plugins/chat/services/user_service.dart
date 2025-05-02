import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import '../models/user.dart';
import '../chat_plugin.dart';

/// 负责管理用户相关的功能
class UserService {
  final ChatPlugin _plugin;

  // 所有用户列表
  final List<User> _users = [];
  
  // 当前用户
  User? _currentUser;
  User get currentUser {
    return _currentUser!;
  }
  
  /// 获取默认用户
  User _getDefaultUser() {
    return _getUserById('default_user') ?? 
      User(id: 'default_user', username: 'Default User');
  }
  
  /// 根据ID获取用户
  User? _getUserById(String id) {
    try {
      return _users.firstWhere((user) => user.id == id);
    } catch (e) {
      return null;
    }
  }
  
  /// 获取所有用户列表
  List<User> getAllUsers() {
    return List.from(_users);
  }
  
  /// 添加或更新用户
  void _addOrUpdateUser(User user) {
    final index = _users.indexWhere((u) => u.id == user.id);
    if (index >= 0) {
      _users[index] = user;
    } else {
      _users.add(user);
    }
  }


  UserService(this._plugin);

  Future<void> initialize() async {
    // 确保头像目录存在
    await _plugin.storage.createDirectory('chat/avatars');
      // 尝试从存储中加载用户信息
      final userData = await _plugin.storage.read('chat/users', {
        'users': [
          {
            'id': 'default_user',
            'username': 'Default User',
          }
        ]
      });
      
      // 加载所有用户信息
      final usersList = userData['users'] as List<dynamic>;
      for (var userJson in usersList) {
        final user = User.fromJson(userJson as Map<String, dynamic>);
        _addOrUpdateUser(user);
      }
      
      // 设置当前用户为默认用户
      _currentUser = _getDefaultUser();
  }

  // 设置当前用户
  void setCurrentUser(User user) {
    _currentUser = user;
    // 确保用户存在于用户列表中
    _addOrUpdateUser(user);
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

      // 更新用户列表中的用户信息
      _addOrUpdateUser(_currentUser!);
      
      // 保存所有用户信息
      await _saveAllUsers();

      _plugin.notifyListeners();
    }
  }
  
  // 保存所有用户信息到存储
  Future<void> _saveAllUsers() async {
    await _plugin.storage.write('chat/users', {
      'users': _users.map((user) => user.toJson()).toList(),
    });
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
    
    // 更新用户列表中的用户信息
    _addOrUpdateUser(user);
    
    // 保存所有用户信息
    await _saveAllUsers();
    
    // 通知监听器更新
    _plugin.notifyListeners();
  }
}

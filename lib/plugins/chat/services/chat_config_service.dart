import 'package:flutter/foundation.dart';
import 'package:Memento/core/event/event_manager.dart';
import 'package:Memento/plugins/chat/events/user_events.dart';
import 'package:Memento/plugins/chat/models/user.dart';
import 'package:Memento/plugins/chat/chat_plugin.dart';

/// 聊天配置服务
///
/// 职责：统一管理用户和设置的配置
/// - 用户管理（当前用户、用户列表）
/// - 插件设置（头像显示、声音等）
/// - 配置持久化
class ChatConfigService {
  final ChatPlugin _plugin;

  // ==================== 用户管理 ====================

  final List<User> _users = [];
  User? _currentUser;

  User get currentUser {
    return _currentUser!;
  }

  // ==================== 设置管理 ====================

  bool _showAvatarInChat = true;
  bool _showAvatarInTimeline = true;
  bool _playSoundOnSend = true;
  bool _timelineIsGridView = false;

  bool get showAvatarInChat => _showAvatarInChat;
  bool get showAvatarInTimeline => _showAvatarInTimeline;
  bool get playSoundOnSend => _playSoundOnSend;
  bool get timelineIsGridView => _timelineIsGridView;

  ChatConfigService(this._plugin);

  // ==================== 初始化 ====================

  Future<void> initialize() async {
    await _initializeUsers();
    await _initializeSettings();
  }

  Future<void> _initializeUsers() async {
    // 确保头像目录存在
    await _plugin.storage.createDirectory('chat/avatars');

    // 从存储中加载用户信息
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

  Future<void> _initializeSettings() async {
    try {
      final settings = await _plugin.storage.read('chat/settings');
      _showAvatarInChat = settings['showAvatarInChat'] ?? true;
      _showAvatarInTimeline = settings['showAvatarInTimeline'] ?? true;
      _playSoundOnSend = settings['playSoundOnSend'] ?? true;
      _timelineIsGridView = settings['timelineIsGridView'] ?? false;
    } catch (e) {
      debugPrint('Error loading chat settings: $e');
      _showAvatarInChat = true;
      _showAvatarInTimeline = true;
      _playSoundOnSend = true;
      _timelineIsGridView = false;
    }
  }

  // ==================== 用户操作 ====================

  User _getDefaultUser() {
    return _getUserById('default_user') ??
      User(id: 'default_user', username: 'Default User');
  }

  User? _getUserById(String id) {
    try {
      return _users.firstWhere((user) => user.id == id);
    } catch (e) {
      return null;
    }
  }

  List<User> getAllUsers() {
    return List.from(_users);
  }

  void _addOrUpdateUser(User user) {
    final index = _users.indexWhere((u) => u.id == user.id);
    if (index >= 0) {
      _users[index] = user;
    } else {
      _users.add(user);
    }
  }

  void setCurrentUser(User user) {
    _currentUser = user;
    _addOrUpdateUser(user);
    _plugin.refresh();
  }

  Future<void> _saveAllUsers() async {
    await _plugin.storage.write('chat/users', {
      'users': _users.map((user) => user.toJson()).toList(),
    });
  }

  Future<void> updateUser(User user) async {
    if (user.id == _currentUser?.id) {
      _currentUser = user;
    }

    _addOrUpdateUser(user);
    await _saveAllUsers();

    EventManager.instance.broadcast(
      UserEventNames.userAvatarUpdated,
      UserAvatarUpdatedEventArgs(user)
    );

    _plugin.refresh();
  }

  // ==================== 设置操作 ====================

  Future<void> setPlaySoundOnSend(bool value) async {
    _playSoundOnSend = value;
    await _saveSettings();
    _plugin.refresh();
  }

  Future<void> setShowAvatarInChat(bool value) async {
    _showAvatarInChat = value;
    await _saveSettings();
    _plugin.refresh();
  }

  Future<void> setShowAvatarInTimeline(bool value) async {
    _showAvatarInTimeline = value;
    await _saveSettings();
    _plugin.refresh();
  }

  Future<void> setTimelineIsGridView(bool value) async {
    _timelineIsGridView = value;
    await _saveSettings();
    _plugin.refresh();
  }

  bool shouldPlayMessageSound() {
    return _playSoundOnSend;
  }

  Future<void> _saveSettings() async {
    await _plugin.storage.write('chat/settings', {
      'showAvatarInChat': _showAvatarInChat,
      'showAvatarInTimeline': _showAvatarInTimeline,
      'playSoundOnSend': _playSoundOnSend,
      'timelineIsGridView': _timelineIsGridView,
    });
  }
}

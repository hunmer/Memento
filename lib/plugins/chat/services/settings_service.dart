import 'package:flutter/foundation.dart';
import '../chat_plugin.dart';

/// 负责管理聊天插件的设置
class SettingsService {
  final ChatPlugin _plugin;

  // 插件设置
  bool _showAvatarInChat = true;
  bool _showAvatarInTimeline = true;
  bool _playSoundOnSend = true;
  bool _timelineIsGridView = false;

  bool get showAvatarInChat => _showAvatarInChat;
  bool get showAvatarInTimeline => _showAvatarInTimeline;
  bool get playSoundOnSend => _playSoundOnSend;
  bool get timelineIsGridView => _timelineIsGridView;

  SettingsService(this._plugin);

  Future<void> initialize() async {
    await _initializeSettings();
  }

  // 初始化插件设置
  Future<void> _initializeSettings() async {
    try {
      // 从存储中加载设置
      final settings = await _plugin.storage.read('chat/settings');
      _showAvatarInChat = settings['showAvatarInChat'] ?? true;
      _showAvatarInTimeline = settings['showAvatarInTimeline'] ?? true;
      _playSoundOnSend = settings['playSoundOnSend'] ?? true;
      _timelineIsGridView = settings['timelineIsGridView'] ?? false;
    } catch (e) {
      // 如果读取失败，使用默认值
      debugPrint('Error loading chat settings: $e');
      _showAvatarInChat = true;
      _showAvatarInTimeline = true;
      _playSoundOnSend = true;
      _timelineIsGridView = false;
    }
  }

  Future<void> setPlaySoundOnSend(bool value) async {
    _playSoundOnSend = value;
    await _saveSettings();
    _plugin.notifyListeners();
  }

  Future<void> setShowAvatarInChat(bool value) async {
    _showAvatarInChat = value;
    await _saveSettings();
    _plugin.notifyListeners();
  }

  Future<void> setShowAvatarInTimeline(bool value) async {
    _showAvatarInTimeline = value;
    await _saveSettings();
    _plugin.notifyListeners();
  }

  // 保存设置
  Future<void> _saveSettings() async {
    await _plugin.storage.write('chat/settings', {
      'showAvatarInChat': _showAvatarInChat,
      'showAvatarInTimeline': _showAvatarInTimeline,
      'playSoundOnSend': _playSoundOnSend,
      'timelineIsGridView': _timelineIsGridView,
    });
  }

  // 检查是否应该播放消息提示音
  bool shouldPlayMessageSound() {
    return _playSoundOnSend;
  }

  // 设置时间线视图模式
  Future<void> setTimelineIsGridView(bool value) async {
    _timelineIsGridView = value;
    await _saveSettings();
    _plugin.notifyListeners();
  }
}

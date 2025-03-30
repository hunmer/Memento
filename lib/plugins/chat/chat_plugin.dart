import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../base_plugin.dart';
import '../../core/plugin_manager.dart';
import '../../core/config_manager.dart';
import '../../models/channel.dart';
import '../../models/message.dart';
import '../../models/user.dart';
import '../../models/serialization_helpers.dart';
import '../../screens/channel_list_screen.dart';

class ChatPlugin extends BasePlugin {
  static ChatPlugin? _instance;
  static ChatPlugin get instance {
    _instance ??= ChatPlugin();
    return _instance!;
  }

  final List<Channel> _channels = [];
  final String _pluginId = 'chat';
  final String _uuid = '12345678901234567890123456789012'; // 32位UUID
  String _customPluginDir = ''; // 自定义插件目录

  // 获取自定义插件目录
  String get customPluginDir => _customPluginDir;

  // 获取频道列表的getter
  List<Channel> get channels => _channels;

  @override
  String get id => _pluginId;

  @override
  String get name => 'Chat';

  @override
  String get version => '1.0.0';

  @override
  String get description => '基础聊天功能插件';

  @override
  String get author => 'Zhuanz';

  @override
  String get pluginDir =>
      _customPluginDir.isEmpty
          ? 'flutter_app/$_uuid' // 默认路径：用户目录/flutter_app/插件uuid
          : _customPluginDir; // 自定义路径

  // 设置自定义插件目录
  void setCustomPluginDir(String dir) {
    _customPluginDir = dir;
  }

  // 打开目录选择器
  Future<String?> pickDirectory() async {
    try {
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
      if (selectedDirectory != null) {
        setCustomPluginDir(selectedDirectory);
        return selectedDirectory;
      }
      return null;
    } catch (e) {
      debugPrint('Error picking directory: $e');
      return null;
    }
  }

  // 获取插件的UUID
  String get uuid => _uuid;

  @override
  Future<void> initialize() async {
    await initializeDefaultData();
    await _loadChannels();
  }

  @override
  Future<void> initializeDefaultData() async {
    // 确保数据目录存在
    await storage.ensureDirectoryExists('$pluginDir/datas');
    // 默认数据已移除，用户需要手动创建频道和消息
  }

  Future<void> _loadChannels() async {
    try {
      // 清空现有频道列表，避免重复加载
      _channels.clear();

      // 获取所有频道目录
      final dataPath = '$pluginDir/datas';
      final directory = Directory('${storage.basePath}/$dataPath');

      if (await directory.exists()) {
        final channelDirs = await directory.list().toList();

        for (var channelDir in channelDirs) {
          final channelId = channelDir.path.split('/').last;

          // 加载频道信息
          final channelData = await storage.read(
            '$dataPath/$channelId/channel.json',
          );
          if (channelData.isEmpty || !channelData.containsKey('channel')) {
            continue;
          }

          // 加载频道成员
          final channelJson = channelData['channel'] as Map<String, dynamic>;
          final List<dynamic> membersJson =
              channelJson['members'] as List<dynamic>;
          final List<User> members =
              membersJson
                  .map(
                    (m) => UserSerializer.fromJson(m as Map<String, dynamic>),
                  )
                  .toList();

          // 加载消息
          final messagesData = await storage.read(
            '$dataPath/$channelId/messages.json',
          );
          List<Message> messages = [];

          if (messagesData.isNotEmpty && messagesData.containsKey('messages')) {
            final List<dynamic> messagesJson =
                messagesData['messages'] as List<dynamic>;
            messages =
                messagesJson
                    .map(
                      (m) => MessageSerializer.fromJson(
                        m as Map<String, dynamic>,
                        members,
                      ),
                    )
                    .toList();
          }

          // 创建频道对象
          final channel = ChannelSerializer.fromJson(
            channelJson,
            messages: messages,
          );
          _channels.add(channel);
        }

        // 按优先级和最后消息时间排序
        _channels.sort(Channel.compare);
      }
    } catch (e) {
      debugPrint('Error loading channels: $e');
    }
  }

  // 保存频道信息
  Future<void> saveChannel(Channel channel) async {
    final channelPath = '$pluginDir/datas/${channel.id}';

    // 确保目录存在
    await storage.ensureDirectoryExists(channelPath);

    // 保存频道信息
    await storage.write('$channelPath/channel.json', {
      'channel': ChannelSerializer.toJson(channel),
    });
  }

  // 保存消息
  Future<void> saveMessages(String channelId, List<Message> messages) async {
    final channelPath = '$pluginDir/datas/$channelId';

    // 确保目录存在
    await storage.ensureDirectoryExists(channelPath);

    // 保存消息
    await storage.write('$channelPath/messages.json', {
      'messages': messages.map((m) => MessageSerializer.toJson(m)).toList(),
    });
  }

  // 保存所有频道信息
  Future<void> saveChannels() async {
    for (var channel in _channels) {
      await saveChannel(channel);
    }
  }

  // 删除频道
  Future<void> deleteChannel(String channelId) async {
    final channelPath = '$pluginDir/datas/$channelId';

    try {
      // 删除频道目录及其所有内容
      await storage.deleteDirectory(channelPath);

      // 从内存中移除频道
      _channels.removeWhere((channel) => channel.id == channelId);
    } catch (e) {
      debugPrint('Error deleting channel: $e');
    }
  }

  // 删除频道消息
  Future<void> deleteChannelMessages(String channelId) async {
    final channelPath = '$pluginDir/datas/$channelId';

    try {
      // 删除消息文件
      await storage.delete('$channelPath/messages.json');
    } catch (e) {
      debugPrint('Error deleting channel messages: $e');
    }
  }

  // 添加新消息
  Future<void> addMessage(String channelId, Message message) async {
    // 找到对应频道
    final channelIndex = _channels.indexWhere((c) => c.id == channelId);
    if (channelIndex == -1) return;

    // 添加消息到内存中
    _channels[channelIndex].messages.add(message);

    // 保存到存储
    await saveMessages(channelId, _channels[channelIndex].messages);
  }

  // 创建新频道
  Future<void> createChannel(Channel channel) async {
    // 添加到内存中
    _channels.add(channel);

    // 保存频道信息
    await saveChannel(channel);

    // 保存空消息列表
    await saveMessages(channel.id, []);

    // 重新排序
    _channels.sort(Channel.compare);
  }

  @override
  Widget buildMainView(BuildContext context) {
    return ChannelListScreen(channels: _channels);
  }

  /// 注册插件到应用
  @override
  Future<void> registerToApp(
    PluginManager pluginManager,
    ConfigManager configManager,
  ) async {
    // 初始化插件
    await initialize();

    // 注册插件到插件管理器
    await pluginManager.registerPlugin(this);

    // 保存插件配置
    await configManager.savePluginConfig(id, {
      'version': version,
      'enabled': true,
      'settings': {'notifications': true, 'theme': 'light'},
    });
  }
}

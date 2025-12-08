import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:Memento/plugins/base_plugin.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/core/config_manager.dart';
import 'models/tts_service_config.dart';
import 'models/tts_service_type.dart';
import 'services/tts_manager_service.dart';
import 'services/tts_base_service.dart';
import 'l10n/tts_localizations.dart';
import 'screens/tts_services_screen.dart';

/// TTS语音朗读插件
class TTSPlugin extends BasePlugin {
  static TTSPlugin? _instance;

  /// 获取单例实例
  static TTSPlugin get instance {
    if (_instance == null) {
      _instance = PluginManager.instance.getPlugin('tts') as TTSPlugin?;
      if (_instance == null) {
        throw StateError('TTSPlugin has not been initialized');
      }
    }
    return _instance!;
  }

  /// TTS管理器服务
  late final TTSManagerService managerService;

  @override
  String get id => 'tts';

  @override
  IconData get icon => Icons.record_voice_over;

  @override
  Color get color => Colors.purple;

  @override
  String? getPluginName(context) {
    return TTSLocalizations.of(context).name;
  }

  @override
  Future<void> initialize() async {
    // 创建管理器服务
    managerService = TTSManagerService(
      storagePrefix: storageDir,
      readStorage: (key) async {
        try {
          return await storage.read(key);
        } catch (e) {
          return {};
        }
      },
      writeStorage: (key, data) async {
        await storage.write(key, data);
      },
    );

    // 初始化默认数据
    await initializeDefaultData();
  }

  @override
  Future<void> registerToApp(
    PluginManager pluginManager,
    ConfigManager configManager,
  ) async {
    await initialize();
  }

  /// 初始化默认数据
  @override
  Future<void> initializeDefaultData() async {
    final services = await managerService.getAllServices();

    if (services.isEmpty) {
      // 创建默认系统 TTS 服务
      final defaultService = TTSServiceConfig(
        id: const Uuid().v4(),
        name: '系统语音',
        type: TTSServiceType.system,
        isDefault: true,
        isEnabled: true,
        pitch: 1.0,
        speed: 1.0,
        volume: 1.0,
        voice: 'zh-CN', // 默认中文
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await managerService.saveService(defaultService);
    }
  }

  @override
  Widget buildMainView(BuildContext context) {
    return const TTSServicesScreen();
  }

  @override
  Widget? buildCardView(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(
                  getPluginName(context) ?? 'TTS',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FutureBuilder<List<TTSServiceConfig>>(
              future: managerService.getAllServices(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Text('加载中...');
                }

                final services = snapshot.data!;
                final enabledCount = services.where((s) => s.isEnabled).length;

                return Text(
                  '已配置 ${services.length} 个服务，启用 $enabledCount 个',
                  style: TextStyle(color: Colors.grey[600]),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ============ 对外 API ============

  /// 单次朗读
  ///
  /// [text] 要朗读的文本
  /// [serviceId] 指定的服务ID（如果为null则使用默认服务）
  /// [onStart] 开始朗读回调
  /// [onComplete] 完成回调
  /// [onError] 错误回调
  Future<void> speak(
    String text, {
    String? serviceId,
    TTSCallback? onStart,
    TTSCallback? onComplete,
    TTSErrorCallback? onError,
  }) {
    return managerService.speak(
      text,
      serviceId: serviceId,
      onStart: onStart,
      onComplete: onComplete,
      onError: onError,
    );
  }

  /// 添加到队列
  ///
  /// [text] 要朗读的文本
  /// [serviceId] 指定的服务ID（如果为null则使用默认服务）
  void addToQueue(String text, {String? serviceId}) {
    managerService.addToQueue(text, serviceId: serviceId);
  }

  /// 批量添加到队列
  ///
  /// [texts] 要朗读的文本列表
  /// [serviceId] 指定的服务ID（如果为null则使用默认服务）
  void addBatchToQueue(List<String> texts, {String? serviceId}) {
    managerService.addBatchToQueue(texts, serviceId: serviceId);
  }

  /// 暂停队列
  Future<void> pauseQueue() => managerService.pauseQueue();

  /// 继续队列
  Future<void> resumeQueue() => managerService.resumeQueue();

  /// 停止队列
  Future<void> stopQueue() => managerService.stopQueue();

  /// 跳过当前项
  Future<void> skipCurrent() => managerService.skipCurrent();

  /// 清空队列
  void clearQueue() => managerService.clearQueue();

  /// 停止朗读
  Future<void> stop() => managerService.stop();

  /// 暂停朗读
  Future<void> pause() => managerService.pause();

  /// 继续朗读
  Future<void> resume() => managerService.resume();

  /// 获取队列副本
  List<dynamic> get queue => managerService.queue;

  /// 获取当前队列项
  dynamic get currentQueueItem => managerService.currentQueueItem;

  /// 是否正在处理队列
  bool get isProcessingQueue => managerService.isProcessingQueue;

  /// 队列是否暂停
  bool get isQueuePaused => managerService.isQueuePaused;
}

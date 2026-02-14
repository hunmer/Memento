import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:Memento/plugins/tts/tts_plugin.dart';
import 'package:Memento/plugins/tts/models/tts_service_config.dart';
import 'package:Memento/plugins/tts/models/tts_service_type.dart';
import 'package:Memento/plugins/tts/services/background_announcement_service.dart';

/// 后台播报测试页面
class BackgroundAnnouncementTestScreen extends StatefulWidget {
  const BackgroundAnnouncementTestScreen({super.key});

  @override
  State<BackgroundAnnouncementTestScreen> createState() =>
      _BackgroundAnnouncementTestScreenState();
}

class _BackgroundAnnouncementTestScreenState
    extends State<BackgroundAnnouncementTestScreen> {
  final BackgroundAnnouncementService _announcementService =
      BackgroundAnnouncementService();

  List<TTSServiceConfig> _services = [];
  bool _isLoadingServices = true;
  String? _selectedServiceId;

  final TextEditingController _intervalController = TextEditingController(text: '60');
  final TextEditingController _textController = TextEditingController(
    text: '现在是 {yyyy年MM月dd日} {HH时mm分}',
  );

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  @override
  void dispose() {
    _intervalController.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _loadServices() async {
    setState(() => _isLoadingServices = true);
    try {
      final plugin = TTSPlugin.instance;
      final services = await plugin.managerService.getAllServices();

      final defaultService = await plugin.managerService.getDefaultService();
      _selectedServiceId = defaultService?.id;

      setState(() {
        _services = services;
        _isLoadingServices = false;
      });
    } catch (e) {
      setState(() => _isLoadingServices = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载TTS服务失败: $e')),
        );
      }
    }
  }

  Future<void> _startAnnouncement() async {
    final interval = int.tryParse(_intervalController.text);
    if (interval == null || interval < 1) {
      _showMessage('请输入有效的间隔时间（秒）');
      return;
    }

    if (_textController.text.trim().isEmpty) {
      _showMessage('请输入播报文本');
      return;
    }

    try {
      // 初始化服务
      _announcementService.initialize(TTSPlugin.instance.managerService);

      await _announcementService.start(
        intervalSeconds: interval,
        textTemplate: _textController.text,
        serviceId: _selectedServiceId,
      );

      if (mounted) {
        _showMessage('后台播报已启动');
      }
    } catch (e) {
      _showMessage('启动失败: $e');
    }
  }

  Future<void> _stopAnnouncement() async {
    await _announcementService.stop();
    if (mounted) {
      _showMessage('后台播报已停止');
    }
  }

  Future<void> _speakOnce() async {
    try {
      if (_textController.text.trim().isEmpty) {
        _showMessage('请输入播报文本');
        return;
      }

      // 初始化服务
      _announcementService.initialize(TTSPlugin.instance.managerService);

      // 更新配置使用当前选中的服务和文本
      _announcementService.updateConfig(
        serviceId: _selectedServiceId,
        textTemplate: _textController.text,
      );

      await _announcementService.speakOnce(
        textTemplate: _textController.text,
      );
      if (mounted) {
        _showMessage('已播报一次');
      }
    } catch (e) {
      _showMessage('播报失败: $e');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('后台播报测试'),
        actions: [
          ListenableBuilder(
            listenable: _announcementService,
            builder: (context, child) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                alignment: Alignment.center,
                child: Row(
                  children: [
                    Icon(
                      _announcementService.isActive
                          ? Icons.notifications_active
                          : Icons.notifications_none,
                      color: _announcementService.isActive
                          ? Colors.green
                          : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _announcementService.isActive ? '运行中' : '已停止',
                      style: TextStyle(
                        color: _announcementService.isActive
                            ? Colors.green
                            : Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // TTS服务选择
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'TTS服务',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _isLoadingServices
                      ? const Center(child: CircularProgressIndicator())
                      : _services.isEmpty
                          ? const Text('没有可用的TTS服务')
                          : DropdownButtonFormField<String>(
                              value: _selectedServiceId,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                hintText: '选择TTS服务',
                              ),
                              items: _services
                                  .where((s) => s.isEnabled)
                                  .map((service) {
                                return DropdownMenuItem<String>(
                                  value: service.id,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        service.type == TTSServiceType.system
                                            ? Icons.record_voice_over
                                            : Icons.cloud,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(service.name),
                                      if (service.isDefault) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.green,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: const Text(
                                            '默认',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedServiceId = value;
                                });
                                if (_announcementService.isActive) {
                                  _announcementService.updateConfig(
                                    serviceId: value,
                                  );
                                }
                              },
                            ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 间隔设置
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '播报间隔（秒）',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _intervalController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: '输入播报间隔（秒）',
                      suffixText: '秒',
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 播报文本
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '播报文本模板',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '支持的时间占位符：',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  const Text(
                    '{yyyy-MM-dd} {HH:mm:ss} {yyyy年MM月dd日} {HH时mm分} {weekday}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _textController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: '输入播报文本模板',
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _speakOnce,
                    icon: const Icon(Icons.volume_up),
                    label: const Text('测试播报一次'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(40),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 控制按钮
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '控制',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ListenableBuilder(
                          listenable: _announcementService,
                          builder: (context, child) {
                            return ElevatedButton.icon(
                              onPressed: _announcementService.isActive
                                  ? _stopAnnouncement
                                  : _startAnnouncement,
                              icon: Icon(
                                _announcementService.isActive
                                    ? Icons.stop
                                    : Icons.play_arrow,
                              ),
                              label: Text(
                                _announcementService.isActive
                                    ? '停止播报'
                                    : '开始播报',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _announcementService.isActive
                                    ? Colors.red
                                    : Colors.green,
                                foregroundColor: Colors.white,
                                minimumSize: const Size.fromHeight(50),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 状态信息
          ListenableBuilder(
            listenable: _announcementService,
            builder: (context, child) {
              if (!_announcementService.isActive) {
                return const SizedBox.shrink();
              }

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '运行状态',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildStatusRow('播报间隔',
                          '${_announcementService.intervalSeconds} 秒'),
                      _buildStatusRow('播报次数',
                          '${_announcementService.announcementCount} 次'),
                      _buildStatusRow('上次播报',
                          _formatDateTime(_announcementService.lastAnnouncementTime)),
                      _buildStatusRow('下次播报',
                          _formatDateTime(_announcementService.nextAnnouncementTime)),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 16),

          // 说明
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '使用说明',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('• 选择要使用的TTS服务'),
                  const Text('• 设置播报间隔时间（秒）'),
                  const Text('• 输入播报文本模板，支持时间占位符'),
                  const Text('• 点击"测试播报一次"预览效果'),
                  const Text('• 点击"开始播报"启动后台播报'),
                  const Text('• 播报会在后台持续运行'),
                  const SizedBox(height: 8),
                  const Text(
                    '注意：应用切换到后台后播报可能会中断，',
                    style: TextStyle(color: Colors.orange),
                  ),
                  const Text(
                    '建议配合前台服务使用以保持后台运行。',
                    style: TextStyle(color: Colors.orange),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.grey),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime? dt) {
    if (dt == null) return '-';
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
  }
}

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../tts_plugin.dart';
import '../models/tts_service_config.dart';
import '../models/tts_service_type.dart';
import '../l10n/tts_localizations.dart';

/// TTS服务列表界面
class TTSServicesScreen extends StatefulWidget {
  const TTSServicesScreen({super.key});

  @override
  State<TTSServicesScreen> createState() => _TTSServicesScreenState();
}

class _TTSServicesScreenState extends State<TTSServicesScreen> {
  late TTSPlugin _plugin;
  List<TTSServiceConfig> _services = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _plugin = TTSPlugin.instance;
    _loadServices();
  }

  Future<void> _loadServices() async {
    setState(() => _isLoading = true);
    try {
      final services = await _plugin.managerService.getAllServices();
      setState(() {
        _services = services;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载服务失败: $e')),
        );
      }
    }
  }

  Future<void> _deleteService(TTSServiceConfig service) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(TTSLocalizations.of(context).deleteService),
        content: Text(TTSLocalizations.of(context).confirmDelete),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(TTSLocalizations.of(context).cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(TTSLocalizations.of(context).deleteService),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _plugin.managerService.deleteService(service.id);
        _loadServices();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('服务已删除')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('删除失败: $e')),
          );
        }
      }
    }
  }

  Future<void> _testService(TTSServiceConfig service) async {
    try {
      await _plugin.speak(
        '你好，这是语音测试',
        serviceId: service.id,
        onError: (error) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('测试失败: $error')),
            );
          }
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(TTSLocalizations.of(context).testSuccess)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${TTSLocalizations.of(context).testFailed}: $e')),
        );
      }
    }
  }

  Future<void> _toggleService(TTSServiceConfig service) async {
    try {
      final updated = service.copyWith(isEnabled: !service.isEnabled);
      await _plugin.managerService.saveService(updated);
      _loadServices();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('更新失败: $e')),
        );
      }
    }
  }

  Future<void> _setDefaultService(TTSServiceConfig service) async {
    try {
      // 获取所有服务,取消其他服务的默认状态
      for (var s in _services) {
        if (s.id != service.id && s.isDefault) {
          await _plugin.managerService.saveService(s.copyWith(isDefault: false));
        }
      }

      // 设置当前服务为默认
      await _plugin.managerService.saveService(service.copyWith(isDefault: true));
      _loadServices();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已设置为默认服务')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('设置失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = TTSLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.servicesList),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadServices,
            tooltip: '刷新',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _services.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.record_voice_over_outlined, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text('暂无服务', style: TextStyle(color: Colors.grey[600])),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () => _createDefaultService(),
                        icon: const Icon(Icons.add),
                        label: Text(loc.addService),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _services.length,
                  itemBuilder: (context, index) {
                    final service = _services[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: Icon(
                          service.type == TTSServiceType.system
                              ? Icons.record_voice_over
                              : Icons.cloud,
                          color: service.isEnabled ? _plugin.color : Colors.grey,
                        ),
                        title: Row(
                          children: [
                            Expanded(child: Text(service.name)),
                            if (service.isDefault)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  loc.defaultService,
                                  style: const TextStyle(color: Colors.white, fontSize: 12),
                                ),
                              ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              service.type == TTSServiceType.system ? loc.systemTts : loc.httpService,
                              style: TextStyle(color: Colors.grey[600], fontSize: 12),
                            ),
                            Text(
                              service.isEnabled ? loc.enabled : loc.disabled,
                              style: TextStyle(
                                color: service.isEnabled ? Colors.green : Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert),
                          onSelected: (value) {
                            switch (value) {
                              case 'test':
                                _testService(service);
                                break;
                              case 'toggle':
                                _toggleService(service);
                                break;
                              case 'default':
                                _setDefaultService(service);
                                break;
                              case 'delete':
                                _deleteService(service);
                                break;
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'test',
                              child: Row(
                                children: [
                                  const Icon(Icons.play_arrow, size: 20),
                                  const SizedBox(width: 8),
                                  Text(loc.test),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'toggle',
                              child: Row(
                                children: [
                                  Icon(
                                    service.isEnabled ? Icons.pause : Icons.play_circle_outline,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(service.isEnabled ? loc.disabled : loc.enabled),
                                ],
                              ),
                            ),
                            if (!service.isDefault)
                              PopupMenuItem(
                                value: 'default',
                                child: Row(
                                  children: [
                                    const Icon(Icons.star_outline, size: 20),
                                    const SizedBox(width: 8),
                                    Text('设为默认'),
                                  ],
                                ),
                              ),
                            const PopupMenuDivider(),
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                                  const SizedBox(width: 8),
                                  Text(loc.deleteService, style: const TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: _isLoading || _services.isEmpty
          ? null
          : FloatingActionButton(
              onPressed: () => _createDefaultService(),
              child: const Icon(Icons.add),
            ),
    );
  }

  Future<void> _createDefaultService() async {
    // 简化版:直接创建一个系统TTS服务
    final newService = TTSServiceConfig(
      id: const Uuid().v4(),
      name: '系统语音 ${_services.length + 1}',
      type: TTSServiceType.system,
      isDefault: _services.isEmpty,
      isEnabled: true,
      pitch: 1.0,
      speed: 1.0,
      volume: 1.0,
      voice: 'zh-CN',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      await _plugin.managerService.saveService(newService);
      _loadServices();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('服务已添加')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('添加失败: $e')),
        );
      }
    }
  }
}

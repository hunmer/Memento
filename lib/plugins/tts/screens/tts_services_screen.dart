import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/widgets/super_cupertino_navigation_wrapper.dart';
import 'package:Memento/plugins/tts/tts_plugin.dart';
import 'package:Memento/plugins/tts/models/tts_service_config.dart';
import 'package:Memento/plugins/tts/models/tts_service_type.dart';
import 'package:Memento/plugins/tts/widgets/service_editor_dialog.dart';
import 'package:Memento/core/services/toast_service.dart';

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
        Toast.error('${'tts_loadServicesFailed'.tr}: $e');
      }
    }
  }

  Future<void> _deleteService(TTSServiceConfig service) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('tts_deleteService'.tr),
            content: Text('tts_confirmDelete'.tr),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('tts_cancel'.tr),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: Text('tts_deleteService'.tr),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        await _plugin.managerService.deleteService(service.id);
        _loadServices();
        if (mounted) {
          Toast.success('tts_serviceDeleted'.tr);
        }
      } catch (e) {
        if (mounted) {
          Toast.error('${'tts_deleteFailed'.tr}: $e');
        }
      }
    }
  }

  Future<void> _testService(TTSServiceConfig service) async {
    try {
      await _plugin.speak(
        'tts_voiceTestText'.tr,
        serviceId: service.id,
        onError: (error) {
          if (mounted) {
            Toast.error('${'tts_testFailedPrefix'.tr}: $error');
          }
        },
      );

      if (mounted) {
        Toast.success('tts_testSuccess'.tr);
      }
    } catch (e) {
      if (mounted) {
        Toast.error('${'tts_testFailedPrefix'.tr}: $e');
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
        Toast.error('${'tts_updateFailed'.tr}: $e');
      }
    }
  }

  Future<void> _setDefaultService(TTSServiceConfig service) async {
    try {
      // 获取所有服务,取消其他服务的默认状态
      for (var s in _services) {
        if (s.id != service.id && s.isDefault) {
          await _plugin.managerService.saveService(
            s.copyWith(isDefault: false),
          );
        }
      }

      // 设置当前服务为默认
      await _plugin.managerService.saveService(
        service.copyWith(isDefault: true),
      );
      _loadServices();

      if (mounted) {
        Toast.success('tts_setAsDefaultService'.tr);
      }
    } catch (e) {
      if (mounted) {
        Toast.error('${'tts_setDefaultFailed'.tr}: $e');
      }
    }
  }

  /// 创建新服务
  Future<void> _createDefaultService() async {
    final result = await showDialog<TTSServiceConfig>(
      context: context,
      builder: (context) => const ServiceEditorDialog(),
    );

    if (result != null) {
      try {
        await _plugin.managerService.saveService(result);
        _loadServices();

        if (mounted) {
          Toast.success('tts_serviceAdded'.tr);
        }
      } catch (e) {
        if (mounted) {
          Toast.error('${'tts_addFailed'.tr}: $e');
        }
      }
    }
  }

  /// 编辑服务
  Future<void> _editService(TTSServiceConfig service) async {
    final result = await showDialog<TTSServiceConfig>(
      context: context,
      builder: (context) => ServiceEditorDialog(service: service),
    );

    if (result != null) {
      try {
        await _plugin.managerService.saveService(result);
        _loadServices();

        if (mounted) {
          Toast.success('tts_serviceUpdated'.tr);
        }
      } catch (e) {
        if (mounted) {
          Toast.error('${'tts_updateFailed'.tr}: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SuperCupertinoNavigationWrapper(
      title: Text(
        'tts_servicesList'.tr,
        style: TextStyle(color: theme.textTheme.titleLarge?.color),
      ),
      largeTitle: 'TTS 服务',

      actions: [
        IconButton(
          icon: Icon(Icons.refresh, color: theme.iconTheme.color),
          onPressed: _loadServices,
          tooltip: 'tts_refresh'.tr,
        ),
      ],
      body: Stack(
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _services.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.record_voice_over_outlined,
                      size: 64,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'tts_noServicesAvailable'.tr,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () => _createDefaultService(),
                      icon: const Icon(Icons.add),
                      label: Text('tts_addService'.tr),
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
                      onTap: () => _editService(service),
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'tts_defaultService'.tr,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            service.type == TTSServiceType.system
                                ? 'tts_systemTts'.tr
                                : 'tts_httpService'.tr,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            service.isEnabled
                                ? 'tts_enabled'.tr
                                : 'tts_disabled'.tr,
                            style: TextStyle(
                              color:
                                  service.isEnabled
                                      ? Colors.green
                                      : Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      trailing: PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert),
                        onSelected: (value) {
                          switch (value) {
                            case 'edit':
                              _editService(service);
                              break;
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
                        itemBuilder:
                            (context) => [
                              PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    const Icon(Icons.edit, size: 20),
                                    const SizedBox(width: 8),
                                    Text('tts_editService'.tr),
                                  ],
                                ),
                              ),
                              const PopupMenuDivider(),
                              PopupMenuItem(
                                value: 'test',
                                child: Row(
                                  children: [
                                    const Icon(Icons.play_arrow, size: 20),
                                    const SizedBox(width: 8),
                                    Text('tts_test'.tr),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'toggle',
                                child: Row(
                                  children: [
                                    Icon(
                                      service.isEnabled
                                          ? Icons.pause
                                          : Icons.play_circle_outline,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      service.isEnabled
                                          ? 'tts_disabled'.tr
                                          : 'tts_enabled'.tr,
                                    ),
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
                                      Text('tts_setAsDefault'.tr),
                                    ],
                                  ),
                                ),
                              const PopupMenuDivider(),
                              PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.delete_outline,
                                      size: 20,
                                      color: Colors.red,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'tts_deleteService'.tr,
                                      style: const TextStyle(color: Colors.red),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                      ),
                    ),
                  );
                },
              ),
          // FAB 覆盖层
          if (!_isLoading && _services.isNotEmpty)
            Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton(
                onPressed: () => _createDefaultService(),
                child: const Icon(Icons.add),
              ),
            ),
        ],
      ),
    );
  }
}

import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:Memento/widgets/super_cupertino_navigation_wrapper.dart';
import 'package:Memento/plugins/tts/tts_plugin.dart';
import 'package:Memento/plugins/tts/models/tts_service_config.dart';
import 'package:Memento/plugins/tts/models/tts_service_type.dart';
import 'package:Memento/plugins/tts/l10n/tts_localizations.dart';
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
        Toast.error('${TTSLocalizations.of(context).loadServicesFailed}: $e');
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
          Toast.success(TTSLocalizations.of(context).serviceDeleted);
        }
      } catch (e) {
        if (mounted) {
          Toast.error('${TTSLocalizations.of(context).deleteFailed}: $e');
        }
      }
    }
  }

  Future<void> _testService(TTSServiceConfig service) async {
    try {
      await _plugin.speak(
        TTSLocalizations.of(context).voiceTestText,
        serviceId: service.id,
        onError: (error) {
          if (mounted) {
            Toast.error('${TTSLocalizations.of(context).testFailedPrefix}: $error');
          }
        },
      );

      if (mounted) {
        Toast.success(TTSLocalizations.of(context).testSuccess);
      }
    } catch (e) {
      if (mounted) {
        Toast.error('${TTSLocalizations.of(context).testFailedPrefix}: $e');
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
        Toast.error('${TTSLocalizations.of(context).updateFailed}: $e');
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
        Toast.success(TTSLocalizations.of(context).setAsDefaultService);
      }
    } catch (e) {
      if (mounted) {
        Toast.error('${TTSLocalizations.of(context).setDefaultFailed}: $e');
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
          Toast.success(TTSLocalizations.of(context).serviceAdded);
        }
      } catch (e) {
        if (mounted) {
          Toast.error('${TTSLocalizations.of(context).addFailed}: $e');
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
          Toast.success(TTSLocalizations.of(context).serviceUpdated);
        }
      } catch (e) {
        if (mounted) {
          Toast.error('${TTSLocalizations.of(context).updateFailed}: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = TTSLocalizations.of(context);
    final theme = Theme.of(context);

    return SuperCupertinoNavigationWrapper(
      title: Text(
        loc.servicesList,
        style: TextStyle(color: theme.textTheme.titleLarge?.color),
      ),
      largeTitle: 'TTS 服务',
      automaticallyImplyLeading: !(Platform.isAndroid || Platform.isIOS),
      actions: [
        IconButton(
          icon: Icon(Icons.refresh, color: theme.iconTheme.color),
          onPressed: _loadServices,
          tooltip: TTSLocalizations.of(context).refresh,
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
                          const Icon(Icons.record_voice_over_outlined, size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text(TTSLocalizations.of(context).noServicesAvailable, style: TextStyle(color: Colors.grey[600])),
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
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      const Icon(Icons.edit, size: 20),
                                      const SizedBox(width: 8),
                                      Text(loc.editService),
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
                                        Text(TTSLocalizations.of(context).setAsDefault),
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

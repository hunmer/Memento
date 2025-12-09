import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/screens/settings_screen/controllers/settings_screen_controller.dart';
import 'package:Memento/screens/settings_screen/models/webdav_config.dart';
import '../../../../core/services/toast_service.dart';

class WebDAVSettingsSection extends StatefulWidget {
  final SettingsScreenController controller;

  const WebDAVSettingsSection({super.key, required this.controller});

  @override
  State<WebDAVSettingsSection> createState() => _WebDAVSettingsSectionState();
}

class _WebDAVSettingsSectionState extends State<WebDAVSettingsSection> {
  final _formKey = GlobalKey<FormState>();
  final _serverController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _serverController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    try {
      final config = await WebDAVConfig.load();
      setState(() {
        _serverController.text =
            config.server.isNotEmpty ? config.server : 'https://';
        _usernameController.text = config.username;
        _passwordController.text = config.password;
      });
    } catch (e) {
      debugPrint('加载WebDAV设置失败: $e');
      setState(() {
        _serverController.text = 'https://';
        _usernameController.text = '';
        _passwordController.text = '';
      });
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final config = WebDAVConfig(
        server: _serverController.text.trim(),
        username: _usernameController.text.trim(),
        password: _passwordController.text,
      );

      await config.save();

      if (!mounted) return;

      toastService.showToast('webdav_settingsSaved'.tr);
    } catch (e) {
      if (!mounted) return;

      toastService.showToast(
        '${'webdav_saveFailed'.tr}: ${e.toString()}',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _uploadAllToWebDAV() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await widget.controller.uploadAllToWebDAV();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _downloadAllFromWebDAV() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await widget.controller.downloadAllFromWebDAV();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.cloud_sync),
                const SizedBox(width: 8),
                Text(
                  'webdav_title'.tr,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _serverController,
                    decoration: InputDecoration(
                      labelText: 'webdav_serverAddress'.tr,
                      hintText: 'webdav_serverAddressHint'.tr,
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'webdav_serverAddressEmptyError'.tr;
                      }
                      if (!value.startsWith('http://') &&
                          !value.startsWith('https://')) {
                        return 'webdav_serverAddressInvalidError'.tr;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      labelText: 'webdav_username'.tr,
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'webdav_usernameEmptyError'.tr;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    decoration: InputDecoration(
                      labelText: 'webdav_password'.tr,
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'webdav_passwordEmptyError'.tr;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _saveSettings,
                          child: Text(
                            'webdav_saveSettings'.tr,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 32),
            Text(
              'webdav_dataSync'.tr,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _uploadAllToWebDAV,
                    icon: const Icon(Icons.cloud_upload),
                    label: Text('webdav_uploadAllData'.tr),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _downloadAllFromWebDAV,
                    icon: const Icon(Icons.cloud_download),
                    label: Text(
                      'webdav_downloadAllData'.tr,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      foregroundColor:
                          Theme.of(context).colorScheme.onSecondary,
                    ),
                  ),
                ),
              ],
            ),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: LinearProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }
}

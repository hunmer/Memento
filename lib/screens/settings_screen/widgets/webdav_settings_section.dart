import 'package:flutter/material.dart';
import '../controllers/settings_screen_controller.dart';
import '../models/webdav_config.dart';
import 'l10n/webdav_localizations.dart';

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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(WebDAVLocalizations.of(context).settingsSaved),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${WebDAVLocalizations.of(context).saveFailed}: ${e.toString()}',
          ),
          backgroundColor: Colors.red,
        ),
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
                  WebDAVLocalizations.of(context).title,
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
                      labelText: WebDAVLocalizations.of(context).serverAddress,
                      hintText:
                          WebDAVLocalizations.of(context).serverAddressHint,
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return WebDAVLocalizations.of(
                          context,
                        ).serverAddressEmptyError;
                      }
                      if (!value.startsWith('http://') &&
                          !value.startsWith('https://')) {
                        return WebDAVLocalizations.of(
                          context,
                        ).serverAddressInvalidError;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      labelText: WebDAVLocalizations.of(context).username,
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return WebDAVLocalizations.of(
                          context,
                        ).usernameEmptyError;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    decoration: InputDecoration(
                      labelText: WebDAVLocalizations.of(context).password,
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
                        return WebDAVLocalizations.of(
                          context,
                        ).passwordEmptyError;
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
                            WebDAVLocalizations.of(context).saveSettings,
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
              WebDAVLocalizations.of(context).dataSync,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _uploadAllToWebDAV,
                    icon: const Icon(Icons.cloud_upload),
                    label: Text(WebDAVLocalizations.of(context).uploadAllData),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _downloadAllFromWebDAV,
                    icon: const Icon(Icons.cloud_download),
                    label: Text(
                      WebDAVLocalizations.of(context).downloadAllData,
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

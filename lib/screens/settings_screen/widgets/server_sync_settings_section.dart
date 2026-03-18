import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:universal_platform/universal_platform.dart';

import 'package:Memento/core/services/toast_service.dart';
import 'package:Memento/core/services/sync_client_service.dart';
import 'package:Memento/core/services/sync_websocket_service.dart';
import 'package:Memento/core/services/sync_record_service.dart';
import 'package:Memento/core/services/encryption_service.dart';
import 'package:Memento/core/services/file_watch_sync_service.dart';
import 'package:Memento/core/storage/storage_manager.dart';
import 'package:Memento/core/route/route_refresh_manager.dart';
import 'package:Memento/screens/settings_screen/models/server_sync_config.dart';

/// 服务器同步设置组件
class ServerSyncSettingsSection extends StatefulWidget {
  const ServerSyncSettingsSection({super.key});

  @override
  State<ServerSyncSettingsSection> createState() =>
      _ServerSyncSettingsSectionState();
}

class _ServerSyncSettingsSectionState extends State<ServerSyncSettingsSection> {
  final _formKey = GlobalKey<FormState>();
  final _serverController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _deviceNameController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _isLoggedIn = false;
  bool _autoSync = false;
  bool _syncOnChange = true;
  bool _syncOnStart = true;
  int _syncInterval = 30;
  List<String> _selectedSyncDirs = [];

  ServerSyncConfig? _config;
  SyncClientService? _syncService;
  SyncRecordService? _recordService;
  Timer? _autoSyncTimer;
  bool _isWsConnected = false;

  @override
  void initState() {
    super.initState();
    _loadConfig();
    _initDeviceName();
  }

  @override
  void dispose() {
    _serverController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _deviceNameController.dispose();
    _autoSyncTimer?.cancel();
    super.dispose();
  }

  Future<void> _initDeviceName() async {
    final deviceInfo = DeviceInfoPlugin();
    String deviceName = 'Unknown Device';

    try {
      if (UniversalPlatform.isAndroid) {
        final info = await deviceInfo.androidInfo;
        deviceName = '${info.brand} ${info.model}';
      } else if (UniversalPlatform.isIOS) {
        final info = await deviceInfo.iosInfo;
        deviceName = info.name;
      } else if (UniversalPlatform.isWindows) {
        final info = await deviceInfo.windowsInfo;
        deviceName = info.computerName;
      } else if (UniversalPlatform.isMacOS) {
        final info = await deviceInfo.macOsInfo;
        deviceName = info.computerName;
      } else if (UniversalPlatform.isLinux) {
        final info = await deviceInfo.linuxInfo;
        deviceName = info.name;
      }
    } catch (e) {
      debugPrint('获取设备信息失败: $e');
    }

    if (_deviceNameController.text.isEmpty) {
      _deviceNameController.text = deviceName;
    }
  }

  Future<void> _loadConfig() async {
    try {
      final config = await ServerSyncConfig.load();
      setState(() {
        _config = config;
        _serverController.text =
            config.server.isNotEmpty ? config.server : 'http://';
        _usernameController.text = config.username;
        _passwordController.text = config.password;
        _deviceNameController.text = config.deviceName;
        _isLoggedIn = config.isLoggedIn;
        _autoSync = config.autoSync;
        _syncOnChange = config.syncOnChange;
        _syncOnStart = config.syncOnStart;
        _syncInterval = config.syncInterval;
        _selectedSyncDirs = List.from(config.syncDirs);
      });

      // 如果已登录，初始化同步服务
      if (config.isLoggedIn) {
        await _initSyncService();
        _startAutoSyncIfEnabled();
      }
    } catch (e) {
      debugPrint('加载服务器同步设置失败: $e');
      setState(() {
        _serverController.text = 'http://';
      });
    }
  }

  Future<void> _initSyncService() async {
    if (_config == null || !_config!.isLoggedIn) return;

    final storage = StorageManager();
    final encryption = EncryptionService();
    await encryption.initializeFromPassword(_config!.password, _config!.salt!);

    _syncService = SyncClientService(
      serverUrl: _config!.server,
      storage: storage,
      encryption: encryption,
    );
    _syncService!.initialize(
      token: _config!.token!,
      userId: _config!.userId!,
      deviceId: _config!.deviceId,
    );

    // 初始化记录服务
    _recordService = SyncRecordService();
    await _recordService!.initialize(storage);

    // 配置并连接 WebSocket
    _initWebSocket();
  }

  /// 初始化 WebSocket 连接
  void _initWebSocket() {
    if (_config == null || !_config!.isLoggedIn) return;

    final wsService = SyncWebSocketService();
    wsService.configure(
      syncClientService: _syncService!,
      recordService: _recordService!,
      routeRefreshManager: RouteRefreshManager(),
    );

    wsService.connect(
      serverUrl: _config!.server,
      token: _config!.token!,
      deviceId: _config!.deviceId,
    );

    setState(() {
      _isWsConnected = true;
    });
  }

  void _startAutoSyncIfEnabled() {
    _autoSyncTimer?.cancel();
    if (_autoSync && _isLoggedIn) {
      _autoSyncTimer = Timer.periodic(
        Duration(minutes: _syncInterval),
        (_) => _performSync(),
      );
    }
  }

  Future<void> _saveConfig() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final config = ServerSyncConfig(
        server: _serverController.text.trim(),
        username: _usernameController.text.trim(),
        password: _passwordController.text,
        deviceId:
            _config?.deviceId ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        deviceName: _deviceNameController.text.trim(),
        autoSync: _autoSync,
        syncInterval: _syncInterval,
        syncOnChange: _syncOnChange,
        syncOnStart: _syncOnStart,
        token: _config?.token,
        userId: _config?.userId,
        salt: _config?.salt,
        syncDirs: _selectedSyncDirs,
      );

      await config.save();
      _config = config;

      // 重新加载文件监听服务
      await fileWatchSyncService.reload();

      if (!mounted) return;
      toastService.showToast('server_sync_settingsSaved'.tr);
    } catch (e) {
      if (!mounted) return;
      toastService.showToast('${'server_sync_saveFailed'.tr}: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final serverUrl = _serverController.text.trim();
      final deviceId =
          _config?.deviceId ?? DateTime.now().millisecondsSinceEpoch.toString();

      final response = await http.post(
        Uri.parse('$serverUrl/api/v1/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': _usernameController.text.trim(),
          'password': _passwordController.text,
          'device_id': deviceId,
          'device_name': _deviceNameController.text.trim(),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token'] as String;
        final userId = data['user_id'] as String;
        final salt = data['user_salt'] as String;

        // 保存配置和认证信息
        final config = ServerSyncConfig(
          server: serverUrl,
          username: _usernameController.text.trim(),
          password: _passwordController.text,
          deviceId: deviceId,
          deviceName: _deviceNameController.text.trim(),
          autoSync: _autoSync,
          syncInterval: _syncInterval,
          syncOnChange: _syncOnChange,
          syncOnStart: _syncOnStart,
          token: token,
          userId: userId,
          salt: salt,
          syncDirs: _selectedSyncDirs,
        );
        await config.save();
        _config = config;

        await _initSyncService();
        _startAutoSyncIfEnabled();

        // 启动文件监听服务
        await fileWatchSyncService.reload();

        setState(() {
          _isLoggedIn = true;
        });

        if (!mounted) return;
        toastService.showToast('server_sync_loginSuccess'.tr);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? '登录失败');
      }
    } catch (e) {
      if (!mounted) return;
      toastService.showToast(
        '${'server_sync_loginFailed'.tr}: ${e.toString()}',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final serverUrl = _serverController.text.trim();
      final deviceId = DateTime.now().millisecondsSinceEpoch.toString();

      final response = await http.post(
        Uri.parse('$serverUrl/api/v1/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': _usernameController.text.trim(),
          'password': _passwordController.text,
          'device_id': deviceId,
          'device_name': _deviceNameController.text.trim(),
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final token = data['token'] as String;
        final userId = data['user_id'] as String;
        final salt = data['user_salt'] as String;

        // 保存配置和认证信息
        final config = ServerSyncConfig(
          server: serverUrl,
          username: _usernameController.text.trim(),
          password: _passwordController.text,
          deviceId: deviceId,
          deviceName: _deviceNameController.text.trim(),
          autoSync: _autoSync,
          syncInterval: _syncInterval,
          syncOnChange: _syncOnChange,
          syncOnStart: _syncOnStart,
          token: token,
          userId: userId,
          salt: salt,
          syncDirs: _selectedSyncDirs,
        );
        await config.save();
        _config = config;

        await _initSyncService();
        _startAutoSyncIfEnabled();

        // 启动文件监听服务
        await fileWatchSyncService.reload();

        setState(() {
          _isLoggedIn = true;
        });

        if (!mounted) return;
        toastService.showToast('server_sync_registerSuccess'.tr);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? '注册失败');
      }
    } catch (e) {
      if (!mounted) return;
      toastService.showToast(
        '${'server_sync_registerFailed'.tr}: ${e.toString()}',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _autoSyncTimer?.cancel();

      // 断开 WebSocket 连接
      SyncWebSocketService().disconnect();
      _isWsConnected = false;

      _syncService?.logout();
      await _config?.clearAuthInfo();

      // 停止文件监听服务
      await fileWatchSyncService.dispose();

      setState(() {
        _isLoggedIn = false;
      });

      if (!mounted) return;
      toastService.showToast('server_sync_logoutSuccess'.tr);
    } catch (e) {
      if (!mounted) return;
      toastService.showToast(
        '${'server_sync_logoutFailed'.tr}: ${e.toString()}',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _performSync() async {
    if (_syncService == null || !_isLoggedIn) {
      toastService.showToast('server_sync_notLoggedIn'.tr);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final results = await _syncService!.fullSync();

      int successCount = 0;
      int errorCount = 0;
      int conflictCount = 0;

      for (final result in results) {
        switch (result.type) {
          case SyncResultType.success:
            successCount++;
            break;
          case SyncResultType.error:
            errorCount++;
            break;
          case SyncResultType.conflictResolved:
            conflictCount++;
            break;
          default:
            break;
        }
      }

      if (!mounted) return;
      toastService.showToast(
        'server_sync_syncComplete'.trParams({
          'success': successCount.toString(),
          'conflict': conflictCount.toString(),
          'error': errorCount.toString(),
        }),
      );
    } catch (e) {
      if (!mounted) return;
      toastService.showToast('${'server_sync_syncFailed'.tr}: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// 显示强制同步到服务端的确认对话框
  Future<void> _showForceSyncToServerConfirm() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.warning, color: Colors.orange),
                SizedBox(width: 8),
                Text('server_sync_forceToServerConfirmTitle'.tr),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('server_sync_forceToServerDesc'.tr),
                const SizedBox(height: 12),
                ...[
                  'server_sync_forceToServerAction1'.tr,
                  'server_sync_forceToServerAction2'.tr,
                ].map(
                  (text) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '• ',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Expanded(child: Text(text)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber, color: Colors.red, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'server_sync_forceSyncWarning'.tr,
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                child: Text('server_sync_cancel'.tr),
                onPressed: () => Navigator.pop(context, false),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
                child: Text('server_sync_confirmSync'.tr),
                onPressed: () => Navigator.pop(context, true),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      await _performForceSyncToServer();
    }
  }

  /// 显示强制同步到客户端的确认对话框
  Future<void> _showForceSyncToClientConfirm() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.warning, color: Colors.blue),
                SizedBox(width: 8),
                Text('server_sync_forceToClientConfirmTitle'.tr),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('server_sync_forceToClientDesc'.tr),
                const SizedBox(height: 12),
                ...[
                  'server_sync_forceToClientAction1'.tr,
                  'server_sync_forceToClientAction2'.tr,
                ].map(
                  (text) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '• ',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Expanded(child: Text(text)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber, color: Colors.red, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'server_sync_forceSyncWarning'.tr,
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                child: Text('server_sync_cancel'.tr),
                onPressed: () => Navigator.pop(context, false),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: Text('server_sync_confirmSync'.tr),
                onPressed: () => Navigator.pop(context, true),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      await _performForceSyncToClient();
    }
  }

  /// 执行强制同步到服务端
  Future<void> _performForceSyncToServer() async {
    if (_syncService == null || !_isLoggedIn) {
      toastService.showToast('server_sync_notLoggedIn'.tr);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _syncService!.forceSyncToServer();

      if (!mounted) return;
      toastService.showToast(
        'server_sync_forceSyncToServerComplete'.trParams({
          'uploaded': result.uploaded.toString(),
          'deleted': result.deleted.toString(),
          'errors': result.errors.length.toString(),
        }),
      );
    } catch (e) {
      if (!mounted) return;
      toastService.showToast('${'server_sync_syncFailed'.tr}: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// 执行强制同步到客户端
  Future<void> _performForceSyncToClient() async {
    if (_syncService == null || !_isLoggedIn) {
      toastService.showToast('server_sync_notLoggedIn'.tr);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _syncService!.forceSyncToClient();

      if (!mounted) return;
      toastService.showToast(
        'server_sync_forceSyncToClientComplete'.trParams({
          'downloaded': result.downloaded.toString(),
          'deleted': result.deleted.toString(),
          'errors': result.errors.length.toString(),
        }),
      );
    } catch (e) {
      if (!mounted) return;
      toastService.showToast('${'server_sync_syncFailed'.tr}: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _testConnection() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final serverUrl = _serverController.text.trim();
      final response = await http
          .get(Uri.parse('$serverUrl/health'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        if (!mounted) return;
        toastService.showToast('server_sync_connectionSuccess'.tr);
      } else {
        throw Exception('服务器响应异常: ${response.statusCode}');
      }
    } catch (e) {
      if (!mounted) return;
      toastService.showToast(
        '${'server_sync_connectionFailed'.tr}: ${e.toString()}',
      );
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
            // 标题
            Row(
              children: [
                const Icon(Icons.sync),
                const SizedBox(width: 8),
                Text(
                  'server_sync_title'.tr,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                if (_isLoggedIn) ...[
                  // WebSocket 连接状态
                  if (_isWsConnected)
                    Tooltip(
                      message: 'server_sync_wsConnected'.tr,
                      child: const Icon(Icons.cloud_done, color: Colors.green, size: 18),
                    )
                  else
                    Tooltip(
                      message: 'server_sync_wsDisconnected'.tr,
                      child: const Icon(Icons.cloud_off, color: Colors.grey, size: 18),
                    ),
                  const SizedBox(width: 8),
                  Chip(
                    label: Text('server_sync_loggedIn'.tr),
                    backgroundColor: Colors.green.withOpacity(0.2),
                    labelStyle: const TextStyle(color: Colors.green),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),

            // 表单
            Form(
              key: _formKey,
              child: Column(
                children: [
                  // 服务器地址
                  TextFormField(
                    controller: _serverController,
                    decoration: InputDecoration(
                      labelText: 'server_sync_serverAddress'.tr,
                      hintText: 'http://localhost:8080',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.network_check),
                        onPressed: _isLoading ? null : _testConnection,
                        tooltip: 'server_sync_testConnection'.tr,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'server_sync_serverAddressRequired'.tr;
                      }
                      if (!value.startsWith('http://') &&
                          !value.startsWith('https://')) {
                        return 'server_sync_serverAddressInvalid'.tr;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // 用户名
                  TextFormField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      labelText: 'server_sync_username'.tr,
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'server_sync_usernameRequired'.tr;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // 密码
                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    decoration: InputDecoration(
                      labelText: 'server_sync_password'.tr,
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
                        return 'server_sync_passwordRequired'.tr;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // 设备名称
                  TextFormField(
                    controller: _deviceNameController,
                    decoration: InputDecoration(
                      labelText: 'server_sync_deviceName'.tr,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 登录/注册按钮
                  if (!_isLoggedIn) ...[
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _login,
                            child: Text('server_sync_login'.tr),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isLoading ? null : _register,
                            child: Text('server_sync_register'.tr),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    // 已登录状态的操作
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _saveConfig,
                            child: Text('server_sync_saveSettings'.tr),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isLoading ? null : _logout,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                            child: Text('server_sync_logout'.tr),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // 同步设置（仅已登录时显示）
            if (_isLoggedIn) ...[
              const Divider(height: 32),

              // 加密密钥展示
              Card(
                color: Colors.orange.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.vpn_key, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'server_sync_encryptionKey'.tr,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'server_sync_encryptionKeyHint'.tr,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.orange.shade700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: SelectableText(
                                _syncService?.encryption.encryptionKeyBase64 ??
                                    'N/A',
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy, size: 20),
                              tooltip: 'server_sync_copyKey'.tr,
                              onPressed: () {
                                final key =
                                    _syncService
                                        ?.encryption
                                        .encryptionKeyBase64;
                                if (key != null) {
                                  Clipboard.setData(ClipboardData(text: key));
                                  toastService.showToast(
                                    'server_sync_keyCopied'.tr,
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Divider(height: 32),
              Text(
                'server_sync_syncSettings'.tr,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),

              // 自动同步
              SwitchListTile(
                title: Text('server_sync_autoSync'.tr),
                subtitle: Text('server_sync_autoSyncSubtitle'.tr),
                value: _autoSync,
                onChanged: (value) {
                  setState(() {
                    _autoSync = value;
                  });
                  _startAutoSyncIfEnabled();
                },
              ),

              // 同步间隔
              if (_autoSync)
                ListTile(
                  title: Text('server_sync_syncInterval'.tr),
                  subtitle: Text('$_syncInterval ${'server_sync_minutes'.tr}'),
                  trailing: SizedBox(
                    width: 150,
                    child: Slider(
                      value: _syncInterval.toDouble(),
                      min: 5,
                      max: 120,
                      divisions: 23,
                      label: '$_syncInterval',
                      onChanged: (value) {
                        setState(() {
                          _syncInterval = value.toInt();
                        });
                      },
                      onChangeEnd: (_) {
                        _startAutoSyncIfEnabled();
                      },
                    ),
                  ),
                ),

              // 文件修改时同步
              SwitchListTile(
                title: Text('server_sync_syncOnChange'.tr),
                subtitle: Text('server_sync_syncOnChangeSubtitle'.tr),
                value: _syncOnChange,
                onChanged: (value) {
                  setState(() {
                    _syncOnChange = value;
                  });
                },
              ),

              // 启动时同步
              SwitchListTile(
                title: Text('server_sync_syncOnStart'.tr),
                subtitle: Text('server_sync_syncOnStartSubtitle'.tr),
                value: _syncOnStart,
                onChanged: (value) {
                  setState(() {
                    _syncOnStart = value;
                  });
                },
              ),

              // 同步目录选择
              ExpansionTile(
                title: Text('server_sync_syncDirs'.tr),
                subtitle: Text(
                  '${'server_sync_selected'.tr}: ${_selectedSyncDirs.length}',
                ),
                children:
                    ServerSyncConfig.availableSyncDirs.map((dir) {
                      return CheckboxListTile(
                        title: Text(dir),
                        value: _selectedSyncDirs.contains(dir),
                        onChanged: (value) {
                          setState(() {
                            if (value == true) {
                              _selectedSyncDirs.add(dir);
                            } else {
                              _selectedSyncDirs.remove(dir);
                            }
                          });
                        },
                      );
                    }).toList(),
              ),

              const Divider(height: 32),

              // 手动同步按钮
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _performSync,
                      icon: const Icon(Icons.sync),
                      label: Text('server_sync_syncNow'.tr),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // 强制同步按钮
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed:
                          _isLoading ? null : _showForceSyncToServerConfirm,
                      icon: const Icon(Icons.cloud_upload),
                      label: Text('server_sync_forceToServer'.tr),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed:
                          _isLoading ? null : _showForceSyncToClientConfirm,
                      icon: const Icon(Icons.cloud_download),
                      label: Text('server_sync_forceToClient'.tr),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],

            // 加载指示器
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

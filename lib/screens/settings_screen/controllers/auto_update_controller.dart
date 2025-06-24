import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:Memento/core/utils/network.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class AutoUpdateController extends ChangeNotifier {
  BuildContext? context;
  static AutoUpdateController? _instance;

  static AutoUpdateController get instance {
    return _instance ??= AutoUpdateController._();
  }

  // 私有构造函数
  AutoUpdateController._();

  // 公开构造函数，用于设置界面
  factory AutoUpdateController(BuildContext context) {
    instance.context = context;
    return instance;
  }
  bool _autoCheckUpdate = false;
  String _latestVersion = '';
  String _currentVersion = '';
  String _releaseNotes = '';
  String _releaseUrl = '';
  bool _checking = false;

  // 初始化方法，由main.dart调用
  Future<void> initialize() async {
    // 在后台执行初始化
    Future(() async {
      await _init();
    });
  }

  Future<void> _init() async {
    await Future.wait([_loadSettings(), _getCurrentVersion()]);
    // 如果启用了自动检查更新，则在初始化后执行检查
    if (!_autoCheckUpdate) {
      return;
    }

    // 延迟几秒再检查，避免应用启动时立即执行网络请求
    await Future.delayed(const Duration(seconds: 2));

    // 检查上下文是否有效
    if (context == null || !context!.mounted) {
      return;
    }

    debugPrint('AutoUpdateController: 开始检查更新');
    // 在后台执行更新检查
    Future(() async {
      try {
        final hasUpdate = await checkForUpdates();
        if (!context!.mounted) return;

        if (hasUpdate) {
          // 确保在主线程中显示对话框
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context?.mounted ?? false) {
              showUpdateDialog(skipCheck: true);
            }
          });
        }
      } catch (e) {
        debugPrint('AutoUpdateController: 检查更新失败 - $e');
      }
    });
  }

  bool get autoCheckUpdate => _autoCheckUpdate;
  String get latestVersion => _latestVersion;
  String get currentVersion => _currentVersion;
  String get releaseNotes => _releaseNotes;
  String get releaseUrl => _releaseUrl;
  bool get checking => _checking;

  set autoCheckUpdate(bool value) {
    _autoCheckUpdate = value;
    _saveSettings();
    notifyListeners();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _autoCheckUpdate = prefs.getBool('autoCheckUpdate') ?? false;
    notifyListeners();
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('autoCheckUpdate', _autoCheckUpdate);
  }

  Future<void> _getCurrentVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    _currentVersion = packageInfo.version;
    notifyListeners();
  }

  Future<bool> checkForUpdates() async {
    if (_checking) return false;

    _checking = true;
    notifyListeners();

    final client = await createClientWithSystemProxy();
    try {
      final response = await client.get(
        Uri.parse(
          'https://api.github.com/repos/hunmer/Memento/releases/latest',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _latestVersion = data['tag_name'].toString().replaceAll('v', '');
        _releaseNotes = data['body'] ?? '';
        _releaseUrl = data['html_url'] ?? '';
        debugPrint('AutoUpdateController: 获取到最新版本：$_latestVersion');
        final hasUpdate = _isNewerVersion(_latestVersion, _currentVersion);
        debugPrint(
          'AutoUpdateController: 版本比较 - 当前版本：$_currentVersion，最新版本：$_latestVersion，需要更新：$hasUpdate',
        );
        _checking = false;
        notifyListeners();
        return hasUpdate;
      }

      _checking = false;
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('Error checking for updates: $e');
      if (context?.mounted ?? false) {
        ScaffoldMessenger.of(context!).showSnackBar(
          SnackBar(
            content: Text('检查更新失败: ${e.toString()}'),
            duration: const Duration(seconds: 3),
            backgroundColor: Theme.of(context!).colorScheme.error,
          ),
        );
      }
    } finally {
      client.close();
    }

    _checking = false;
    notifyListeners();
    return false;
  }

  bool _isNewerVersion(String latest, String current) {
    List<int> latestParts = latest.split('.').map(int.parse).toList();
    List<int> currentParts = current.split('.').map(int.parse).toList();

    for (int i = 0; i < 3; i++) {
      final latestPart = latestParts.length > i ? latestParts[i] : 0;
      final currentPart = currentParts.length > i ? currentParts[i] : 0;

      if (latestPart > currentPart) return true;
      if (latestPart < currentPart) return false;
    }

    return false;
  }

  Future<void> openReleasePage() async {
    if (_releaseUrl.isEmpty) return;

    final Uri url = Uri.parse(_releaseUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  // 防止多次显示更新对话框
  bool _isShowingUpdateDialog = false;

  Future<void> showUpdateDialog({bool skipCheck = false}) async {
    // 如果已经在显示更新对话框，则不再显示
    if (_isShowingUpdateDialog) {
      return;
    }

    _isShowingUpdateDialog = true;
    bool hasUpdate = false;

    try {
      // 如果skipCheck为true，表示已经检查过有更新，直接显示对话框
      if (skipCheck) {
        hasUpdate = true;
      } else {
        hasUpdate = await checkForUpdates();
      }

      if (context == null || !context!.mounted) return;

      if (!hasUpdate) {
        if (context != null) {
          ScaffoldMessenger.of(context!).showSnackBar(
            const SnackBar(
              content: Text('当前已是最新版本'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      if (context == null) return;

      showDialog(
        context: context!,
        builder:
            (context) => AlertDialog(
              title: const Text('发现新版本'),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('当前版本: $_currentVersion'),
                    Text('最新版本: $_latestVersion'),
                    const SizedBox(height: 16),
                    const Text('更新内容:'),
                    const SizedBox(height: 8),
                    Text(_releaseNotes),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('稍后再说'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    openReleasePage();
                  },
                  child: const Text('查看更新'),
                ),
              ],
            ),
      );
    } catch (e) {
      if (context?.mounted ?? false) {
        ScaffoldMessenger.of(context!).showSnackBar(
          SnackBar(
            content: Text('检查更新时出错: ${e.toString()}'),
            duration: const Duration(seconds: 3),
            backgroundColor: Theme.of(context!).colorScheme.error,
          ),
        );
      }
    } finally {
      _isShowingUpdateDialog = false;
    }
  }
}

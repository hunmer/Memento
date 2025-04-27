import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
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
  bool _autoCheckUpdate = true;
  String _latestVersion = '';
  String _currentVersion = '';
  String _releaseNotes = '';
  String _releaseUrl = '';
  bool _checking = false;

  // 初始化方法，由main.dart调用
  Future<void> initialize() async {
    debugPrint('AutoUpdateController: 初始化开始');
    // 在后台执行初始化
    Future(() async {
      try {
        await _init();
      } catch (e) {
        debugPrint('AutoUpdateController: 初始化失败 - $e');
      }
    });
  }

  Future<void> _init() async {
    debugPrint('AutoUpdateController: 开始加载设置');
    // 并行加载设置和当前版本
    await Future.wait([
      _loadSettings(),
      _getCurrentVersion(),
    ]);
    
    debugPrint('AutoUpdateController: 设置加载完成，autoCheckUpdate=$_autoCheckUpdate');
    debugPrint('AutoUpdateController: 当前版本获取完成，currentVersion=$_currentVersion');
    
    // 如果启用了自动检查更新，则在初始化后执行检查
    if (!_autoCheckUpdate) {
      debugPrint('AutoUpdateController: 自动更新已禁用');
      return;
    }

    debugPrint('AutoUpdateController: 自动更新已启用，准备检查更新');
    // 延迟几秒再检查，避免应用启动时立即执行网络请求
    await Future.delayed(const Duration(seconds: 2));
    
    // 检查上下文是否有效
    if (context == null || !context!.mounted) {
      debugPrint('AutoUpdateController: context未设置或已失效，取消检查更新');
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
    _autoCheckUpdate = prefs.getBool('autoCheckUpdate') ?? true;
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

  Future<http.Client> _createClientWithSystemProxy() async {
    // 创建一个自定义的 HttpClient 来明确应用代理设置
    final httpClient = HttpClient();
    
    // 获取系统代理设置
    final httpProxy = Platform.environment['HTTP_PROXY'] ?? 
                     Platform.environment['http_proxy'];
    final httpsProxy = Platform.environment['HTTPS_PROXY'] ?? 
                      Platform.environment['https_proxy'];
    
    // 用于调试的日志
    if (httpProxy != null && httpProxy.isNotEmpty) {
      debugPrint('System HTTP proxy detected: $httpProxy');
    }
    
    if (httpsProxy != null && httpsProxy.isNotEmpty) {
      debugPrint('System HTTPS proxy detected: $httpsProxy');
    }
    
    // 明确设置代理
    if ((httpProxy != null && httpProxy.isNotEmpty) || 
        (httpsProxy != null && httpsProxy.isNotEmpty)) {
      try {
        final proxyUrl = httpsProxy ?? httpProxy;
        if (proxyUrl != null) {
          // 解析代理URL
          Uri proxyUri = Uri.parse(proxyUrl);
          
          // 设置代理
          httpClient.findProxy = (uri) {
            final host = proxyUri.host;
            final port = proxyUri.port;
            debugPrint('Using proxy for $uri: $host:$port');
            return 'PROXY $host:$port';
          };
          
          // 如果代理需要认证
          if (proxyUri.userInfo.isNotEmpty) {
            List<String> userInfo = proxyUri.userInfo.split(':');
            if (userInfo.length == 2) {
              // 正确处理认证回调的类型
              httpClient.authenticate = (Uri url, String scheme, String? realm) {
                debugPrint('Authenticating proxy with username: ${userInfo[0]}');
                // 设置凭据并返回true表示已提供凭据
                httpClient.addCredentials(
                  url,
                  realm ?? '',
                  HttpClientBasicCredentials(userInfo[0], userInfo[1])
                );
                return Future.value(true);
              };
            }
          }
        }
      } catch (e) {
        debugPrint('Error setting proxy: $e');
      }
    }
    
    // 允许自签名证书，如果代理使用自签名证书
    httpClient.badCertificateCallback = (cert, host, port) => true;
    
    // 创建一个基于自定义HttpClient的http客户端
    return IOClient(httpClient);
  }

  Future<bool> checkForUpdates() async {
    if (_checking) return false;
    
    _checking = true;
    notifyListeners();

    final client = await _createClientWithSystemProxy();
    try {
      final response = await client.get(
        Uri.parse('https://api.github.com/repos/hunmer/Memento/releases/latest'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _latestVersion = data['tag_name'].toString().replaceAll('v', '');
        _releaseNotes = data['body'] ?? '';
        _releaseUrl = data['html_url'] ?? '';
        debugPrint('AutoUpdateController: 获取到最新版本：$_latestVersion');
        final hasUpdate = _isNewerVersion(_latestVersion, _currentVersion);
        debugPrint('AutoUpdateController: 版本比较 - 当前版本：$_currentVersion，最新版本：$_latestVersion，需要更新：$hasUpdate');
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
      debugPrint('AutoUpdateController: 更新对话框已在显示中，跳过');
      return;
    }
    
    debugPrint('AutoUpdateController: 准备显示更新对话框');
    _isShowingUpdateDialog = true;
    bool hasUpdate = false;
    
    try {
      // 如果skipCheck为true，表示已经检查过有更新，直接显示对话框
      if (skipCheck) {
        debugPrint('AutoUpdateController: 跳过检查，直接显示更新对话框');
        hasUpdate = true;
      } else {
        debugPrint('AutoUpdateController: 显示对话框前再次检查更新');
        hasUpdate = await checkForUpdates();
      }
      
      if (context == null || !context!.mounted) return;

      if (!hasUpdate) {
        debugPrint('AutoUpdateController: 没有新版本可用');
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
      
      debugPrint('AutoUpdateController: 发现新版本，显示更新对话框');

      if (context == null) return;
      
      showDialog(
      context: context!,
      builder: (context) => AlertDialog(
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
      debugPrint('Error in showUpdateDialog: $e');
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
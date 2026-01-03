import 'dart:convert';
import 'dart:io'
    show File, Directory, FileSystemEntity, FileSystemEntityType;
import 'package:universal_platform/universal_platform.dart';
import 'dart:math' show min;
import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' as path;
import 'package:Memento/plugins/base_plugin.dart';
import 'package:Memento/core/js_bridge/js_bridge_plugin.dart';
import 'package:Memento/core/js_bridge/js_bridge_manager.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/core/services/plugin_data_selector/index.dart';

import 'models/webview_card.dart';
import 'models/webview_settings.dart';
import 'services/tab_manager.dart';
import 'services/card_manager.dart';
import 'services/proxy_controller_service.dart';
import 'services/local_http_server.dart';
import 'services/app_store_manager.dart';
import 'services/download_manager.dart';
import 'screens/webview_main_screen.dart';
import 'screens/webview_settings_screen.dart';

/// WebView 插件
///
/// 支持：
/// - 多标签页浏览
/// - 网址卡片管理（在线/本地）
/// - Memento JS Bridge 集成
class WebViewPlugin extends BasePlugin with ChangeNotifier, JSBridgePlugin {
  static WebViewPlugin? _instance;

  static WebViewPlugin get instance {
    _instance ??= PluginManager.instance.getPlugin('webview') as WebViewPlugin?;
    if (_instance == null) {
      throw StateError('WebViewPlugin has not been initialized');
    }
    return _instance!;
  }

  // Services
  late final TabManager tabManager;
  late final CardManager cardManager;
  late final ProxyControllerService proxyController;
  late final LocalHttpServer localHttpServer;
  late final AppStoreManager appStoreManager;
  late final DownloadManager downloadManager;
  late WebViewSettings webviewSettings;

  /// 待复制的文件列表（用于 Android 11+ 的文件访问）
  List<String>? pendingFilesToCopy;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  @override
  String get id => 'webview';

  @override
  Color get color => const Color(0xFF4285F4); // Google Blue

  @override
  IconData get icon => Icons.language;

  @override
  String? getPluginName(context) => 'webview_name'.tr;

  @override
  Future<void> initialize() async {
    // 初始化服务
    tabManager = TabManager(maxTabs: 10);
    cardManager = CardManager(storage);
    proxyController = ProxyControllerService();
    localHttpServer = LocalHttpServer();

    // 初始化应用商场管理器
    appStoreManager = AppStoreManager(
      storage: storage,
      cardManager: cardManager,
    );

    // 初始化下载管理器
    downloadManager = DownloadManager(
      storage: storage,
      cardManager: cardManager,
      appStoreManager: appStoreManager,
    );

    // 检查 proxy 支持
    await proxyController.checkSupport();

    // 加载设置
    await _loadSettings();

    // 应用 proxy 配置（如果支持）
    if (proxyController.isSupported) {
      await proxyController.applyProxySettings(webviewSettings.proxySettings);
    }

    // 初始化卡片服务
    await cardManager.initialize();

    // 初始化应用商场
    await appStoreManager.initialize();

    // 恢复标签页状态
    if (webviewSettings.restoreTabsOnStartup) {
      await _restoreTabs();
    }

    // 在非 Web 平台启动本地 HTTP 服务器（主要用于 Windows）
    if (!kIsWeb) {
      await _startLocalHttpServer();
    }

    _isInitialized = true;
    _instance = this;

    // 注册 JS API
    await registerJSAPI();

    // 等待 JSBridgeManager 完全初始化
    print('[WebViewPlugin] 等待 JSBridgeManager 初始化...');
    final jsBridge = JSBridgeManager.instance;

    // 等待引擎初始化完成
    int retryCount = 0;
    while (!jsBridge.isSupported && retryCount < 50) {
      await Future.delayed(Duration(milliseconds: 100));
      retryCount++;
      print('[WebViewPlugin] 等待初始化... ($retryCount/50)');
    }

    if (jsBridge.isSupported) {
      print('[WebViewPlugin] ✓ JSBridgeManager 初始化完成');
    } else {
      print('[WebViewPlugin] ✗ JSBridgeManager 初始化超时');
      throw Exception('JSBridgeManager 初始化失败');
    }

    // 加载所有卡片的 preload.js 并注册工具
    await _loadPreloadScripts();

    // 注册数据选择器
    _registerDataSelectors();
  }

  /// 注册数据选择器
  void _registerDataSelectors() {
    pluginDataSelectorService.registerSelector(
      SelectorDefinition(
        id: 'webview.card',
        pluginId: 'webview',
        name: 'webview_cardSelectorName'.tr,
        description: 'webview_cardSelectorDesc'.tr,
        icon: Icons.link,
        color: color,
        selectionMode: SelectionMode.single,
        steps: [
          SelectorStep(
            id: 'select_card',
            title: 'webview_selectCard'.tr,
            viewType: SelectorViewType.list,
            dataLoader: (previousSelections) async {
              // 加载所有卡片
              final cards = cardManager.getAllCards();
              return cards.map((card) => SelectableItem(
                id: card.id,
                title: card.title,
                subtitle: card.url,
                icon: Icons.language,
                color: card.type == CardType.localFile ? Colors.green : null,
                rawData: card.toJson(),
              )).toList();
            },
            isFinalStep: true,
          ),
        ],
      ),
    );
  }

  /// 加载所有卡片的 preload.js 文件
  Future<void> _loadPreloadScripts() async {
    try {
      print('[WebViewPlugin] ========== 开始加载 preload.js 脚本 ==========');

      final jsBridge = JSBridgeManager.instance;
      print('[WebViewPlugin] JSBridgeManager 实例获取成功');

      final cards = cardManager.getAllCards();
      print('[WebViewPlugin] 总共有 ${cards.length} 个卡片');

      if (cards.isEmpty) {
        print('[WebViewPlugin] 没有卡片，跳过 preload.js 加载');
        return;
      }

      for (final card in cards) {
        print('[WebViewPlugin] ----------------------------------------');
        print('[WebViewPlugin] 检查卡片: ${card.title}, 类型: ${card.type}');

        if (card.type == CardType.localFile) {
          // 获取卡片对应的 HTTP 服务器路径
          final cardPath = await cardManager.getCardPath(card);
          print('[WebViewPlugin] 卡片 "${card.title}" 的路径: $cardPath');

          final preloadFile = File('$cardPath/preload.js');
          print('[WebViewPlugin] preload.js 文件路径: ${preloadFile.path}');

          if (await preloadFile.exists()) {
            print('[WebViewPlugin] ✓ preload.js 文件存在，开始加载...');
            // 读取 preload.js 内容
            final scriptContent = await preloadFile.readAsString();
            print(
              '[WebViewPlugin] preload.js 内容长度: ${scriptContent.length} 字符',
            );
            print(
              '[WebViewPlugin] preload.js 内容预览: ${scriptContent.substring(0, min(100, scriptContent.length))}...',
            );

            // 在 QuickJS 引擎中执行脚本（如果 JS Bridge 未初始化，会自动加入延迟队列）
            try {
              print('[WebViewPlugin] >>> 开始在 QuickJS 中执行 preload.js...');
              final result = await jsBridge.evaluateWhenReady(
                scriptContent,
                description: 'preload.js: ${card.title}',
              );
              print(
                '[WebViewPlugin] <<< QuickJS 执行完成，结果: ${result.success ? '成功' : '失败'}',
              );
              if (!result.success) {
                print('[WebViewPlugin] 执行错误: ${result.error}');
              }
              print('[WebViewPlugin] ✓ 已成功加载 preload.js: ${card.title}');
            } catch (e) {
              print('[WebViewPlugin] ✗ 加载 preload.js 失败: ${card.title}');
              print('[WebViewPlugin] 错误详情: $e');
              print('[WebViewPlugin] 错误类型: ${e.runtimeType}');
            }
          } else {
            print('[WebViewPlugin] ✗ preload.js 文件不存在');
          }
        } else {
          print('[WebViewPlugin] 跳过非本地文件类型的卡片');
        }
      }
      print('[WebViewPlugin] ========== preload.js 加载流程完成 ==========');
    } catch (e) {
      print('[WebViewPlugin] ✗ 加载 preload.js 脚本时发生错误: $e');
      print('[WebViewPlugin] 错误类型: ${e.runtimeType}');
      print('[WebViewPlugin] 错误堆栈: ${StackTrace.current}');
    }
  }

  /// 加载设置
  Future<void> _loadSettings() async {
    try {
      final data = await storage.read('webview/settings.json');
      if (data != null) {
        webviewSettings = WebViewSettings.fromJson(
          data as Map<String, dynamic>,
        );
      } else {
        webviewSettings = WebViewSettings();
      }
    } catch (e) {
      webviewSettings = WebViewSettings();
    }
  }

  /// 保存设置
  Future<void> saveWebviewSettings() async {
    await storage.write('webview/settings.json', webviewSettings.toJson());

    // 重新应用 proxy 配置
    if (proxyController.isSupported) {
      await proxyController.applyProxySettings(webviewSettings.proxySettings);
    }

    notifyListeners();
  }

  /// 恢复标签页
  Future<void> _restoreTabs() async {
    try {
      final data = await storage.read('webview/tabs.json');
      if (data != null && data is List) {
        await tabManager.restoreFromJson(data);
      }
    } catch (e) {
      debugPrint('恢复标签页失败: $e');
    }
  }

  /// 保存标签页状态
  Future<void> saveTabs() async {
    final tabsJson = tabManager.toJson();
    await storage.write('webview/tabs.json', tabsJson);
  }

  /// 获取本地文件存储路径
  String get localFilesPath =>
      '${storage.getPluginStoragePath(id)}/local_files';

  /// 检查 URL 是否为本地文件
  bool isLocalFileUrl(String url) {
    return url.startsWith('file://') || url.contains(localFilesPath);
  }

  // ==================== 统计方法 ====================

  int getTotalCardsCount() => _isInitialized ? cardManager.count : 0;
  int getUrlCardsCount() => _isInitialized ? cardManager.urlCards.length : 0;
  int getLocalFileCardsCount() =>
      _isInitialized ? cardManager.localFileCards.length : 0;
  int getActiveTabsCount() => _isInitialized ? tabManager.tabCount : 0;

  // ==================== UI 构建 ====================

  @override
  Widget buildMainView(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: cardManager),
        ChangeNotifierProvider.value(value: tabManager),
        ChangeNotifierProvider.value(value: appStoreManager),
        ChangeNotifierProvider.value(value: downloadManager),
      ],
      child: const WebViewMainScreen(),
    );
  }

  @override
  Widget buildSettingsView(BuildContext context) {
    return const WebViewSettingsScreen();
  }

  @override
  Widget? buildCardView(BuildContext context) {
    if (!_isInitialized) return null;

    final theme = Theme.of(context);
    final totalCards = getTotalCardsCount();
    final activeTabs = getActiveTabsCount();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 24, color: color),
              ),
              const SizedBox(width: 12),
              Text(
                'webview_name'.tr,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  Text('webview_cards'.tr, style: theme.textTheme.bodyMedium),
                  Text(
                    '$totalCards',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  Text('webview_tabs'.tr, style: theme.textTheme.bodyMedium),
                  Text(
                    '$activeTabs',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== JS API ====================

  @override
  Map<String, Function> defineJSAPI() {
    return {
      // 卡片管理
      'getCards': _jsGetCards,
      'addCard': _jsAddCard,
      'deleteCard': _jsDeleteCard,
      'updateCard': _jsUpdateCard,
      'findCardById': _jsFindCardById,
      'findCardByUrl': _jsFindCardByUrl,

      // 标签页管理
      'getTabs': _jsGetTabs,
      'createTab': _jsCreateTab,
      'closeTab': _jsCloseTab,
      'switchTab': _jsSwitchTab,

      // 导航
      'navigate': _jsNavigate,
      'goBack': _jsGoBack,
      'goForward': _jsGoForward,
      'reload': _jsReload,
    };
  }

  Future<String> _jsGetCards(Map<String, dynamic> params) async {
    if (!_isInitialized) return jsonEncode({'error': '插件未初始化'});
    return jsonEncode(cardManager.cards.map((c) => c.toJson()).toList());
  }

  Future<String> _jsAddCard(Map<String, dynamic> params) async {
    if (!_isInitialized) return jsonEncode({'error': '插件未初始化'});

    final title = params['title'] as String?;
    final url = params['url'] as String?;
    final type = params['type'] as String? ?? 'url';

    if (title == null || url == null) {
      return jsonEncode({'error': '缺少必需参数: title, url'});
    }

    final card = await cardManager.addCard(
      title: title,
      url: url,
      type: type == 'localFile' ? CardType.localFile : CardType.url,
      description: params['description'] as String?,
      tags: (params['tags'] as List<dynamic>?)?.cast<String>(),
    );

    return jsonEncode(card.toJson());
  }

  Future<String> _jsDeleteCard(Map<String, dynamic> params) async {
    if (!_isInitialized) return jsonEncode({'error': '插件未初始化'});

    final cardId = params['cardId'] as String?;
    if (cardId == null) {
      return jsonEncode({'error': '缺少必需参数: cardId'});
    }

    await cardManager.deleteCard(cardId);
    return jsonEncode({'success': true});
  }

  Future<String> _jsUpdateCard(Map<String, dynamic> params) async {
    if (!_isInitialized) return jsonEncode({'error': '插件未初始化'});

    final cardId = params['cardId'] as String?;
    if (cardId == null) {
      return jsonEncode({'error': '缺少必需参数: cardId'});
    }

    final card = cardManager.getCardById(cardId);
    if (card == null) {
      return jsonEncode({'error': '卡片不存在'});
    }

    final updatedCard = card.copyWith(
      title: params['title'] as String?,
      url: params['url'] as String?,
      description: params['description'] as String?,
    );

    await cardManager.updateCard(updatedCard);
    return jsonEncode(updatedCard.toJson());
  }

  Future<String> _jsFindCardById(Map<String, dynamic> params) async {
    if (!_isInitialized) return jsonEncode(null);

    final id = params['id'] as String?;
    if (id == null) return jsonEncode(null);

    final card = cardManager.getCardById(id);
    return jsonEncode(card?.toJson());
  }

  Future<String> _jsFindCardByUrl(Map<String, dynamic> params) async {
    if (!_isInitialized) return jsonEncode(null);

    final url = params['url'] as String?;
    if (url == null) return jsonEncode(null);

    final card = cardManager.getCardByUrl(url);
    return jsonEncode(card?.toJson());
  }

  Future<String> _jsGetTabs(Map<String, dynamic> params) async {
    if (!_isInitialized) return jsonEncode({'error': '插件未初始化'});
    return jsonEncode(tabManager.tabs.map((t) => t.toJson()).toList());
  }

  Future<String> _jsCreateTab(Map<String, dynamic> params) async {
    if (!_isInitialized) return jsonEncode({'error': '插件未初始化'});

    final url = params['url'] as String?;
    if (url == null) {
      return jsonEncode({'error': '缺少必需参数: url'});
    }

    try {
      final tab = await tabManager.createTab(
        url: url,
        title: params['title'] as String?,
        setActive: params['setActive'] as bool? ?? true,
      );
      return jsonEncode(tab.toJson());
    } catch (e) {
      return jsonEncode({'error': e.toString()});
    }
  }

  Future<String> _jsCloseTab(Map<String, dynamic> params) async {
    if (!_isInitialized) return jsonEncode({'error': '插件未初始化'});

    final tabId = params['tabId'] as String?;
    if (tabId == null) {
      return jsonEncode({'error': '缺少必需参数: tabId'});
    }

    await tabManager.closeTab(tabId);
    return jsonEncode({'success': true});
  }

  Future<String> _jsSwitchTab(Map<String, dynamic> params) async {
    if (!_isInitialized) return jsonEncode({'error': '插件未初始化'});

    final tabId = params['tabId'] as String?;
    if (tabId == null) {
      return jsonEncode({'error': '缺少必需参数: tabId'});
    }

    await tabManager.switchToTab(tabId);
    return jsonEncode({'success': true});
  }

  Future<String> _jsNavigate(Map<String, dynamic> params) async {
    if (!_isInitialized) return jsonEncode({'error': '插件未初始化'});

    final url = params['url'] as String?;
    if (url == null) {
      return jsonEncode({'error': '缺少必需参数: url'});
    }

    final tabId = tabManager.activeTabId;
    if (tabId == null) {
      return jsonEncode({'error': '没有活动的标签页'});
    }

    await tabManager.navigateTo(tabId, url);
    return jsonEncode({'success': true});
  }

  Future<String> _jsGoBack(Map<String, dynamic> params) async {
    final tabId = tabManager.activeTabId;
    if (tabId != null) {
      final success = await tabManager.goBack(tabId);
      return jsonEncode({'success': success});
    }
    return jsonEncode({'success': false, 'error': '无法后退'});
  }

  Future<String> _jsGoForward(Map<String, dynamic> params) async {
    final tabId = tabManager.activeTabId;
    if (tabId != null) {
      final success = await tabManager.goForward(tabId);
      return jsonEncode({'success': success});
    }
    return jsonEncode({'success': false, 'error': '无法前进'});
  }

  Future<String> _jsReload(Map<String, dynamic> params) async {
    final tabId = tabManager.activeTabId;
    if (tabId != null) {
      await tabManager.reload(tabId);
      return jsonEncode({'success': true});
    }
    return jsonEncode({'success': false, 'error': '没有活动的标签页'});
  }

  // ==================== 本地 HTTP 服务器管理 ====================

  /// 启动本地 HTTP 服务器
  Future<void> _startLocalHttpServer() async {
    // 使用统一的 HTTP 服务器根目录
    final rootDir = await getHttpServerRootDir();

    debugPrint('[WebViewPlugin] 尝试启动本地 HTTP 服务器，根目录: $rootDir');

    final success = await localHttpServer.start(rootDir: rootDir, port: 8080);

    if (success) {
      debugPrint(
        '[WebViewPlugin] 本地 HTTP 服务器启动成功: ${localHttpServer.serverUrl} www路径：$rootDir',
      );
    } else {
      debugPrint('[WebViewPlugin] 本地 HTTP 服务器启动失败');
    }
  }

  /// 获取 HTTP 服务器根目录
  ///
  /// 返回 app_data/webview/http_server 目录
  Future<String> getHttpServerRootDir() async {
    if (kIsWeb) {
      return 'http_server'; // Web 平台使用相对路径
    }

    // 使用 StorageManager 获取应用数据目录（包含 app_data 前缀）
    final appDataDir = await storageManager.getApplicationDataDirectory();
    final pluginPath = storageManager.getPluginStoragePath('webview');
    return path.join(appDataDir.path, pluginPath, 'http_server');
  }

  /// 复制本地文件/目录到 HTTP 服务器目录
  ///
  /// [sourcePath] 源文件或目录的绝对路径
  /// [projectName] 项目名称（将作为子目录名）
  /// 返回：复制后的相对路径（如 ./projectName/index.html）
  Future<String> copyToHttpServer({
    required String sourcePath,
    required String projectName,
  }) async {
    if (kIsWeb) {
      throw UnsupportedError('Web 平台不支持本地文件操作');
    }

    // 验证项目名称（只允许字母、数字、下划线、连字符）
    if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(projectName)) {
      throw ArgumentError('项目名称只能包含字母、数字、下划线和连字符');
    }

    final httpRoot = await getHttpServerRootDir();
    final projectDir = path.join(httpRoot, projectName);

    try {
      // 创建项目目录
      final dir = Directory(projectDir);
      if (await dir.exists()) {
        // 如果目录已存在，先删除
        await dir.delete(recursive: true);
      }
      await dir.create(recursive: true);

      // 优先使用 pendingFilesToCopy（Android 11+ SAF 方式）
      if (pendingFilesToCopy != null && pendingFilesToCopy!.isNotEmpty) {
        debugPrint('[WebViewPlugin] 使用 pendingFilesToCopy 复制 ${pendingFilesToCopy!.length} 个文件');
        await _copyFilesFromList(pendingFilesToCopy!, sourcePath, projectDir);
        pendingFilesToCopy = null; // 清空列表

        // 查找入口文件
        final entryFile = await _findEntryFile(projectDir);
        if (entryFile != null) {
          final relativePath = path.relative(entryFile, from: httpRoot);
          return './${relativePath.replaceAll(path.separator, '/')}';
        } else {
          return './$projectName/';
        }
      }

      // 传统方式：直接访问文件系统
      final source = FileSystemEntity.typeSync(sourcePath);

      if (source == FileSystemEntityType.file) {
        // 复制单个文件
        final sourceFile = File(sourcePath);
        final fileName = path.basename(sourcePath);
        final targetPath = path.join(projectDir, fileName);

        await sourceFile.copy(targetPath);
        debugPrint('[WebViewPlugin] 文件已复制: $sourcePath -> $targetPath');

        // 如果是 HTML 文件，同时复制同目录下的 preload.js（如果存在）
        if (fileName.endsWith('.html')) {
          final sourceDir = path.dirname(sourcePath);
          final preloadJsPath = path.join(sourceDir, 'preload.js');
          final preloadJsFile = File(preloadJsPath);

          if (await preloadJsFile.exists()) {
            final targetPreloadPath = path.join(projectDir, 'preload.js');
            await preloadJsFile.copy(targetPreloadPath);
            debugPrint(
              '[WebViewPlugin] preload.js 已复制: $preloadJsPath -> $targetPreloadPath',
            );
          }
        }

        // 返回相对路径
        return './$projectName/$fileName';
      } else if (source == FileSystemEntityType.directory) {
        // 复制整个目录
        await _copyDirectory(sourcePath, projectDir);
        debugPrint('[WebViewPlugin] 目录已复制: $sourcePath -> $projectDir');

        // 查找入口文件（index.html 或第一个 .html 文件）
        final entryFile = await _findEntryFile(projectDir);
        if (entryFile != null) {
          final relativePath = path.relative(entryFile, from: httpRoot);
          return './${relativePath.replaceAll(path.separator, '/')}';
        } else {
          return './$projectName/';
        }
      } else {
        throw ArgumentError('源路径不是有效的文件或目录: $sourcePath');
      }
    } catch (e) {
      debugPrint('[WebViewPlugin] 复制文件失败: $e');
      rethrow;
    }
  }

  /// 从文件列表复制文件（用于 Android 11+ SAF 方式）
  Future<void> _copyFilesFromList(
    List<String> filePaths,
    String baseSourcePath,
    String targetDir,
  ) async {
    int fileCount = 0;

    for (final filePath in filePaths) {
      try {
        final sourceFile = File(filePath);
        if (!await sourceFile.exists()) {
          debugPrint('[WebViewPlugin] 文件不存在，跳过: $filePath');
          continue;
        }

        // 计算相对路径（相对于 baseSourcePath）
        String relativePath;
        if (filePath.startsWith(baseSourcePath)) {
          relativePath = filePath.substring(baseSourcePath.length);
          if (relativePath.startsWith('/') || relativePath.startsWith('\\')) {
            relativePath = relativePath.substring(1);
          }
        } else {
          // 如果不在 baseSourcePath 下，只取文件名
          relativePath = path.basename(filePath);
        }

        final targetPath = path.join(targetDir, relativePath);

        // 确保目标目录存在
        final targetFileDir = Directory(path.dirname(targetPath));
        if (!await targetFileDir.exists()) {
          await targetFileDir.create(recursive: true);
        }

        await sourceFile.copy(targetPath);
        fileCount++;
        debugPrint('[WebViewPlugin] 文件复制成功: $relativePath');
      } catch (e) {
        debugPrint('[WebViewPlugin] 复制文件失败: $filePath, 错误: $e');
      }
    }

    debugPrint('[WebViewPlugin] 文件列表复制完成，共 $fileCount 个文件');
  }

  /// 递归复制目录
  Future<void> _copyDirectory(String sourcePath, String targetPath) async {
    final sourceDir = Directory(sourcePath);
    final targetDir = Directory(targetPath);

    // 检查源目录是否存在
    if (!await sourceDir.exists()) {
      debugPrint('[WebViewPlugin] 错误: 源目录不存在: $sourcePath');
      throw Exception('源目录不存在: $sourcePath');
    }

    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }

    // 统计文件数量
    int fileCount = 0;
    int dirCount = 0;

    try {
      final entities = await sourceDir.list(recursive: false).toList();
      debugPrint('[WebViewPlugin] 源目录包含 ${entities.length} 个项目: $sourcePath');

      for (final entity in entities) {
        final name = path.basename(entity.path);

        // 跳过隐藏文件和系统文件
        if (name.startsWith('.')) {
          debugPrint('[WebViewPlugin] 跳过隐藏文件: $name');
          continue;
        }

        if (entity is File) {
          final targetFile = path.join(targetPath, name);
          try {
            await entity.copy(targetFile);
            fileCount++;
            debugPrint('[WebViewPlugin] 文件复制成功: $name');
          } catch (e) {
            debugPrint('[WebViewPlugin] 文件复制失败: $name, 错误: $e');
            rethrow;
          }
        } else if (entity is Directory) {
          final targetSubDir = path.join(targetPath, name);
          debugPrint('[WebViewPlugin] 进入子目录: $name');
          await _copyDirectory(entity.path, targetSubDir);
          dirCount++;
        }
      }

      debugPrint('[WebViewPlugin] 目录复制完成: $sourcePath -> $targetPath (文件: $fileCount, 子目录: $dirCount)');
    } catch (e) {
      debugPrint('[WebViewPlugin] 列出目录内容失败: $sourcePath, 错误: $e');
      rethrow;
    }
  }

  /// 查找入口文件（index.html 或第一个 .html 文件）
  Future<String?> _findEntryFile(String directoryPath) async {
    final dir = Directory(directoryPath);

    // 优先查找 index.html
    final indexFile = File(path.join(directoryPath, 'index.html'));
    if (await indexFile.exists()) {
      return indexFile.path;
    }

    // 查找第一个 .html 文件
    await for (final entity in dir.list(recursive: false)) {
      if (entity is File && entity.path.toLowerCase().endsWith('.html')) {
        return entity.path;
      }
    }

    return null;
  }

  /// 获取项目列表（HTTP 服务器目录下的所有子目录）
  Future<List<String>> getHttpProjects() async {
    if (kIsWeb) return [];

    final httpRoot = await getHttpServerRootDir();
    final dir = Directory(httpRoot);

    if (!await dir.exists()) {
      return [];
    }

    final projects = <String>[];
    await for (final entity in dir.list(recursive: false)) {
      if (entity is Directory) {
        projects.add(path.basename(entity.path));
      }
    }

    return projects;
  }

  /// 删除 HTTP 项目
  Future<void> deleteHttpProject(String projectName) async {
    if (kIsWeb) return;

    final httpRoot = await getHttpServerRootDir();
    final projectDir = Directory(path.join(httpRoot, projectName));

    if (await projectDir.exists()) {
      await projectDir.delete(recursive: true);
      debugPrint('[WebViewPlugin] 已删除项目: $projectName');
    }
  }

  /// 停止本地 HTTP 服务器
  Future<void> stopLocalHttpServer() async {
    await localHttpServer.stop();
  }

  /// 将 file:// URL 转换为 HTTP URL（如果需要）
  ///
  /// 在 Windows 平台且本地服务器运行时，自动将 file:// URL 转换为 http://localhost URL
  /// 同时支持 ./ 相对路径转换
  String convertUrlIfNeeded(String url) {
    // Web 平台不转换
    if (kIsWeb) {
      return url;
    }

    // 处理 ./ 相对路径
    if (url.startsWith('./')) {
      // 确保服务器运行
      if (!localHttpServer.isRunning) {
        // 同步启动服务器（如果尚未启动）
        _startLocalHttpServer();
      }

      // 将 ./ 转换为 http://localhost:port/
      final relativePath = url.substring(2); // 移除 ./
      return '${localHttpServer.serverUrl}/$relativePath';
    }

    // 只在服务器运行时转换
    if (!localHttpServer.isRunning) {
      return url;
    }

    // 只在 Windows 平台转换 file:// URL
    if (!UniversalPlatform.isWindows) {
      return url;
    }

    // 如果是可转换的本地文件 URL，则转换
    if (localHttpServer.isConvertibleFileUrl(url)) {
      return localHttpServer.convertFileUrlToHttpUrl(url);
    }

    return url;
  }

  /// 将文件路径转换为可访问的 URL
  ///
  /// 优先使用 HTTP URL（Windows），否则使用 file:// URL
  String filePathToUrl(String filePath) {
    // Web 平台不支持本地文件
    if (kIsWeb) {
      return filePath;
    }

    // 如果服务器运行且是 Windows 平台，使用 HTTP URL
    if (localHttpServer.isRunning && UniversalPlatform.isWindows) {
      return localHttpServer.filePathToHttpUrl(filePath);
    }

    // 否则使用 file:// URL
    return _formatFileUrl(filePath);
  }

  /// 将文件路径转换为 file:// URL 格式
  String _formatFileUrl(String filePath) {
    String normalizedPath = filePath.replaceAll('\\', '/');

    if (UniversalPlatform.isWindows) {
      if (normalizedPath.length >= 2 && normalizedPath[1] == ':') {
        normalizedPath =
            normalizedPath[0].toUpperCase() + normalizedPath.substring(1);
      }
      return 'file:///$normalizedPath';
    } else {
      return 'file://$normalizedPath';
    }
  }

  @override
  void dispose() {
    // 停止本地 HTTP 服务器
    if (!kIsWeb) {
      stopLocalHttpServer();
    }
    super.dispose();
  }
}

import 'package:flutter/material.dart';
import 'package:Memento/plugins/openai/models/tool_app.dart';

class ToolAppController extends ChangeNotifier {
  List<ToolApp> _apps = [];
  bool _isLoading = false;

  List<ToolApp> get apps => List.unmodifiable(_apps);
  bool get isLoading => _isLoading;

  ToolAppController() {
    loadApps();
  }

  Future<void> loadApps() async {
    _isLoading = true;
    notifyListeners();

    try {
      // 这里可以从API或本地存储加载应用
      // 目前添加一个示例应用
      _apps = [
        const ToolApp(
          id: 'plugin-analysis',
          title: '插件分析',
          description: '使用AI分析插件的数据',
        ),
        // 可以添加更多默认应用
      ];
    } catch (e) {
      debugPrint('Error loading tool apps: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 处理应用点击事件
  void handleAppClick(BuildContext context, String appId) {
    switch (appId) {
      case 'plugin-analysis':
        // 插件分析功能已移除
        debugPrint('Plugin analysis feature has been removed');
        break;
    }
  }

  Future<void> addApp(ToolApp app) async {
    // 检查是否已存在相同ID的应用
    if (_apps.any((element) => element.id == app.id)) {
      return;
    }

    _apps.add(app);
    notifyListeners();
    // 这里可以添加保存到持久化存储的逻辑
  }

  Future<void> removeApp(String id) async {
    _apps.removeWhere((app) => app.id == id);
    notifyListeners();
    // 这里可以添加从持久化存储中删除的逻辑
  }
}

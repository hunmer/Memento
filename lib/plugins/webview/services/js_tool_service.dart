import 'dart:convert';
import 'package:Memento/core/js_bridge/js_bridge_manager.dart';
import 'package:Memento/core/js_bridge/js_tool_registry.dart';

/// JavaScript 工具执行服务
class JSToolService {
  static final JSToolService _instance = JSToolService._internal();
  factory JSToolService() => _instance;
  JSToolService._internal();

  final JSToolRegistry _registry = JSToolRegistry();

  /// 执行工具（在 QuickJS 中）
  Future<Map<String, dynamic>> executeTool(String toolId, Map<String, dynamic> params) async {
    final tool = _registry.getTool(toolId);
    if (tool == null) {
      return {
        'success': false,
        'error': '工具未找到: $toolId'
      };
    }

    // 通过 JSBridgeManager 在 QuickJS 中执行
    try {
      final jsResult = await JSBridgeManager.instance.evaluate('''
        // 执行工具代码
        (async function() {
          const toolCode = `${tool.code.replaceAll('`', '\\`')}`;
          const toolParams = ${jsonEncode(params)};

          try {
            // 使用 new Function 执行工具代码
            const fn = new Function('params', 'return (async () => { ' + toolCode + ' })(params);');
            const result = await fn(toolParams);

            return {
              success: true,
              data: result,
              toolId: '$toolId'
            };
          } catch (error) {
            return {
              success: false,
              error: error.message || String(error),
              toolId: '$toolId'
            };
          }
        })();
      ''');

      // 检查执行结果
      if (jsResult.success) {
        return jsResult.result as Map<String, dynamic>;
      } else {
        return {
          'success': false,
          'error': jsResult.error ?? '工具执行失败',
          'toolId': toolId
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': '执行工具时发生错误: $e',
        'toolId': toolId
      };
    }
  }

  /// 获取所有已注册的工具
  List<JSToolConfig> getAllTools() {
    return _registry.getAllTools();
  }

  /// 获取指定工具
  JSToolConfig? getTool(String toolId) {
    return _registry.getTool(toolId);
  }

  /// 检查工具是否存在
  bool hasTool(String toolId) {
    return _registry.hasTool(toolId);
  }

  /// 获取工具数量
  int get toolCount => _registry.toolCount;

  /// 按卡片 ID 获取工具
  List<JSToolConfig> getToolsByCardId(String cardId) {
    return _registry.getToolsByCardId(cardId);
  }

  @override
  String toString() {
    return 'JSToolService{tools: ${_registry.toolCount}}';
  }
}

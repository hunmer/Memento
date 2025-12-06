import 'package:flutter/material.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:provider/provider.dart';
import '../services/script_manager.dart';
import '../services/script_executor.dart';
import '../models/script_info.dart';
import '../models/script_input.dart';
import '../models/script_trigger.dart';
import '../widgets/script_card.dart';
import '../widgets/script_run_dialog.dart';
import 'script_edit_screen.dart';

/// 脚本列表界面
///
/// 展示所有脚本，支持启用/禁用切换、搜索、刷新、文件夹切换
class ScriptsListScreen extends StatefulWidget {
  final ScriptManager scriptManager;
  final ScriptExecutor? scriptExecutor;

  const ScriptsListScreen({
    super.key,
    required this.scriptManager,
    this.scriptExecutor,
  });

  @override
  State<ScriptsListScreen> createState() => _ScriptsListScreenState();
}

class _ScriptsListScreenState extends State<ScriptsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final bool _showOnlyEnabled = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// 获取筛选后的脚本列表
  List<ScriptInfo> _getFilteredScripts() {
    var scripts = widget.scriptManager.scripts;

    // 按启用状态筛选
    if (_showOnlyEnabled) {
      scripts = scripts.where((s) => s.enabled).toList();
    }

    // 按搜索关键词筛选
    if (_searchQuery.isNotEmpty) {
      scripts = widget.scriptManager.searchScripts(_searchQuery);
    }

    return scripts;
  }

  /// 刷新脚本列表
  Future<void> _refreshScripts() async {
    await widget.scriptManager.loadScripts();
  }

  /// 切换脚本启用状态
  Future<void> _toggleScript(ScriptInfo script) async {
    try {
      await widget.scriptManager.toggleScript(script.id, !script.enabled);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              script.enabled
                  ? '已启用脚本: ${script.name}'
                  : '已禁用脚本: ${script.name}',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('操作失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 显示创建/编辑脚本屏幕
  Future<void> _showScriptDialog({ScriptInfo? script}) async {
    final result = await NavigationHelper.push<Map<String, dynamic>>(
      context,
      ScriptEditScreen(
        script: script,
        scriptManager: widget.scriptManager,
      ),
    );

    if (result == null || !mounted) return;

    try {
      if (script == null) {
        // 创建新脚本
        await widget.scriptManager.createScript(
          scriptId: result['id'] as String,
          name: result['name'] as String,
          description: result['description'] as String,
          version: result['version'] as String,
          icon: result['icon'] as String,
          author: result['author'] as String,
        );

        // 更新启用状态和其他属性（包括代码和触发器）
        final newScript = widget.scriptManager.getScriptById(result['id'] as String);
        if (newScript != null) {
          // 解析触发器数据
          final triggersData = result['triggers'] as List<dynamic>? ?? [];
          final triggers = triggersData
              .map((t) => ScriptTrigger.fromJson(t as Map<String, dynamic>))
              .toList();

          // 解析输入参数数据
          final inputsData = result['inputs'] as List<ScriptInput>? ?? [];

          await widget.scriptManager.saveScriptMetadata(
            newScript.id,
            newScript.copyWith(
              enabled: result['enabled'] as bool,
              type: result['type'] as String,
              updateUrl: result['updateUrl'] as String?,
              inputs: inputsData,
              triggers: triggers,
            ),
          );

          // 保存代码
          final code = result['code'] as String? ?? '';
          if (code.isNotEmpty) {
            await widget.scriptManager.saveScriptCode(newScript.id, code);
          }
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('脚本创建成功！')),
          );
        }
      } else {
        // 解析触发器数据
        final triggersData = result['triggers'] as List<dynamic>? ?? [];
        final triggers = triggersData
            .map((t) => ScriptTrigger.fromJson(t as Map<String, dynamic>))
            .toList();

        // 解析输入参数数据
        final inputsData = result['inputs'] as List<ScriptInput>? ?? [];

        // 编辑现有脚本
        final updatedScript = script.copyWith(
          name: result['name'] as String,
          description: result['description'] as String,
          version: result['version'] as String,
          icon: result['icon'] as String,
          author: result['author'] as String,
          enabled: result['enabled'] as bool,
          type: result['type'] as String,
          updateUrl: result['updateUrl'] as String?,
          inputs: inputsData,
          triggers: triggers,
          updatedAt: DateTime.now(),
        );

        await widget.scriptManager.saveScriptMetadata(script.id, updatedScript);

        // 保存代码
        final code = result['code'] as String? ?? '';
        await widget.scriptManager.saveScriptCode(script.id, code);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('脚本更新成功！')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('操作失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 运行脚本
  Future<void> _runScript(ScriptInfo script) async {
    if (widget.scriptExecutor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('脚本执行器未初始化'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 如果是 module 类型且有输入参数,显示表单收集用户输入
    Map<String, dynamic>? inputValues;
    if (script.isModule && script.hasInputs) {
      inputValues = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => ScriptRunDialog(script: script),
      );

      // 用户取消了
      if (inputValues == null) {
        return;
      }
    }

    // 显示加载提示
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Text('正在运行脚本: ${script.name}...'),
            ],
          ),
          duration: const Duration(seconds: 30),
        ),
      );
    }

    try {
      // 执行脚本,传入用户输入的参数
      final result = await widget.scriptExecutor!.execute(
        script.id,
        args: inputValues,
      );

      if (mounted) {
        // 清除加载提示
        ScaffoldMessenger.of(context).clearSnackBars();

        // 显示结果
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.success ? '✅ 脚本执行成功' : '❌ 脚本执行失败',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text('脚本: ${script.name}'),
                Text('耗时: ${result.duration.inMilliseconds}ms'),
                if (!result.success && result.error != null)
                  Text('错误: ${result.error}'),
                if (result.result != null)
                  Text('结果: ${result.result}'),
              ],
            ),
            backgroundColor: result.success ? Colors.green : Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('执行异常: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: widget.scriptManager,
      child: Column(
        children: [
          // 搜索栏
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '搜索脚本...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
          ),

          // 脚本列表
          Expanded(
            child: Consumer<ScriptManager>(
              builder: (context, manager, child) {
                if (manager.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final scripts = _getFilteredScripts();

                if (scripts.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.code_off,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty
                              ? '未找到匹配的脚本'
                              : '暂无脚本\n点击右下角按钮创建新脚本',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _refreshScripts,
                  child: ListView.builder(
                    itemCount: scripts.length,
                    itemBuilder: (context, index) {
                      final script = scripts[index];
                      return ScriptCard(
                        script: script,
                        onTap: () => _showScriptDialog(script: script),
                        onToggle: (enabled) => _toggleScript(script),
                        onRun: () => _runScript(script),
                      );
                    },
                  ),
                );
              },
            ),
          ),

          // 底部统计信息
          Consumer<ScriptManager>(
            builder: (context, manager, child) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  border: Border(
                    top: BorderSide(color: Colors.grey[300]!),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatChip(
                      '总数',
                      manager.scriptCount.toString(),
                      Colors.blue,
                    ),
                    _buildStatChip(
                      '已启用',
                      manager.enabledScriptCount.toString(),
                      Colors.green,
                    ),
                    _buildStatChip(
                      '已禁用',
                      (manager.scriptCount - manager.enabledScriptCount)
                          .toString(),
                      Colors.grey,
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

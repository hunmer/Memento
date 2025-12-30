import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:Memento/core/services/toast_service.dart';
import 'package:provider/provider.dart';
import 'package:Memento/plugins/scripts_center/services/script_manager.dart';
import 'package:Memento/plugins/scripts_center/services/script_executor.dart';
import 'package:Memento/plugins/scripts_center/models/script_info.dart';
import 'package:Memento/plugins/scripts_center/widgets/script_card.dart';
import 'package:Memento/plugins/scripts_center/widgets/script_run_dialog.dart';
import 'package:Memento/widgets/smooth_bottom_sheet.dart';
import 'script_edit_screen.dart';

/// 脚本列表界面
///
/// 展示所有脚本，支持启用/禁用切换、搜索、刷新、文件夹切换
class ScriptsListScreen extends StatefulWidget {
  final ScriptManager scriptManager;
  final ScriptExecutor? scriptExecutor;
  final String? searchQuery;

  const ScriptsListScreen({
    super.key,
    required this.scriptManager,
    this.scriptExecutor,
    this.searchQuery,
  });

  @override
  State<ScriptsListScreen> createState() => _ScriptsListScreenState();
}

class _ScriptsListScreenState extends State<ScriptsListScreen> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchQuery = widget.searchQuery ?? '';
  }

  @override
  void didUpdateWidget(covariant ScriptsListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.searchQuery != oldWidget.searchQuery) {
      setState(() {
        _searchQuery = widget.searchQuery ?? '';
      });
    }
  }

  /// 获取筛选后的脚本列表
  List<ScriptInfo> _getFilteredScripts() {
    var scripts = widget.scriptManager.scripts;

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
        Toast.success(
          script.enabled
              ? '已启用脚本: ${script.name}'
              : '已禁用脚本: ${script.name}',
        );
      }
    } catch (e) {
      if (mounted) {
        Toast.error('操作失败: $e');
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
      // 使用统一的保存方法
      await widget.scriptManager.saveScriptFromEditResult(
        result,
        existingScript: script,
      );

      if (mounted) {
        Toast.success(
          script == null ? '脚本创建成功！' : '脚本更新成功！',
        );
      }
    } catch (e) {
      if (mounted) {
        Toast.error('操作失败: $e');
      }
    }
  }

  /// 运行脚本
  Future<void> _runScript(ScriptInfo script) async {
    if (widget.scriptExecutor == null) {
      Toast.error('脚本执行器未初始化');
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
      Toast.loading('正在运行脚本: ${script.name}...');
    }

    try {
      // 执行脚本,传入用户输入的参数
      final result = await widget.scriptExecutor!.execute(
        script.id,
        args: inputValues,
      );

      if (mounted) {
        // 清除加载提示
        Toast.dismiss();

        // 显示结果
        if (result.success) {
          Toast.success(
            '脚本执行成功\n'
            '脚本: ${script.name}\n'
            '耗时: ${result.duration.inMilliseconds}ms'
            '${result.result != null ? '\n结果: ${result.result}' : ''}',
            duration: const Duration(seconds: 5),
          );
        } else {
          Toast.error(
            '脚本执行失败\n'
            '脚本: ${script.name}\n'
            '耗时: ${result.duration.inMilliseconds}ms'
            '${result.error != null ? '\n错误: ${result.error}' : ''}',
            duration: const Duration(seconds: 5),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Toast.dismiss();
        Toast.error('执行异常: $e');
      }
    }
  }

  /// 删除脚本
  Future<void> _deleteScript(ScriptInfo script) async {
    // 确认删除
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('scripts_center_delete_confirm'.tr),
        content: Text('${'scripts_center_delete_script_confirm'.tr}: ${script.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('app_cancel'.tr),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('app_delete'.tr),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await widget.scriptManager.deleteScript(script.id);
      if (mounted) {
        Toast.success('scripts_center_delete_success'.tr);
      }
    } catch (e) {
      if (mounted) {
        Toast.error('${'scripts_center_operation_failed'.tr}: $e');
      }
    }
  }

  /// 显示底部操作菜单
  void _showActionSheet(ScriptInfo script) {
    SmoothBottomSheet.show(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: Text('app_edit'.tr),
            onTap: () {
              Navigator.pop(context);
              _showScriptDialog(script: script);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: Text(
              'app_delete'.tr,
              style: const TextStyle(color: Colors.red),
            ),
            onTap: () {
              Navigator.pop(context);
              _deleteScript(script);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: widget.scriptManager,
      child: Column(
        children: [
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
                    padding: EdgeInsets.zero,
                    itemCount: scripts.length,
                    itemBuilder: (context, index) {
                      final script = scripts[index];
                      return ScriptCard(
                        script: script,
                        onTap: () => _showScriptDialog(script: script),
                        onLongPress: () => _showActionSheet(script),
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

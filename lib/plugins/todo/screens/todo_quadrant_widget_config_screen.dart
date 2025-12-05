import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import '../todo_plugin.dart';
import '../../../widgets/widget_config_editor/index.dart';

/// 任务四象限小组件配置界面
///
/// 提供实时预览、双色配置和透明度调节功能。
class TodoQuadrantWidgetConfigScreen extends StatefulWidget {
  /// 小组件ID（Android appWidgetId）
  final int? widgetId;

  const TodoQuadrantWidgetConfigScreen({
    super.key,
    this.widgetId,
  });

  @override
  State<TodoQuadrantWidgetConfigScreen> createState() => _TodoQuadrantWidgetConfigScreenState();
}

class _TodoQuadrantWidgetConfigScreenState extends State<TodoQuadrantWidgetConfigScreen> {
  final TodoPlugin _todoPlugin = TodoPlugin.instance;
  late WidgetConfig _widgetConfig;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // 初始化双色配置
    _widgetConfig = WidgetConfig(
      colors: [
        const ColorConfig(
          key: 'primary',
          label: '背景色',
          defaultValue: Color(0xFF2196F3),
          currentValue: Color(0xFF2196F3),
        ),
        const ColorConfig(
          key: 'accent',
          label: '标题色',
          defaultValue: Colors.white,
          currentValue: Colors.white,
        ),
      ],
      opacity: 0.95,
    );
    _loadSavedConfig();
  }

  /// 加载已保存的配置
  Future<void> _loadSavedConfig() async {
    if (widget.widgetId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      // 加载主色调
      final savedPrimaryColor = await HomeWidget.getWidgetData<String>(
        'todo_quadrant_widget_primary_color_${widget.widgetId}',
      );
      if (savedPrimaryColor != null) {
        final colorValue = int.tryParse(savedPrimaryColor);
        if (colorValue != null) {
          _widgetConfig = _widgetConfig.updateColor('primary', Color(colorValue));
        }
      }

      // 加载强调色
      final savedAccentColor = await HomeWidget.getWidgetData<String>(
        'todo_quadrant_widget_accent_color_${widget.widgetId}',
      );
      if (savedAccentColor != null) {
        final colorValue = int.tryParse(savedAccentColor);
        if (colorValue != null) {
          _widgetConfig = _widgetConfig.updateColor('accent', Color(colorValue));
        }
      }

      // 加载透明度
      final savedOpacity = await HomeWidget.getWidgetData<String>(
        'todo_quadrant_widget_opacity_${widget.widgetId}',
      );
      if (savedOpacity != null) {
        final opacityValue = double.tryParse(savedOpacity);
        if (opacityValue != null) {
          _widgetConfig.opacity = opacityValue;
        }
      }
    } catch (e) {
      debugPrint('加载配置失败: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 保存配置并完成设置
  Future<void> _saveAndFinish() async {
    if (widget.widgetId == null) return;

    try {
      // 1. 获取配置值
      final primaryColor = _widgetConfig.getColor('primary')?.currentValue ?? const Color(0xFF2196F3);
      final accentColor = _widgetConfig.getColor('accent')?.currentValue ?? Colors.white;
      final opacity = _widgetConfig.opacity;

      // 2. 保存颜色配置（必须使用 String 类型！）
      await HomeWidget.saveWidgetData<String>(
        'todo_quadrant_widget_primary_color_${widget.widgetId}',
        primaryColor.value.toString(),  // Color.value 转为字符串
      );

      await HomeWidget.saveWidgetData<String>(
        'todo_quadrant_widget_accent_color_${widget.widgetId}',
        accentColor.value.toString(),
      );

      await HomeWidget.saveWidgetData<String>(
        'todo_quadrant_widget_opacity_${widget.widgetId}',
        opacity.toString(),  // double 转为字符串
      );

      // 3. 同步数据并更新小组件
      await _syncDataToWidget();
      await HomeWidget.updateWidget(
        name: 'TodoQuadrantWidgetProvider',
        iOSName: 'TodoQuadrantWidgetProvider',
        qualifiedAndroidName: 'github.hunmer.memento.widgets.providers.TodoQuadrantWidgetProvider',
      );

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      debugPrint('保存配置失败: $e');
    }
  }

  /// 同步数据到小组件
  Future<void> _syncDataToWidget() async {
    try {
      await _todoPlugin.taskController._syncWidget?.call();
      await _todoPlugin.taskController._syncWidgetList?.call();
    } catch (e) {
      debugPrint('同步数据到小组件失败: $e');
    }
  }

  /// 构建实时预览组件
  Widget _buildPreview(WidgetConfig config) {
    final primaryColor = config.getColor('primary')?.currentValue ?? const Color(0xFF2196F3);
    final accentColor = config.getColor('accent')?.currentValue ?? Colors.white;
    final opacity = config.opacity;

    return Container(
      width: 160,
      height: 160,
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(opacity),
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // 标题栏
          Row(
            children: [
              Text(
                '任务四象限',
                style: TextStyle(
                  color: accentColor,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '本日',
                style: TextStyle(
                  color: accentColor,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 四象限网格
          Expanded(
            child: Row(
              children: [
                // 紧急且重要
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(1),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.check_box_outline_blank,
                              size: 12,
                              color: accentColor,
                            ),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                '紧急且重要',
                                style: TextStyle(
                                  color: accentColor,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '2',
                              style: TextStyle(
                                color: accentColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                // 不紧急但重要
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(1),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.check_box_outline_blank,
                              size: 12,
                              color: accentColor,
                            ),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                '不紧急但重要',
                                style: TextStyle(
                                  color: accentColor,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '3',
                              style: TextStyle(
                                color: accentColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                // 紧急但不重要
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(1),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.check_box_outline_blank,
                              size: 12,
                              color: accentColor,
                            ),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                '紧急但不重要',
                                style: TextStyle(
                                  color: accentColor,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '1',
                              style: TextStyle(
                                color: accentColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                // 不紧急且不重要
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(1),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.check_box_outline_blank,
                              size: 12,
                              color: accentColor,
                            ),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                '不紧急且不重要',
                                style: TextStyle(
                                  color: accentColor,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '0',
                              style: TextStyle(
                                color: accentColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('配置四象限小组件'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveAndFinish,
            child: Text(
              _isLoading ? '加载中...' : '完成',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 预览
                Text(
                  '预览效果',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: _buildPreview(_widgetConfig),
                ),
                const SizedBox(height: 24),
                // 主题配置编辑器
                Text(
                  '主题配置',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                WidgetConfigEditor(
                  config: _widgetConfig,
                  onConfigChanged: (newConfig) {
                    setState(() {
                      _widgetConfig = newConfig;
                    });
                  },
                  previewBuilder: (config) => _buildPreview(config),
                ),
                const SizedBox(height: 24),
                // 说明文字
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '使用说明',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '• 点击左上角日期范围按钮可切换时间范围（本日/本周/本月）\n'
                          '• 点击各象限中的 checkbox 可快速完成任务\n'
                          '• 点击标题栏可打开待办事项页面',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

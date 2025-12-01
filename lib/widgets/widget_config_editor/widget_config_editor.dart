import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'models/widget_config.dart';
import 'models/widget_size.dart';
import 'models/color_config.dart';

/// 通用小组件配置编辑器
///
/// 提供实时预览、颜色配置和透明度调节功能，
/// 支持自定义配置区域。
class WidgetConfigEditor extends StatefulWidget {
  /// 预览构建器 - 由调用者提供
  /// 接收当前配置，返回预览 Widget
  final Widget Function(BuildContext context, WidgetConfig config) previewBuilder;

  /// 小组件尺寸（用于预览区域尺寸计算）
  final WidgetSize widgetSize;

  /// 初始配置
  final WidgetConfig initialConfig;

  /// 配置变更回调（实时通知）
  final ValueChanged<WidgetConfig>? onConfigChanged;

  /// 自定义配置组件（放置在主题设置下方）
  final List<Widget>? customConfigWidgets;

  /// 是否显示预览区域
  final bool showPreview;

  /// 预览区域标题
  final String? previewTitle;

  /// 是否显示透明度调节
  final bool showOpacitySlider;

  /// 透明度调节标题
  final String? opacityLabel;

  /// 主题设置标题
  final String? themeSettingsLabel;

  const WidgetConfigEditor({
    super.key,
    required this.previewBuilder,
    required this.widgetSize,
    required this.initialConfig,
    this.onConfigChanged,
    this.customConfigWidgets,
    this.showPreview = true,
    this.previewTitle,
    this.showOpacitySlider = true,
    this.opacityLabel,
    this.themeSettingsLabel,
  });

  @override
  State<WidgetConfigEditor> createState() => _WidgetConfigEditorState();
}

class _WidgetConfigEditorState extends State<WidgetConfigEditor> {
  late WidgetConfig _config;

  @override
  void initState() {
    super.initState();
    _config = widget.initialConfig;
  }

  @override
  void didUpdateWidget(WidgetConfigEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 如果外部配置变化，更新内部状态
    if (widget.initialConfig != oldWidget.initialConfig) {
      setState(() {
        _config = widget.initialConfig;
      });
    }
  }

  void _updateConfig(WidgetConfig newConfig) {
    setState(() => _config = newConfig);
    widget.onConfigChanged?.call(newConfig);
  }

  void _updateColor(String key, Color color) {
    _updateConfig(_config.updateColor(key, color));
  }

  void _updateOpacity(double opacity) {
    _updateConfig(_config.copyWith(opacity: opacity));
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 预览区域
        if (widget.showPreview) ...[
          _buildPreviewSection(),
          const SizedBox(height: 16),
        ],

        // 主题设置
        if (_config.colors.isNotEmpty || widget.showOpacitySlider)
          _buildThemeSettingsSection(),

        // 自定义配置区域
        if (widget.customConfigWidgets != null) ...[
          const SizedBox(height: 16),
          ...widget.customConfigWidgets!,
        ],
      ],
    );
  }

  /// 构建预览区域
  Widget _buildPreviewSection() {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.preview, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  widget.previewTitle ?? '小组件预览',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  widget.widgetSize.label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: RepaintBoundary(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SizedBox(
                      width: widget.widgetSize.getPreviewWidth(context),
                      height: widget.widgetSize.getPreviewHeight(context),
                      child: widget.previewBuilder(context, _config),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建主题设置区域
  Widget _buildThemeSettingsSection() {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.palette, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  widget.themeSettingsLabel ?? '主题设置',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 颜色配置列表
            ..._config.colors.asMap().entries.map((entry) {
              final index = entry.key;
              final colorConfig = entry.value;
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index < _config.colors.length - 1 ? 16 : 0,
                ),
                child: _buildColorPicker(colorConfig),
              );
            }),

            // 透明度调节
            if (widget.showOpacitySlider) ...[
              if (_config.colors.isNotEmpty) const SizedBox(height: 16),
              _buildOpacitySlider(),
            ],
          ],
        ),
      ),
    );
  }

  /// 构建单个颜色选择器
  Widget _buildColorPicker(ColorConfig colorConfig) {
    return _ColorPickerWithLabel(
      label: colorConfig.label,
      selectedColor: colorConfig.currentValue,
      onColorChanged: (color) => _updateColor(colorConfig.key, color),
    );
  }

  /// 构建透明度滑块
  Widget _buildOpacitySlider() {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.opacityLabel ?? '背景透明度',
              style: theme.textTheme.titleSmall,
            ),
            Text(
              '${(_config.opacity * 100).toInt()}%',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
        Slider(
          value: _config.opacity,
          min: 0.0,
          max: 1.0,
          divisions: 20,
          label: '${(_config.opacity * 100).toInt()}%',
          onChanged: _updateOpacity,
        ),
      ],
    );
  }
}

/// 带标签的颜色选择器
///
/// 复用现有的 ColorPickerSection，但添加自定义标签支持
class _ColorPickerWithLabel extends StatelessWidget {
  final String label;
  final Color selectedColor;
  final ValueChanged<Color> onColorChanged;

  const _ColorPickerWithLabel({
    required this.label,
    required this.selectedColor,
    required this.onColorChanged,
  });

  /// 显示自定义颜色选择器
  void _showColorPicker(BuildContext context) {
    Color pickerColor = selectedColor;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('选择颜色'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: pickerColor,
              onColorChanged: (Color color) {
                pickerColor = color;
              },
              pickerAreaHeightPercent: 0.8,
              enableAlpha: false,
              displayThumbColor: true,
              labelTypes: const [],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('取消'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('确定'),
              onPressed: () {
                onColorChanged(pickerColor);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 定义常用颜色列表
    const List<Color> commonColors = [
      Colors.white,
      Colors.grey,
      Colors.red,
      Colors.orange,
      Colors.amber,
      Colors.yellow,
      Colors.lime,
      Colors.green,
      Colors.teal,
      Colors.cyan,
      Colors.blue,
      Colors.indigo,
      Colors.purple,
      Colors.pink,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            // 常用颜色
            ...commonColors.map((color) {
              final isSelected = selectedColor.value == color.value;
              return GestureDetector(
                onTap: () => onColorChanged(color),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: color == Colors.white
                          ? theme.colorScheme.outline.withOpacity(0.5)
                          : (isSelected ? Colors.black : Colors.transparent),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: isSelected
                      ? Icon(
                          Icons.check,
                          color: color == Colors.white ? Colors.black : Colors.white,
                          size: 20,
                        )
                      : null,
                ),
              );
            }),
            // 自定义颜色按钮
            GestureDetector(
              onTap: () => _showColorPicker(context),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.colorScheme.outline,
                    width: 2,
                    style: BorderStyle.solid,
                  ),
                  gradient: const LinearGradient(
                    colors: [
                      Colors.red,
                      Colors.yellow,
                      Colors.green,
                      Colors.blue,
                      Colors.purple,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Icon(
                  Icons.palette,
                  color: Colors.white,
                  size: 20,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:Memento/l10n/app_localizations.dart';
import 'package:Memento/screens/l10n/screens_localizations.dart';
import 'package:Memento/widgets/image_picker_dialog.dart';
import 'package:Memento/screens/home_screen/models/plugin_widget_config.dart';

/// 小组件设置对话框
class WidgetSettingsDialog extends StatefulWidget {
  /// 当前配置
  final PluginWidgetConfig initialConfig;

  /// 可用的统计项
  final List<StatItemData> availableItems;

  const WidgetSettingsDialog({
    super.key,
    required this.initialConfig,
    required this.availableItems,
  });

  @override
  State<WidgetSettingsDialog> createState() => _WidgetSettingsDialogState();
}

class _WidgetSettingsDialogState extends State<WidgetSettingsDialog> {
  late PluginWidgetConfig _config;
  late Set<String> _selectedIds;

  @override
  void initState() {
    super.initState();
    _config = widget.initialConfig;
    _selectedIds = Set.from(_config.selectedItemIds);

    // 如果没有选中任何项，默认选中所有
    if (_selectedIds.isEmpty) {
      _selectedIds = widget.availableItems.map((e) => e.id).toSet();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final screensL10n = ScreensLocalizations.of(context)!;

    return AlertDialog(
      title: Text(screensL10n.widgetSettings),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 显示风格选择
            Text(
              '显示风格',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            SegmentedButton<PluginWidgetDisplayStyle>(
              segments: [
                ButtonSegment(
                  value: PluginWidgetDisplayStyle.oneColumn,
                  label: Text(screensL10n.oneColumn),
                  icon: const Icon(Icons.view_agenda),
                ),
                ButtonSegment(
                  value: PluginWidgetDisplayStyle.twoColumns,
                  label: Text(screensL10n.twoColumns),
                  icon: const Icon(Icons.view_column),
                ),
              ],
              selected: {_config.displayStyle},
              onSelectionChanged: (Set<PluginWidgetDisplayStyle> newSelection) {
                setState(() {
                  _config = _config.copyWith(
                    displayStyle: newSelection.first,
                  );
                });
              },
            ),

            const SizedBox(height: 24),

            // 显示项目选择
            Text(
              '显示项目',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...widget.availableItems.map((item) => CheckboxListTile(
              title: Text(item.label),
              value: _selectedIds.contains(item.id),
              onChanged: (bool? value) {
                setState(() {
                  if (value == true) {
                    _selectedIds.add(item.id);
                  } else {
                    _selectedIds.remove(item.id);
                  }
                });
              },
              dense: true,
              contentPadding: EdgeInsets.zero,
            )),

            const SizedBox(height: 24),

            // 外观设置
            Text(
              '外观设置',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // 背景图片
            ListTile(
              leading: const Icon(Icons.image),
              title: Text(screensL10n.backgroundImage),
              subtitle: _config.backgroundImagePath != null
                ? Text(screensL10n.alreadySet)
                : Text(screensL10n.notSet),
              trailing: _config.backgroundImagePath != null
                ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _config = _config.copyWith(
                        clearBackgroundImage: true,
                      );
                    });
                  },
                )
                : null,
              onTap: () async {
                final result = await showDialog<Map<String, dynamic>>(
                  context: context,
                  builder: (context) => const ImagePickerDialog(
                    saveDirectory: 'widget_backgrounds',
                    enableCrop: true,
                    cropAspectRatio: 16 / 9, // 卡片比例
                  ),
                );

                if (result != null && mounted) {
                  setState(() {
                    _config = _config.copyWith(
                      backgroundImagePath: result['url'] as String,
                    );
                  });
                }
              },
              contentPadding: EdgeInsets.zero,
            ),

            // 图标颜色
            ListTile(
              leading: const Icon(Icons.color_lens),
              title: Text(screensL10n.iconColor),
              subtitle: _config.iconColor != null
                ? Text(screensL10n.customized)
                : Text(screensL10n.useDefault),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_config.iconColor != null)
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: _config.iconColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: theme.dividerColor),
                      ),
                    ),
                  if (_config.iconColor != null)
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _config = _config.copyWith(
                            clearIconColor: true,
                          );
                        });
                      },
                    ),
                ],
              ),
              onTap: () => _showColorPicker(
                context,
                '选择图标颜色',
                _config.iconColor,
                (color) {
                  setState(() {
                    _config = _config.copyWith(iconColor: color);
                  });
                },
              ),
              contentPadding: EdgeInsets.zero,
            ),

            // 背景颜色
            ListTile(
              leading: const Icon(Icons.format_color_fill),
              title: Text(screensL10n.backgroundColor),
              subtitle: Text(screensL10n.effectWhenNoBackgroundImage),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_config.backgroundColor != null)
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: _config.backgroundColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: theme.dividerColor),
                      ),
                    ),
                  if (_config.backgroundColor != null)
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _config = _config.copyWith(
                            clearBackgroundColor: true,
                          );
                        });
                      },
                    ),
                ],
              ),
              onTap: () => _showColorPicker(
                context,
                '选择背景颜色',
                _config.backgroundColor,
                (color) {
                  setState(() {
                    _config = _config.copyWith(backgroundColor: color);
                  });
                },
              ),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        ElevatedButton(
          onPressed: () {
            final finalConfig = _config.copyWith(
              selectedItemIds: _selectedIds.toList(),
            );
            Navigator.of(context).pop(finalConfig);
          },
          child: Text(l10n.confirm),
        ),
      ],
    );
  }

  /// 显示颜色选择器
  void _showColorPicker(
    BuildContext context,
    String title,
    Color? currentColor,
    ValueChanged<Color> onColorSelected,
  ) {
    final screensL10n = ScreensLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 预设颜色网格
              Text(
                screensL10n.presetColors,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _predefinedColors.map((color) {
                  final isSelected = currentColor == color;
                  return GestureDetector(
                    onTap: () {
                      onColorSelected(color);
                      Navigator.of(context).pop();
                    },
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey,
                          width: isSelected ? 3 : 1,
                        ),
                      ),
                      child: isSelected
                        ? const Icon(Icons.check, color: Colors.white)
                        : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              // 自定义颜色按钮
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _showAdvancedColorPicker(
                      context,
                      title,
                      currentColor ?? Colors.blue,
                      onColorSelected,
                    );
                  },
                  icon: const Icon(Icons.palette),
                  label: Text(screensL10n.customColorWithTransparency),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
        ],
      ),
    );
  }

  /// 显示高级颜色选择器（支持透明通道）
  void _showAdvancedColorPicker(
    BuildContext context,
    String title,
    Color initialColor,
    ValueChanged<Color> onColorSelected,
  ) {
    final screensL10n = ScreensLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) {
        Color pickerColor = initialColor;

        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: Text(title),
            contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            content: SizedBox(
              width: MediaQuery.of(context).size.width * 0.8,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 颜色预览
                    Container(
                      width: double.infinity,
                      height: 60,
                      decoration: BoxDecoration(
                        color: pickerColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey),
                      ),
                      child: Center(
                        child: Text(
                          _formatColorInfo(pickerColor),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: pickerColor.computeLuminance() > 0.5
                              ? Colors.black
                              : Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 快速应用预设颜色
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        screensL10n.quickSelectPresetColors,
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 40,
                      width: double.infinity,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _predefinedColors.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final color = _predefinedColors[index];
                          return GestureDetector(
                            onTap: () {
                              // 应用预设颜色到选择器
                              setState(() {
                                pickerColor = color;
                              });
                            },
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.grey),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 颜色选择器（支持透明通道）
                    SizedBox(
                      width: double.infinity,
                      child: ColorPicker(
                        pickerColor: pickerColor,
                        onColorChanged: (Color color) {
                          setState(() {
                            pickerColor = color;
                          });
                        },
                        enableAlpha: true, // 启用透明通道
                        displayThumbColor: true,
                        labelTypes: const [
                          ColorLabelType.rgb,
                          ColorLabelType.hsv,
                        ],
                        pickerAreaHeightPercent: 0.7,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              ElevatedButton(
                onPressed: () {
                  onColorSelected(pickerColor);
                  Navigator.of(context).pop();
                },
                child: Text(AppLocalizations.of(context)!.confirm),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 格式化颜色信息（使用新的 API）
  String _formatColorInfo(Color color) {
    final a = (color.a * 255.0).round().clamp(0, 255);
    final r = (color.r * 255.0).round().clamp(0, 255);
    final g = (color.g * 255.0).round().clamp(0, 255);
    final b = (color.b * 255.0).round().clamp(0, 255);
    final hex = ((a << 24) | (r << 16) | (g << 8) | b).toRadixString(16).toUpperCase().padLeft(8, '0');
    return 'ARGB: $a, $r, $g, $b\n#$hex';
  }

  /// 预定义颜色
  static final List<Color> _predefinedColors = [
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.deepPurple,
    Colors.indigo,
    Colors.blue,
    Colors.lightBlue,
    Colors.cyan,
    Colors.teal,
    Colors.green,
    Colors.lightGreen,
    Colors.lime,
    Colors.yellow,
    Colors.amber,
    Colors.orange,
    Colors.deepOrange,
    Colors.brown,
    Colors.grey,
    Colors.blueGrey,
    Colors.black,
  ];
}

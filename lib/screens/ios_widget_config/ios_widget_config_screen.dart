import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/screens/home_screen/widgets/add_widget_dialog.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/core/app_widgets/models/ios_widget_config.dart';
import 'package:Memento/core/app_widgets/services/ios_widget_sync_service.dart';
import 'package:Memento/core/app_widgets/services/widget_size_mapper.dart';
import 'package:Memento/core/services/toast_service.dart';

/// iOS 小组件配置页面
///
/// 允许用户选择要显示在 iOS 桌面小组件上的 HomeWidget
class IOSWidgetConfigScreen extends StatefulWidget {
  /// iOS Widget Kind（从 URL scheme 传入）
  final String? widgetKind;

  const IOSWidgetConfigScreen({super.key, this.widgetKind});

  @override
  State<IOSWidgetConfigScreen> createState() => _IOSWidgetConfigScreenState();
}

class _IOSWidgetConfigScreenState extends State<IOSWidgetConfigScreen> {
  /// 选中的 HomeWidget
  HomeWidget? _selectedWidget;

  /// 选中的 iOS 尺寸
  IOSWidgetSize _selectedSize = IOSWidgetSize.small;

  /// 可用的 iOS 尺寸列表
  List<IOSWidgetSize> _availableSizes = IOSWidgetSize.values;

  /// 已保存的配置
  Map<String, IOSWidgetConfig> _savedConfigs = {};

  /// 是否正在加载
  bool _isLoading = true;

  /// 是否正在保存
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // 加载已保存的配置
      _savedConfigs = await IOSWidgetSyncService().loadAllConfigs();

      // 如果从 URL scheme 传入 widgetKind，解析尺寸
      if (widget.widgetKind != null) {
        _selectedSize = _parseSizeFromKind(widget.widgetKind!);
        final config = _savedConfigs[widget.widgetKind!];
        if (config != null) {
          _selectedWidget = HomeWidgetRegistry().getWidget(config.homeWidgetId);
        }
      }

      setState(() {
        _isLoading = false;
        _updateAvailableSizes();
      });
    } catch (e) {
      debugPrint('加载配置失败: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  IOSWidgetSize _parseSizeFromKind(String kind) {
    if (kind.contains('small')) return IOSWidgetSize.small;
    if (kind.contains('wide')) return IOSWidgetSize.wide;
    if (kind.contains('large')) return IOSWidgetSize.large;
    return IOSWidgetSize.small;
  }

  void _updateAvailableSizes() {
    if (_selectedWidget != null) {
      _availableSizes = WidgetSizeMapper.getAvailableIOSSizes(
        _selectedWidget!.effectiveSupportedSizes,
      );
      // 如果当前选中的尺寸不可用，切换到第一个可用的
      if (!_availableSizes.contains(_selectedSize) && _availableSizes.isNotEmpty) {
        _selectedSize = _availableSizes.first;
      }
    } else {
      _availableSizes = IOSWidgetSize.values;
    }
  }

  Future<void> _selectWidget() async {
    final result = await showDialog<HomeWidget>(
      context: context,
      builder: (context) => const AddWidgetDialog(),
    );

    if (result != null) {
      setState(() {
        _selectedWidget = result;
        _updateAvailableSizes();
      });
    }
  }

  Future<void> _saveConfig() async {
    if (_selectedWidget == null) {
      Toast.error('请先选择一个小组件');
      return;
    }

    if (!Platform.isIOS) {
      Toast.error('仅支持 iOS 平台');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final success = await IOSWidgetSyncService().createConfig(
        homeWidgetId: _selectedWidget!.id,
        iosSize: _selectedSize,
        context: context,
      );

      if (success != null) {
        // 更新本地缓存
        _savedConfigs[success.widgetKind] = success;

        Toast.success('配置已保存');

        if (mounted) {
          setState(() {});
        }
      } else {
        Toast.error('保存失败');
      }
    } catch (e) {
      debugPrint('保存配置失败: $e');
      Toast.error('保存失败: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('iOS 桌面小组件配置'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(theme),
    );
  }

  Widget _buildBody(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 说明卡片
          _buildInfoCard(theme),

          const SizedBox(height: 24),

          // 尺寸选择
          _buildSizeSelector(theme),

          const SizedBox(height: 24),

          // 选择小组件
          _buildWidgetSelector(theme),

          const SizedBox(height: 24),

          // 预览
          if (_selectedWidget != null) _buildPreview(theme),

          const SizedBox(height: 24),

          // 已保存的配置
          if (_savedConfigs.isNotEmpty) _buildSavedConfigs(theme),

          const SizedBox(height: 32),

          // 保存按钮
          _buildSaveButton(theme),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildInfoCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  '使用说明',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              '1. 选择要显示的尺寸\n'
              '2. 点击"选择小组件"按钮\n'
              '3. 在弹出的对话框中选择要显示的小组件\n'
              '4. 点击"保存配置"按钮\n'
              '5. 返回桌面，小组件将自动更新',
              style: TextStyle(height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSizeSelector(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '选择尺寸',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: IOSWidgetSize.values.map((size) {
            final isAvailable = _availableSizes.contains(size);
            final isSelected = _selectedSize == size;
            final config = _savedConfigs['memento_widget_${size.name}'];

            return _SizeOptionCard(
              size: size,
              isSelected: isSelected,
              isAvailable: isAvailable,
              hasConfig: config != null,
              onTap: isAvailable
                  ? () {
                      setState(() {
                        _selectedSize = size;
                        // 如果该尺寸已有配置，加载对应的 Widget
                        if (config != null) {
                          _selectedWidget = HomeWidgetRegistry().getWidget(
                            config.homeWidgetId,
                          );
                        }
                      });
                    }
                  : null,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildWidgetSelector(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '选择小组件',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: _selectWidget,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(
                color: _selectedWidget != null
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  _selectedWidget?.icon ?? Icons.add_circle_outline,
                  size: 48,
                  color: _selectedWidget?.color ?? theme.colorScheme.primary,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedWidget?.name ?? '点击选择小组件',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_selectedWidget?.description != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          _selectedWidget!.description!,
                          style: theme.textTheme.bodySmall,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (_selectedWidget != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          '插件: ${_selectedWidget!.pluginId}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPreview(ThemeData theme) {
    final logicalSize = WidgetSizeMapper.getLogicalSize(_selectedSize);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '预览',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Container(
            width: logicalSize.width.clamp(100.0, 350.0),
            height: logicalSize.height.clamp(100.0, 300.0),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.colorScheme.outline),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: _selectedWidget != null
                  ? Builder(
                      builder: (context) {
                        final homeSize = WidgetSizeMapper.iosToHome(_selectedSize);
                        return _selectedWidget!.build(
                          context,
                          {'widgetSize': homeSize},
                          homeSize,
                        );
                      },
                    )
                  : Center(
                      child: Text(
                        '选择小组件以预览',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSavedConfigs(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '已保存的配置',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...(_savedConfigs.entries.map((entry) {
          final config = entry.value;
          final widgetDef = HomeWidgetRegistry().getWidget(config.homeWidgetId);

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Icon(
                widgetDef?.icon ?? Icons.widgets,
                color: widgetDef?.color ?? theme.colorScheme.primary,
              ),
              title: Text(widgetDef?.name ?? config.homeWidgetId),
              subtitle: Text('尺寸: ${config.size.name}'),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _deleteConfig(entry.key),
              ),
            ),
          );
        }).toList()),
      ],
    );
  }

  Future<void> _deleteConfig(String widgetKind) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除配置'),
        content: const Text('确定要删除此配置吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await IOSWidgetSyncService().deleteConfig(widgetKind);
      setState(() {
        _savedConfigs.remove(widgetKind);
      });
      Toast.success('配置已删除');
    }
  }

  Widget _buildSaveButton(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: _isSaving ? null : _saveConfig,
        icon: _isSaving
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.save),
        label: Text(_isSaving ? '保存中...' : '保存配置'),
      ),
    );
  }
}

/// 尺寸选项卡片
class _SizeOptionCard extends StatelessWidget {
  final IOSWidgetSize size;
  final bool isSelected;
  final bool isAvailable;
  final bool hasConfig;
  final VoidCallback? onTap;

  const _SizeOptionCard({
    required this.size,
    required this.isSelected,
    required this.isAvailable,
    required this.hasConfig,
    this.onTap,
  });

  String get _label {
    return switch (size) {
      IOSWidgetSize.small => '小',
      IOSWidgetSize.wide => '宽',
      IOSWidgetSize.large => '大',
    };
  }

  String get _description {
    return switch (size) {
      IOSWidgetSize.small => '170 × 170',
      IOSWidgetSize.wide => '364 × 170',
      IOSWidgetSize.large => '364 × 382',
    };
  }

  IconData get _icon {
    return switch (size) {
      IOSWidgetSize.small => Icons.crop_square,
      IOSWidgetSize.wide => Icons.rectangle,
      IOSWidgetSize.large => Icons.crop_landscape,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Stack(
              children: [
                Icon(
                  _icon,
                  size: 32,
                  color: isAvailable
                      ? isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface
                      : theme.colorScheme.outline,
                ),
                if (hasConfig)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _label,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isAvailable
                    ? null
                    : theme.colorScheme.outline,
              ),
            ),
            Text(
              _description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

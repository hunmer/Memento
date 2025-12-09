import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'package:Memento/screens/home_screen/managers/home_layout_manager.dart';
import 'package:Memento/screens/home_screen/models/layout_config.dart';
import 'package:Memento/core/services/toast_service.dart';

/// 主页主题设置页面
class BackgroundSettingsPage extends StatefulWidget {
  const BackgroundSettingsPage({super.key});

  @override
  State<BackgroundSettingsPage> createState() => _BackgroundSettingsPageState();
}

class _BackgroundSettingsPageState extends State<BackgroundSettingsPage> {
  final HomeLayoutManager _layoutManager = HomeLayoutManager();
  List<LayoutConfig> _layouts = [];
  bool _isLoading = true;

  // 全局背景图设置
  String? _globalBackgroundPath;
  BoxFit _globalBackgroundFit = BoxFit.cover;
  double _globalBackgroundBlur = 0.0;

  // 全局小组件透明度 (0-1) - 影响整个小组件
  double _globalWidgetOpacity = 1.0;

  // 全局小组件背景颜色透明度 (0-1) - 仅影响背景颜色
  double _globalWidgetBackgroundOpacity = 1.0;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  /// 加载设置
  Future<void> _loadSettings() async {
    try {
      // 加载所有布局
      final layouts = await _layoutManager.getSavedLayouts();

      // 加载全局背景设置
      final globalConfig = await _layoutManager.getGlobalBackgroundConfig();

      if (mounted) {
        setState(() {
          _layouts = layouts;
          _globalBackgroundPath =
              globalConfig['backgroundImagePath'] as String?;
          _globalBackgroundFit = LayoutConfig.boxFitFromString(
            globalConfig['backgroundFit'] as String?,
          );
          _globalBackgroundBlur =
              (globalConfig['backgroundBlur'] as num?)?.toDouble() ?? 0.0;
          _globalWidgetOpacity =
              (globalConfig['widgetOpacity'] as num?)?.toDouble() ?? 1.0;
          _globalWidgetBackgroundOpacity =
              (globalConfig['widgetBackgroundOpacity'] as num?)?.toDouble() ??
              1.0;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('加载背景设置失败: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// 选择图片
  Future<String?> _pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        return result.files.first.path;
      }
    } catch (e) {
      debugPrint('选择图片失败: $e');
      if (mounted) {
        toastService.showToast('选择图片失败：$e');
      }
    }
    return null;
  }

  /// 保存全局背景设置
  Future<void> _saveGlobalBackground() async {
    try {
      await _layoutManager.saveGlobalBackgroundConfig({
        'backgroundImagePath': _globalBackgroundPath,
        'backgroundFit': LayoutConfig.boxFitToString(_globalBackgroundFit),
        'backgroundBlur': _globalBackgroundBlur,
        'widgetOpacity': _globalWidgetOpacity,
        'widgetBackgroundOpacity': _globalWidgetBackgroundOpacity,
      });

      if (mounted) {
        toastService.showToast('主题设置已保存');
      }
    } catch (e) {
      if (mounted) {
        toastService.showToast('保存失败：$e');
      }
    }
  }

  /// 更新布局背景
  Future<void> _updateLayoutBackground(
    LayoutConfig layout,
    String? imagePath,
    BoxFit fit,
    double blur,
  ) async {
    try {
      final updatedLayout = layout.copyWith(
        backgroundImagePath: imagePath,
        clearBackgroundImage: imagePath == null,
        backgroundFit: fit,
        backgroundBlur: blur,
        updatedAt: DateTime.now(),
      );

      final layouts = await _layoutManager.getSavedLayouts();
      final index = layouts.indexWhere((l) => l.id == layout.id);

      if (index != -1) {
        layouts[index] = updatedLayout;
        await _layoutManager.saveLayoutConfigs(layouts);
        await _loadSettings();

        if (mounted) {
          toastService.showToast('布局"${layout.name}"的背景已更新');
        }
      }
    } catch (e) {
      if (mounted) {
        toastService.showToast('更新失败：$e');
      }
    }
  }

  /// 显示全局背景设置对话框
  void _showGlobalBackgroundDialog() {
    String? tempPath = _globalBackgroundPath;
    BoxFit tempFit = _globalBackgroundFit;
    double tempBlur = _globalBackgroundBlur;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: Text('screens_globalBackgroundSettings'.tr),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 背景图预览
                      if (tempPath != null)
                        Container(
                          height: 200,
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.file(File(tempPath!), fit: tempFit),
                                if (tempBlur > 0)
                                  BackdropFilter(
                                    filter: ImageFilter.blur(
                                      sigmaX: tempBlur,
                                      sigmaY: tempBlur,
                                    ),
                                    child: Container(color: Colors.transparent),
                                  ),
                              ],
                            ),
                          ),
                        ),

                      // 选择图片按钮
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final path = await _pickImage();
                                if (path != null) {
                                  setDialogState(() {
                                    tempPath = path;
                                  });
                                }
                              },
                              icon: const Icon(Icons.image),
                              label: Text('screens_selectImage'.tr),
                            ),
                          ),
                          if (tempPath != null) ...[
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: () {
                                setDialogState(() {
                                  tempPath = null;
                                });
                              },
                              icon: const Icon(Icons.clear),
                              tooltip: 'screens_clear'.tr,
                            ),
                          ],
                        ],
                      ),

                      const SizedBox(height: 24),

                      // 填充方式
                      Text(
                        'screens_fillMode'.tr,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      DropdownButton<BoxFit>(
                        value: tempFit,
                        isExpanded: true,
                        items: [
                          DropdownMenuItem(
                            value: BoxFit.cover,
                            child: Text('screens_cover'.tr),
                          ),
                          DropdownMenuItem(
                            value: BoxFit.contain,
                            child: Text('screens_contain'.tr),
                          ),
                          DropdownMenuItem(
                            value: BoxFit.fill,
                            child: Text('screens_fill'.tr),
                          ),
                          DropdownMenuItem(
                            value: BoxFit.fitWidth,
                            child: Text('screens_fitWidth'.tr),
                          ),
                          DropdownMenuItem(
                            value: BoxFit.fitHeight,
                            child: Text('screens_fitHeight'.tr),
                          ),
                          DropdownMenuItem(
                            value: BoxFit.none,
                            child: Text('screens_none'.tr),
                          ),
                          DropdownMenuItem(
                            value: BoxFit.scaleDown,
                            child: Text('screens_scaleDown'.tr),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() {
                              tempFit = value;
                            });
                          }
                        },
                      ),

                      const SizedBox(height: 24),

                      // 模糊程度
                      Text(
                        'screens_blurLevel'.tr,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Slider(
                              value: tempBlur,
                              min: 0,
                              max: 10,
                              divisions: 20,
                              label: tempBlur.toStringAsFixed(1),
                              onChanged: (value) {
                                setDialogState(() {
                                  tempBlur = value;
                                });
                              },
                            ),
                          ),
                          SizedBox(
                            width: 50,
                            child: Text(
                              tempBlur.toStringAsFixed(1),
                              style: const TextStyle(fontSize: 16),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('screens_cancel'.tr),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _globalBackgroundPath = tempPath;
                        _globalBackgroundFit = tempFit;
                        _globalBackgroundBlur = tempBlur;
                      });
                      _saveGlobalBackground();
                      Navigator.pop(context);
                    },
                    child: Text('screens_save'.tr),
                  ),
                ],
              );
            },
          ),
    );
  }

  /// 显示布局背景设置对话框
  void _showLayoutBackgroundDialog(LayoutConfig layout) {
    String? tempPath = layout.backgroundImagePath;
    BoxFit tempFit = layout.backgroundFit;
    double tempBlur = layout.backgroundBlur;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: Text(
                  'screens_layoutBackgroundSettings'.trParams({
                    'layoutName': layout.name,
                  }),
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 提示信息
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              size: 20,
                              color: Colors.blue,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'screens_customBackgroundHasPriority'.tr,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // 背景图预览
                      if (tempPath != null)
                        Container(
                          height: 200,
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.file(File(tempPath!), fit: tempFit),
                                if (tempBlur > 0)
                                  BackdropFilter(
                                    filter: ImageFilter.blur(
                                      sigmaX: tempBlur,
                                      sigmaY: tempBlur,
                                    ),
                                    child: Container(color: Colors.transparent),
                                  ),
                              ],
                            ),
                          ),
                        ),

                      // 选择图片按钮
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final path = await _pickImage();
                                if (path != null) {
                                  setDialogState(() {
                                    tempPath = path;
                                  });
                                }
                              },
                              icon: const Icon(Icons.image),
                              label: Text('screens_selectImage'.tr),
                            ),
                          ),
                          if (tempPath != null) ...[
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: () {
                                setDialogState(() {
                                  tempPath = null;
                                });
                              },
                              icon: const Icon(Icons.clear),
                              tooltip: 'screens_clearUseGlobalBackground'.tr,
                            ),
                          ],
                        ],
                      ),

                      const SizedBox(height: 24),

                      // 填充方式
                      Text(
                        'screens_fillMode'.tr,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      DropdownButton<BoxFit>(
                        value: tempFit,
                        isExpanded: true,
                        items: [
                          DropdownMenuItem(
                            value: BoxFit.cover,
                            child: Text('screens_cover'.tr),
                          ),
                          DropdownMenuItem(
                            value: BoxFit.contain,
                            child: Text('screens_contain'.tr),
                          ),
                          DropdownMenuItem(
                            value: BoxFit.fill,
                            child: Text('screens_fill'.tr),
                          ),
                          DropdownMenuItem(
                            value: BoxFit.fitWidth,
                            child: Text('screens_fitWidth'.tr),
                          ),
                          DropdownMenuItem(
                            value: BoxFit.fitHeight,
                            child: Text('screens_fitHeight'.tr),
                          ),
                          DropdownMenuItem(
                            value: BoxFit.none,
                            child: Text('screens_none'.tr),
                          ),
                          DropdownMenuItem(
                            value: BoxFit.scaleDown,
                            child: Text('screens_scaleDown'.tr),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() {
                              tempFit = value;
                            });
                          }
                        },
                      ),

                      const SizedBox(height: 24),

                      // 模糊程度
                      Text(
                        'screens_blurLevel'.tr,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Slider(
                              value: tempBlur,
                              min: 0,
                              max: 10,
                              divisions: 20,
                              label: tempBlur.toStringAsFixed(1),
                              onChanged: (value) {
                                setDialogState(() {
                                  tempBlur = value;
                                });
                              },
                            ),
                          ),
                          SizedBox(
                            width: 50,
                            child: Text(
                              tempBlur.toStringAsFixed(1),
                              style: const TextStyle(fontSize: 16),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('screens_cancel'.tr),
                  ),
                  TextButton(
                    onPressed: () {
                      _updateLayoutBackground(
                        layout,
                        tempPath,
                        tempFit,
                        tempBlur,
                      );
                      Navigator.pop(context);
                    },
                    child: Text('screens_save'.tr),
                  ),
                ],
              );
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('screens_themeSettings'.tr),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // 全局背景设置卡片
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.wallpaper),
                      title: Text(
                        'screens_globalBackgroundImage'.tr,
                      ),
                      subtitle: Text(
                        _globalBackgroundPath != null
                            ? ScreensLocalizations.of(
                              context,
                            ).backgroundImageSet
                            : ScreensLocalizations.of(
                              context,
                            ).backgroundImageNotSet,
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _showGlobalBackgroundDialog,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 全局小组件透明度设置卡片
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.opacity),
                              const SizedBox(width: 12),
                              Text(
                                ScreensLocalizations.of(
                                  context,
                                ).widgetOverallOpacity,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${(_globalWidgetOpacity * 100).toInt()}%',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            ScreensLocalizations.of(
                              context,
                            ).widgetOverallOpacityDescription,
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).hintColor,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Slider(
                            value: _globalWidgetOpacity,
                            min: 0.0,
                            max: 1.0,
                            divisions: 20,
                            label: '${(_globalWidgetOpacity * 100).toInt()}%',
                            onChanged: (value) {
                              setState(() {
                                _globalWidgetOpacity = value;
                              });
                            },
                            onChangeEnd: (value) {
                              _saveGlobalBackground();
                            },
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                ScreensLocalizations.of(
                                  context,
                                ).zeroPercentFullyTransparent,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).hintColor,
                                ),
                              ),
                              Text(
                                ScreensLocalizations.of(
                                  context,
                                ).oneHundredPercentOpaque,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).hintColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 全局小组件背景颜色透明度设置卡片
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.format_color_fill),
                              const SizedBox(width: 12),
                              Text(
                                ScreensLocalizations.of(
                                  context,
                                ).backgroundColorOpacity,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${(_globalWidgetBackgroundOpacity * 100).toInt()}%',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            ScreensLocalizations.of(
                              context,
                            ).backgroundColorOpacityDescription,
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).hintColor,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Slider(
                            value: _globalWidgetBackgroundOpacity,
                            min: 0.0,
                            max: 1.0,
                            divisions: 20,
                            label:
                                '${(_globalWidgetBackgroundOpacity * 100).toInt()}%',
                            onChanged: (value) {
                              setState(() {
                                _globalWidgetBackgroundOpacity = value;
                              });
                            },
                            onChangeEnd: (value) {
                              _saveGlobalBackground();
                            },
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                ScreensLocalizations.of(
                                  context,
                                ).zeroPercentFullyTransparent,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).hintColor,
                                ),
                              ),
                              Text(
                                ScreensLocalizations.of(
                                  context,
                                ).oneHundredPercentOpaque,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).hintColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 布局背景设置标题
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      ScreensLocalizations.of(
                        context,
                      ).layoutBackgroundSettingsTitle,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // 提示信息
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      ScreensLocalizations.of(
                        context,
                      ).layoutBackgroundSettingsDescription,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).hintColor,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 布局列表
                  if (_layouts.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.layers_outlined,
                              size: 64,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'screens_noSavedLayouts'.tr,
                              style: const TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'screens_saveLayoutFirst'.tr,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...List.generate(_layouts.length, (index) {
                      final layout = _layouts[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(child: Text('${index + 1}')),
                          title: Text(layout.name),
                          subtitle: Text(
                            layout.backgroundImagePath != null
                                ? ScreensLocalizations.of(
                                  context,
                                ).customBackgroundImage
                                : ScreensLocalizations.of(
                                  context,
                                ).useGlobalBackgroundImage,
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _showLayoutBackgroundDialog(layout),
                        ),
                      );
                    }),
                ],
              ),
    );
  }
}

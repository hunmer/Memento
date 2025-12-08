import 'dart:async';
import 'dart:ui' as ui;
import 'package:Memento/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'custom_dialog.dart';
import 'package:Memento/constants/app_icons.dart';

class IconPickerDialog extends StatefulWidget {
  final IconData currentIcon;
  final bool enableIconToImage; // 是否启用图标转图片功能

  const IconPickerDialog({
    super.key,
    required this.currentIcon,
    this.enableIconToImage = true,
  });

  @override
  State<IconPickerDialog> createState() => _IconPickerDialogState();
}

class _IconPickerDialogState extends State<IconPickerDialog> {
  late IconData selectedIcon;
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;
  int _currentPage = 0;
  static const int _iconsPerPage = 200;
  List<IconData> _cachedFilteredIcons = [];
  late List<String> _iconNames;
  late List<IconData> _iconData;
  bool _convertToImage = false; // 是否转换为图片

  // 使用预定义的图标映射表中的图标
  late List<IconData> allIcons;

  @override
  void initState() {
    super.initState();
    selectedIcon = widget.currentIcon;
    // 从AppIcons中获取所有预定义图标
    allIcons = AppIcons.predefinedIcons.values.toList();
    _iconNames = AppIcons.predefinedIcons.keys.toList();
    _iconData = AppIcons.predefinedIcons.values.toList();
    _updateFilteredIcons();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  // 过滤图标列表
  List<IconData> get filteredIcons => _cachedFilteredIcons;

  void _updateFilteredIcons() {
    List<IconData> result;
    if (searchQuery.isEmpty) {
      result = _iconData;
    } else {
      // 先过滤名称列表
      final filteredIndices =
          _iconNames
              .asMap()
              .entries
              .where((entry) {
                return entry.value.toLowerCase().contains(
                  searchQuery.toLowerCase(),
                );
              })
              .map((entry) => entry.key)
              .toList();

      // 转换为对应的图标数据
      result = filteredIndices.map((index) => _iconData[index]).toList();
    }

    // 重置页码当过滤结果变化时
    if (_currentPage > 0 && _currentPage * _iconsPerPage >= result.length) {
      _currentPage = 0;
    }

    _cachedFilteredIcons = result;
  }

  // 获取当前页的图标
  List<IconData> get _currentPageIcons {
    final start = _currentPage * _iconsPerPage;
    final end = start + _iconsPerPage;
    return filteredIcons.sublist(
      start.clamp(0, filteredIcons.length),
      end.clamp(0, filteredIcons.length),
    );
  }

  // 总页数
  int get _totalPages {
    return (filteredIcons.length / _iconsPerPage).ceil();
  }

  /// 将图标转换为图片
  Future<Map<String, dynamic>?> _convertIconToImage(IconData icon) async {
    try {
      // 创建测试环境来渲染图标
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // 设置画布大小
      const size = 100.0;

      // 绘制图标
      final iconPainter = IconPainter(
        icon: icon,
        size: 80.0,
        color: Colors.black,
      );
      iconPainter.paint(canvas, const Size(100, 100));

      // 结束录制
      final picture = recorder.endRecording();

      // 转换为图片
      final img = await picture.toImage(size.toInt(), size.toInt());
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData?.buffer.asUint8List();

      if (bytes != null) {
        return {
          'bytes': bytes,
          'icon': icon,
        };
      }
      return null;
    } catch (e) {
      print('图标转图片失败: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomDialog(
      title: '选择图标',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 搜索框
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: '搜索图标...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            onChanged: (value) {
              if (_debounceTimer?.isActive ?? false) {
                _debounceTimer?.cancel();
              }
              _debounceTimer = Timer(const Duration(milliseconds: 500), () {
                setState(() {
                  searchQuery = value;
                  _updateFilteredIcons();
                });
              });
            },
          ),
          const SizedBox(height: 16),

          // 图标转图片选项
          if (widget.enableIconToImage)
            Row(
              children: [
                Checkbox(
                  value: _convertToImage,
                  onChanged: (value) {
                    setState(() {
                      _convertToImage = value ?? false;
                    });
                  },
                ),
                const Expanded(
                  child: Text('将图标转换为图片'),
                ),
                IconButton(
                  icon: const Icon(Icons.help_outline),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('图标转图片'),
                        content: const Text(
                          '启用此选项后，选择的图标将被转换为 PNG 图片。'
                          '这对于不支持图标显示的环境（如某些桌面应用）很有用。'
                          '转换后的图片可以提供更好的视觉效果和兼容性。',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('确定'),
                          ),
                        ],
                      ),
                    );
                  },
                  tooltip: '什么是图标转图片？',
                ),
              ],
            ),

          if (widget.enableIconToImage) const SizedBox(height: 16),

          // 图标网格
          Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.4,
            ),
            child: GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                childAspectRatio: 1,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _currentPageIcons.length,
              itemBuilder: (context, index) {
                final icon = _currentPageIcons[index];
                final isSelected = icon == selectedIcon;
                return IconButton(
                  icon: Icon(icon),
                  color:
                      isSelected ? Theme.of(context).colorScheme.primary : null,
                  onPressed: () {
                    setState(() {
                      selectedIcon = icon;
                    });
                  },
                );
              },
            ),
          ),
          if (_totalPages > 1) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed:
                      _currentPage > 0
                          ? () => setState(() => _currentPage--)
                          : null,
                ),
                Text(
                  '${_currentPage + 1}/$_totalPages',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed:
                      _currentPage < _totalPages - 1
                          ? () => setState(() => _currentPage++)
                          : null,
                ),
              ],
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppLocalizations.of(context)!.cancel),
        ),
        ElevatedButton(
          onPressed: () async {
            if (_convertToImage) {
              final result = await _convertIconToImage(selectedIcon);
              Navigator.pop(context, result);
            } else {
              Navigator.pop(context, selectedIcon);
            }
          },
          child: Text(AppLocalizations.of(context)!.ok),
        ),
      ],
    );
  }
}

/// 图标绘制器
class IconPainter extends CustomPainter {
  final IconData icon;
  final double size;
  final Color color;

  IconPainter({
    required this.icon,
    required this.size,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 居中绘制图标
    final textPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: this.size,
          fontFamily: icon.fontFamily,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    final offset = Offset(
      (size.width - textPainter.width) / 2,
      (size.height - textPainter.height) / 2,
    );
    textPainter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 显示图标选择器对话框的工具方法
Future<dynamic> showIconPickerDialog(
  BuildContext context,
  IconData currentIcon, {
  bool enableIconToImage = true,
}) {
  // 使用原生showDialog，但确保使用rootNavigator以保证在最上层显示
  return showDialog<dynamic>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black54,
    useSafeArea: true,
    useRootNavigator: true, // 确保在根Navigator上显示，这样会在所有其他对话框之上
    builder: (context) => IconPickerDialog(
      currentIcon: currentIcon,
      enableIconToImage: enableIconToImage,
    ),
  );
}

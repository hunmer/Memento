import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'custom_dialog.dart';
import '../constants/app_icons.dart';

class IconPickerDialog extends StatefulWidget {
  final IconData currentIcon;

  const IconPickerDialog({super.key, required this.currentIcon});

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
      final filteredIndices = _iconNames.asMap().entries.where((entry) {
        return entry.value.toLowerCase().contains(searchQuery.toLowerCase());
      }).map((entry) => entry.key).toList();
      
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
                  color: isSelected 
                      ? Theme.of(context).colorScheme.primary
                      : null,
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
                  onPressed: _currentPage > 0
                      ? () => setState(() => _currentPage--)
                      : null,
                ),
                Text(
                  '${_currentPage + 1}/$_totalPages',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _currentPage < _totalPages - 1
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
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, selectedIcon),
          child: const Text('确定'),
        ),
      ],
    );
  }
}

// 显示图标选择器对话框的工具方法
Future<IconData?> showIconPickerDialog(
  BuildContext context,
  IconData currentIcon,
) {
  // 使用原生showDialog，但确保使用rootNavigator以保证在最上层显示
  return showDialog<IconData>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black54,
    useSafeArea: true,
    useRootNavigator: true, // 确保在根Navigator上显示，这样会在所有其他对话框之上
    builder: (context) => IconPickerDialog(currentIcon: currentIcon),
  );
}

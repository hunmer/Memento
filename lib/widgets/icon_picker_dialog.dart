import 'package:flutter/material.dart';
import 'custom_dialog.dart';

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

  // 所有可用的图标列表
  final List<IconData> allIcons = [
    Icons.chat,
    Icons.people,
    Icons.work,
    Icons.school,
    Icons.sports,
    Icons.music_note,
    Icons.movie,
    Icons.book,
    Icons.favorite,
    Icons.shopping_cart,
    Icons.home,
    Icons.settings,
    Icons.person,
    Icons.email,
    Icons.phone,
    Icons.camera,
    Icons.photo,
    Icons.video_camera_back,
    Icons.restaurant,
    Icons.local_cafe,
    Icons.local_bar,
    Icons.local_hotel,
    Icons.flight,
    Icons.directions_car,
    Icons.directions_bike,
    Icons.pets,
    Icons.nature,
    Icons.park,
    Icons.beach_access,
    Icons.ac_unit,
    Icons.whatshot,
    Icons.sports_esports,
    Icons.sports_basketball,
    Icons.sports_football,
    Icons.celebration,
    Icons.cake,
  ];

  @override
  void initState() {
    super.initState();
    selectedIcon = widget.currentIcon;
  }

  // 过滤图标列表
  List<IconData> get filteredIcons {
    if (searchQuery.isEmpty) {
      return allIcons;
    }
    // 这里的过滤逻辑比较简单，实际应用中可能需要更复杂的匹配算法
    return allIcons.where((icon) {
      final name = icon.toString().toLowerCase();
      return name.contains(searchQuery.toLowerCase());
    }).toList();
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
              setState(() {
                searchQuery = value;
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
              itemCount: filteredIcons.length,
              itemBuilder: (context, index) {
                final icon = filteredIcons[index];
                final isSelected = icon == selectedIcon;
                return InkWell(
                  onTap: () {
                    setState(() {
                      selectedIcon = icon;
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? Theme.of(
                                context,
                              ).colorScheme.primary.withOpacity(0.2)
                              : null,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color:
                            isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey.withOpacity(0.3),
                      ),
                    ),
                    child: Icon(
                      icon,
                      color:
                          isSelected
                              ? Theme.of(context).colorScheme.primary
                              : null,
                    ),
                  ),
                );
              },
            ),
          ),
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

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/widgets/super_cupertino_navigation_wrapper.dart';
import 'package:Memento/core/services/toast_service.dart';
class SuperCupertinoTestScreen extends StatefulWidget {
  const SuperCupertinoTestScreen({super.key});

  @override
  State<SuperCupertinoTestScreen> createState() =>
      _SuperCupertinoTestScreenState();
}

class _SuperCupertinoTestScreenState extends State<SuperCupertinoTestScreen> {
  List<String> _filteredItems = [];
  final List<String> _allItems = [
    '香蕉 (Banana)',
    '橙子 (Orange)',
    '葡萄 (Grape)',
    '草莓 (Strawberry)',
    '西瓜 (Watermelon)',
    '芒果 (Mango)',
    '菠萝 (Pineapple)',
    '柠檬 (Lemon)',
    '桃子 (Peach)',
    '梨子 (Pear)',
    '樱桃 (Cherry)',
  ];

  @override
  void initState() {
    super.initState();
    _filteredItems = _allItems;
  }

  void _onSearchChanged(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredItems = _allItems;
      } else {
        _filteredItems =
            _allItems
                .where(
                  (item) => item.toLowerCase().contains(query.toLowerCase()),
                )
                .toList();
      }
    });
  }

  void _onSearchSubmitted(String query) {
    toastService.showToast('搜索: $query');
  }

  Widget _buildBottomBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.only(left: 15.0),
        child: Row(
          children: [
            _buildFilterChip('全部', () {
              setState(() {
                _filteredItems = _allItems;
              });
            }),
            const SizedBox(width: 10),
            _buildFilterChip('水果', () {
              setState(() {
                _filteredItems = _allItems.take(6).toList();
              });
            }),
            const SizedBox(width: 10),
            _buildFilterChip('浆果', () {
              setState(() {
                _filteredItems =
                    _allItems
                        .where(
                          (item) =>
                              item.contains('莓') || item.contains('berry'),
                        )
                        .toList();
              });
            }),
            const SizedBox(width: 10),
            _buildFilterChip('柑橘类', () {
              setState(() {
                _filteredItems =
                    _allItems
                        .where(
                          (item) =>
                              item.contains('橙') ||
                              item.contains('柠檬') ||
                              item.contains('橘'),
                        )
                        .toList();
              });
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(
            color: Theme.of(context).primaryColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: Theme.of(context).primaryColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SuperCupertinoNavigationWrapper(
      title: Text('screens_superCupertinoTest'.tr),
      largeTitle: 'screens_fruitList'.tr,
      body: ListView.separated(
        padding: EdgeInsets.zero,
        itemCount: _filteredItems.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final item = _filteredItems[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: _getFruitColor(item),
              child: Icon(_getFruitIcon(item), color: Colors.white, size: 20),
            ),
            title: Text(item),
            subtitle: Text('screens_fruitIndex'.trParams({'index': (index + 1).toString()})),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              toastService.showToast('你选择了: $item');
            },
          );
        },
      ),
      enableLargeTitle: true,
      enableSearchBar: true,
      enableBottomBar: true,
      bottomBarHeight: 50,
      bottomBarChild: _buildBottomBar(),
      searchPlaceholder: '搜索水果...',
      onSearchChanged: _onSearchChanged,
      onSearchSubmitted: _onSearchSubmitted,
      actions: const [Icon(Icons.more_vert)],
      largeTitleActions: [
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: () {
            toastService.showToast('添加新水果');
          },
        ),
        IconButton(
          icon: const Icon(Icons.filter_list),
          onPressed: () {
            toastService.showToast('打开筛选器');
          },
        ),
      ],
      onCollapsed: (isCollapsed) {
        debugPrint('导航栏折叠状态: $isCollapsed');
      },
    );
  }

  IconData _getFruitIcon(String fruit) {
    if (fruit.contains('香蕉')) return CupertinoIcons.bolt;
    if (fruit.contains('橙子')) return Icons.circle;
    if (fruit.contains('葡萄')) return Icons.grain;
    if (fruit.contains('草莓')) return Icons.favorite;
    if (fruit.contains('西瓜')) return Icons.beach_access;
    return CupertinoIcons.circle_fill;
  }

  Color _getFruitColor(String fruit) {
    if (fruit.contains('香蕉')) return Colors.yellow;
    if (fruit.contains('橙子')) return Colors.orange;
    if (fruit.contains('葡萄')) return Colors.purple;
    if (fruit.contains('草莓')) return Colors.pink;
    if (fruit.contains('西瓜')) return Colors.green;
    return Colors.blue;
  }
}

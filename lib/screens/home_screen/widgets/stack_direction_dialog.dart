import 'package:flutter/material.dart';
import 'package:infinite_carousel/infinite_carousel.dart';
import 'package:get/get.dart';
import '../models/home_stack_item.dart';

Future<HomeStackDirection?> showStackDirectionDialog(BuildContext context) {
  return showDialog<HomeStackDirection>(
    context: context,
    builder: (context) => const _StackDirectionDialog(),
  );
}

class _StackDirectionDialog extends StatefulWidget {
  const _StackDirectionDialog();

  @override
  State<_StackDirectionDialog> createState() => _StackDirectionDialogState();
}

class _StackDirectionDialogState extends State<_StackDirectionDialog> {
  final List<_DirectionOption> _options = const [
    _DirectionOption(
      direction: HomeStackDirection.horizontal,
      title: '横向折叠',
      description: '左右滑动切换组件，适合宽屏布局',
      icon: Icons.view_week,
    ),
    _DirectionOption(
      direction: HomeStackDirection.vertical,
      title: '纵向折叠',
      description: '上下滑动切换组件，适合竖屏布局',
      icon: Icons.view_day,
    ),
  ];

  late final InfiniteScrollController _controller;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = InfiniteScrollController(initialItem: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text('screens_selectStackDirection'.tr),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.6,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('screens_selectStackDirectionDesc'.tr, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 16),
            ...List.generate(_options.length, (index) {
              final option = _options[index];
              final isSelected = _selectedIndex % _options.length == index;
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: isSelected ? 4 : 1,
                color: isSelected ? theme.colorScheme.primaryContainer : null,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: RadioListTile<int>(
                  value: index,
                  groupValue: _selectedIndex % _options.length,
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _selectedIndex = value;
                    });
                  },
                  title: Text(option.title),
                  subtitle: Text(option.description),
                  secondary: Icon(option.icon, color: theme.colorScheme.primary),
                ),
              );
            }),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('screens_cancel'.tr),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop(_options[_selectedIndex % _options.length].direction);
          },
          child: Text('screens_confirm'.tr),
        ),
      ],
    );
  }

}

class _DirectionOption {
  final HomeStackDirection direction;
  final String title;
  final String description;
  final IconData icon;

  const _DirectionOption({
    required this.direction,
    required this.title,
    required this.description,
    required this.icon,
  });
}

import 'package:flutter/material.dart';
import 'package:Memento/screens/l10n/screens_localizations.dart';

/// 布局类型选择器组件
class LayoutTypeSelector extends StatefulWidget {
  final String? initialType;
  final ValueChanged<String> onTypeChanged;
  final String? title;

  const LayoutTypeSelector({
    super.key,
    this.initialType,
    required this.onTypeChanged,
    this.title = '布局类型',
  });

  @override
  State<LayoutTypeSelector> createState() => _LayoutTypeSelectorState();
}

class _LayoutTypeSelectorState extends State<LayoutTypeSelector> {
  late String _selectedType;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType ?? 'empty';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = ScreensLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title!,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        RadioListTile<String>(
          title: Text(l10n.emptyLayout),
          subtitle: Text(l10n.emptyLayoutDescription),
          value: 'empty',
          groupValue: _selectedType,
          onChanged: (value) {
            setState(() {
              _selectedType = value!;
              widget.onTypeChanged(_selectedType);
            });
          },
        ),
        RadioListTile<String>(
          title: Text(l10n.all1x1Widgets),
          subtitle: Text(l10n.all1x1WidgetsDescription),
          value: '1x1',
          groupValue: _selectedType,
          onChanged: (value) {
            setState(() {
              _selectedType = value!;
              widget.onTypeChanged(_selectedType);
            });
          },
        ),
        RadioListTile<String>(
          title: Text(l10n.all2x2Widgets),
          subtitle: Text(l10n.all2x2WidgetsDescription),
          value: '2x2',
          groupValue: _selectedType,
          onChanged: (value) {
            setState(() {
              _selectedType = value!;
              widget.onTypeChanged(_selectedType);
            });
          },
        ),
      ],
    );
  }
}

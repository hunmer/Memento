import 'package:Memento/plugins/chat/l10n/chat_localizations.dart';
import 'package:flutter/material.dart';

class ChannelGroupSelector extends StatelessWidget {
  final String selectedGroup;
  final List<String> availableGroups;
  final Function(String) onGroupSelected;

  const ChannelGroupSelector({
    super.key,
    required this.selectedGroup,
    required this.availableGroups,
    required this.onGroupSelected,
  });

  getGroupName(String group, BuildContext context) {
    switch (group) {
      case "all":
        return ChatLocalizations.of(context).all;
      case "ungrouped":
        return ChatLocalizations.of(context).ungrouped;
      default:
        return group;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children:
              availableGroups.map((group) {
                final isSelected = group == selectedGroup;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    selected: isSelected,
                    label: Text(getGroupName(group, context)),
                    onSelected: (_) => onGroupSelected(group),
                    backgroundColor:
                        Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[800]
                            : Colors.grey[200],
                    selectedColor:
                        Theme.of(context).brightness == Brightness.dark
                            ? Colors.blue[900]
                            : Colors.blue[100],
                    checkmarkColor: Theme.of(context).colorScheme.onPrimary,
                    labelStyle: TextStyle(
                      color:
                          Theme.of(context).brightness == Brightness.dark
                              ? isSelected
                                  ? Colors.white
                                  : Colors.grey[300]
                              : isSelected
                              ? Colors.black87
                              : Colors.grey[700],
                    ),
                  ),
                );
              }).toList(),
        ),
      ),
    );
  }
}

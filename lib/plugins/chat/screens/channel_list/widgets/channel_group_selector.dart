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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: availableGroups.map((group) {
            final isSelected = group == selectedGroup;
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: FilterChip(
                selected: isSelected,
                label: Text(group),
                onSelected: (_) => onGroupSelected(group),
                backgroundColor: Colors.grey[200],
                selectedColor: Colors.blue[100],
                checkmarkColor: Colors.blue,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
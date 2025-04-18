import 'package:flutter/material.dart';

class CircleIconPicker extends StatelessWidget {
  final IconData selectedIcon;
  final Color selectedColor;
  final Function(IconData) onIconChanged;
  final Function(Color)? onColorChanged;

  const CircleIconPicker({
    Key? key,
    required this.selectedIcon,
    required this.selectedColor,
    required this.onIconChanged,
    this.onColorChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => _showIconPicker(context),
          child: CircleAvatar(
            radius: 32,
            backgroundColor: selectedColor,
            child: Icon(
              selectedIcon,
              color: Colors.white,
              size: 32,
            ),
          ),
        ),
        if (onColorChanged != null) ...[
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: _buildColorPicker(),
          ),
        ],
      ],
    );
  }

  List<Widget> _buildColorPicker() {
    final colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
    ];

    return colors.map((color) {
      return GestureDetector(
        onTap: () => onColorChanged?.call(color),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: selectedColor == color ? Colors.white : Colors.transparent,
              width: 2,
            ),
          ),
        ),
      );
    }).toList();
  }

  void _showIconPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _IconPickerSheet(
        selectedIcon: selectedIcon,
        onIconSelected: (icon) {
          onIconChanged(icon);
          Navigator.pop(context);
        },
      ),
    );
  }
}

class _IconPickerSheet extends StatelessWidget {
  final IconData selectedIcon;
  final Function(IconData) onIconSelected;

  const _IconPickerSheet({
    Key? key,
    required this.selectedIcon,
    required this.onIconSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final icons = [
      Icons.shopping_cart,
      Icons.restaurant,
      Icons.local_cafe,
      Icons.directions_bus,
      Icons.local_hospital,
      Icons.school,
      Icons.movie,
      Icons.sports_basketball,
      Icons.attach_money,
      Icons.account_balance,
      Icons.credit_card,
      Icons.home,
      Icons.flight_takeoff,
      Icons.phone_android,
      Icons.pets,
      Icons.fitness_center,
      Icons.card_giftcard,
      Icons.child_care,
      Icons.local_laundry_service,
      Icons.local_parking,
    ];

    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text(
            '选择图标',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
              ),
              itemCount: icons.length,
              itemBuilder: (context, index) {
                final icon = icons[index];
                return InkWell(
                  onTap: () => onIconSelected(icon),
                  child: Container(
                    decoration: BoxDecoration(
                      color: icon == selectedIcon
                          ? Theme.of(context).primaryColor.withOpacity(0.1)
                          : null,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      color: icon == selectedIcon
                          ? Theme.of(context).primaryColor
                          : null,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
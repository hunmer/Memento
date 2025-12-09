import 'package:flutter/material.dart';
import 'package:get/get.dart';

class InformationTab extends StatelessWidget {
  final TextEditingController titleController;
  final DateTime selectedDate;
  final Function() onSelectDate;
  final String Function(DateTime) formatDate;

  const InformationTab({
    super.key,
    required this.titleController,
    required this.selectedDate,
    required this.onSelectDate,
    required this.formatDate,
  });

  @override
  Widget build(BuildContext context) {

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题输入
          TextField(
            controller: titleController,
            decoration: InputDecoration(
              labelText: 'day_title'.tr,
              hintText: 'day_enterTitle'.tr,
            ),
            maxLength: 50,
          ),
          const SizedBox(height: 16),

          // 日期选择
          Row(
            children: [
              Text('day_targetDate'.tr),
              const SizedBox(width: 16),
              TextButton(
                onPressed: onSelectDate,
                child: Text(formatDate(selectedDate)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../usage_records_list.dart';
import '../controllers/form_controller.dart';

class UsageRecordsTab extends StatelessWidget {
  final GoodsItemFormController controller;
  final Function() onStateChanged;

  const UsageRecordsTab({
    super.key,
    required this.controller,
    required this.onStateChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                UsageRecordsList(
                  records: controller.usageRecords,
                  onRecordsChanged: (records) {
                    controller.usageRecords = records;
                    onStateChanged();
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
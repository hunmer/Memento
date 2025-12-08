import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:Memento/plugins/goods/models/goods_item.dart';
import 'package:Memento/plugins/goods/models/usage_record.dart';
import 'package:Memento/plugins/goods/l10n/goods_localizations.dart';

class GoodsItemHistoryPage extends StatefulWidget {
  final GoodsItem item;
  final String warehouseId;

  const GoodsItemHistoryPage({
    super.key,
    required this.item,
    required this.warehouseId,
  });

  @override
  State<GoodsItemHistoryPage> createState() => _GoodsItemHistoryPageState();
}

class _GoodsItemHistoryPageState extends State<GoodsItemHistoryPage> {
  late GoodsItem _item;

  @override
  void initState() {
    super.initState();
    _item = widget.item;
  }

  String _formatDate(DateTime date) {
    return DateFormat('yyyy年MM月dd日 HH:mm').format(date);
  }

  String _formatDuration(int? minutes) {
    if (minutes == null) return '-';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours > 0) {
      return '$hours小时 $mins分钟';
    }
    return '$mins分钟';
  }

  @override
  Widget build(BuildContext context) {
    // Sort records descending
    final records = List<UsageRecord>.from(_item.usageRecords)
      ..sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(GoodsLocalizations.of(context).usageHistory),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(32, 16, 16, 16), // Left padding for timeline
        itemCount: records.length,
        itemBuilder: (context, index) {
          final record = records[index];
          return _buildRecordItem(record, index == records.length - 1);
        },
      ),
    );
  }

  Widget _buildRecordItem(UsageRecord record, bool isLast) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Timeline line
        if (!isLast)
          Positioned(
            left: -24, // Adjust based on dot position
            top: 24,
            bottom: -16, // Extend to next item
            width: 2,
            child: Container(
              color: Theme.of(context).dividerColor,
            ),
          ),
        
        // Dot
        Positioned(
          left: -31,
          top: 12,
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).scaffoldBackgroundColor,
                width: 4,
              ),
            ),
          ),
        ),

        // Card
        Container(
          margin: const EdgeInsets.only(bottom: 24),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header (Date)
                Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 16,
                      color: Theme.of(context).hintColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _formatDate(record.date),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Divider(height: 1, color: Theme.of(context).dividerColor.withOpacity(0.5)),
                const SizedBox(height: 12),

                // Duration
                _buildInfoRow(
                  Icons.hourglass_empty,
                  '使用时长', // TODO: Localize
                  _formatDuration(record.duration),
                ),
                const SizedBox(height: 8),

                // Location
                _buildInfoRow(
                  Icons.location_on,
                  '使用地点', // TODO: Localize
                  record.location ?? '-',
                ),
                const SizedBox(height: 8),

                // Note
                _buildInfoRow(
                  Icons.sticky_note_2,
                  '备注', // TODO: Localize
                  record.note ?? '-',
                  isNote: true,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {bool isNote = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: Theme.of(context).hintColor,
        ),
        const SizedBox(width: 6),
        if (isNote)
          Expanded(
            child: RichText(
              text: TextSpan(
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 14),
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: TextStyle(color: Theme.of(context).hintColor),
                  ),
                  TextSpan(
                    text: value,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: Row(
              children: [
                Text(
                  '$label: ',
                  style: TextStyle(color: Theme.of(context).hintColor, fontSize: 14),
                ),
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

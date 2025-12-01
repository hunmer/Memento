import 'package:flutter/material.dart';
import '../../../plugins/bill/bill_plugin.dart';
import '../../plugin_manager.dart';
import 'plugin_widget_syncer.dart';
import 'package:memento_widgets/memento_widgets.dart';

/// 账单插件同步器
class BillSyncer extends PluginWidgetSyncer {
  @override
  Future<void> sync() async {
    await syncSafely('bill', () async {
      final plugin = PluginManager.instance.getPlugin('bill') as BillPlugin?;
      if (plugin == null) return;

      final todayFinance = plugin.controller.getTodayFinance();
      final monthFinance = plugin.controller.getMonthFinance();

      await updateWidget(
        pluginId: 'bill',
        pluginName: '账单',
        iconCodePoint: Icons.account_balance_wallet.codePoint,
        colorValue: Colors.green.value,
        stats: [
          WidgetStatItem(
            id: 'today',
            label: '今日',
            value: '¥${todayFinance.toStringAsFixed(0)}',
            colorValue: todayFinance >= 0 ? Colors.green.value : Colors.red.value,
          ),
          WidgetStatItem(
            id: 'month',
            label: '本月',
            value: '¥${monthFinance.toStringAsFixed(0)}',
            colorValue: monthFinance >= 0 ? Colors.green.value : Colors.red.value,
          ),
        ],
      );
    });
  }
}

import 'package:flutter/material.dart';
import '../../core/plugin_base.dart';
import '../../core/plugin_manager.dart';
import 'controls/bill_controller.dart';
import 'controls/prompt_controller.dart';
import 'screens/bill_list_screen.dart';
import 'screens/bill_stats_screen.dart';
import 'screens/account_list_screen.dart';
import 'models/account.dart';
import 'models/bill.dart';
import 'models/bill_statistics.dart';
import 'models/statistic_range.dart';

class BillPlugin extends PluginBase with ChangeNotifier {
  late final BillController _billController;
  late final PromptController _promptController;

  BillPlugin() {
    _billController = BillController()..setPlugin(this);
    _promptController = PromptController();
  }

  @override
  String get id => 'bill';

  @override
  String get name => '账单';

  @override
  String get version => '1.0.0';

  @override
  String get description => '管理个人账单和财务统计';

  @override
  String get author => 'Memento Team';

  @override
  IconData get icon => Icons.account_balance_wallet;

  @override
  Color get color => Colors.green;

  Account? get selectedAccount => _billController.selectedAccount;
  set selectedAccount(Account? account) =>
      _billController.selectedAccount = account;
  String? get selectedAccountId => _billController.selectedAccountId;
  List<Account> get accounts => _billController.accounts;

  // 暴露账单控制器
  BillController get controller => _billController;

  @override
  Future<void> initialize() async {
    _promptController.initialize();
  }

  Future<void> uninstall() async {
    _promptController.unregisterPromptMethods();
    await storage.delete(storageDir);
  }

  @override
  Widget buildMainView(BuildContext context) {
    return buildPluginEntryWidget(context);
  }

  @override
  Widget? buildCardView(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 顶部图标和标题
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 24, color: color),
              ),
              const SizedBox(width: 12),
              Text(
                name,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 统计信息卡片
          Column(
            children: [
              // 第一行 - 今日财务和本月财务
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // 今日财务
                  Column(
                    children: [
                      Text('今日财务', style: theme.textTheme.bodyMedium),
                      Text(
                        '¥${_billController.getTodayFinance().toStringAsFixed(2)}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color:
                              _billController.getTodayFinance() >= 0
                                  ? Colors.green
                                  : Colors.red,
                        ),
                      ),
                    ],
                  ),

                  // 本月财务
                  Column(
                    children: [
                      Text('本月财务', style: theme.textTheme.bodyMedium),
                      Text(
                        '¥${_billController.getMonthFinance().toStringAsFixed(2)}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color:
                              _billController.getMonthFinance() >= 0
                                  ? Colors.green
                                  : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 第二行 - 本月记账
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Column(
                    children: [
                      Text('本月记账', style: theme.textTheme.bodyMedium),
                      Text(
                        '${_billController.getMonthBillCount()} 笔',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _settings = {};

  @override
  Map<String, dynamic> get settings => _settings;

  @override
  Future<void> loadSettings(Map<String, dynamic> defaultSettings) async {
    try {
      final storedSettings = await storage.read(
        '${getPluginStoragePath()}/settings.json',
      );
      if (storedSettings.isNotEmpty) {
        _settings = Map<String, dynamic>.from(storedSettings);
      } else {
        _settings = Map<String, dynamic>.from(defaultSettings);
        await saveSettings();
      }
    } catch (e) {
      _settings = Map<String, dynamic>.from(defaultSettings);
      try {
        await saveSettings();
      } catch (e) {
        debugPrint('Warning: Failed to save plugin settings: $e');
      }
    }
  }

  @override
  Future<void> saveSettings() async {
    try {
      await storage.write('${getPluginStoragePath()}/settings.json', _settings);
    } catch (e) {
      debugPrint('Warning: Failed to save plugin settings: $e');
    }
  }

  @override
  Future<void> updateSettings(Map<String, dynamic> newSettings) async {
    _settings.addAll(newSettings);
    await saveSettings();
  }

  @override
  String getPluginStoragePath() {
    return storage.getPluginStoragePath(id);
  }

  @override
  Widget buildSettingsView(BuildContext context) {
    return Column(children: [
      
      ],
    );
  }

  Widget buildPluginEntryWidget(BuildContext context) {
    // 如果没有账户，跳转到账户列表页面
    if (accounts.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => AccountListScreen(billPlugin: this),
          ),
        );
      });
      return const Center(child: CircularProgressIndicator());
    }
    if (selectedAccountId == null && accounts.isNotEmpty) {
      selectedAccount = accounts.first;
    }
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => PluginManager.toHomeScreen(context),
          ),
          title: Text('${selectedAccount?.title}'),
          bottom: const TabBar(tabs: [Tab(text: '账单列表'), Tab(text: '统计分析')]),
          actions: [
            IconButton(
              icon: const Icon(Icons.list),
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => AccountListScreen(billPlugin: this),
                  ),
                );
              },
            ),
          ],
        ),
        body: TabBarView(
          children: [
            BillListScreen(billPlugin: this, accountId: selectedAccount!.id),
            BillStatsScreen(
              billPlugin: this,
              accountId: selectedAccount!.id,
              startDate: DateTime.now().subtract(
                const Duration(days: 30),
              ), // 默认显示最近30天
              endDate: DateTime.now(),
            ),
          ],
        ),
      ),
    );
  }

  // 委托方法到BillController
  Future<void> createAccount(Account account) async {
    await _billController.createAccount(account);
    notifyListeners(); // 添加通知，确保UI更新
  }

  // 修改saveAccount方法，在保存账户后通知监听器
  Future<void> saveAccount(Account account) async {
    await _billController.saveAccount(account);
    notifyListeners(); // 添加通知，确保UI更新
  }

  Future<void> deleteAccount(String accountId) =>
      _billController.deleteAccount(accountId);
  Future<void> deleteBill(String accountId, String billId) =>
      _billController.deleteBill(accountId, billId);
  BillStatistics getStatistics({
    required List<Bill> bills,
    required StatisticRange range,
    DateTime? startDate,
    DateTime? endDate,
  }) => _billController.getStatistics(
    bills: bills,
    range: range,
    startDate: startDate,
    endDate: endDate,
  );
}

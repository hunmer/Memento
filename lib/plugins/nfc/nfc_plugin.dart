import 'dart:async';
import 'package:Memento/core/plugin_base.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/core/config_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:Memento/core/services/toast_service.dart';
import 'package:get/get.dart';
import 'nfc_controller.dart';
import 'card_handlers/read_card_handler.dart';
import 'card_handlers/custom_write_card_handler.dart';
import 'card_handlers/checkin_card_handler.dart';
import 'card_handlers/goods_usage_card_handler.dart';

/// NFC控制器插件主视图
class NfcMainView extends StatefulWidget {
  const NfcMainView({super.key});

  @override
  State<NfcMainView> createState() => _NfcMainViewState();
}

class _NfcMainViewState extends State<NfcMainView> {
  late final NfcController _controller;
  late final ReadCardHandler _readCardHandler;
  late final CustomWriteCardHandler _writeCardHandler;
  late final CheckinCardHandler _checkinCardHandler;
  late final GoodsUsageCardHandler _goodsUsageCardHandler;

  bool _isReading = false;
  bool _isWriting = false;

  @override
  void initState() {
    super.initState();
    _controller = NfcController();
    _readCardHandler = ReadCardHandler(onRead: _readNfc);
    _writeCardHandler = CustomWriteCardHandler(onWrite: _writeNfcRecords);
    _checkinCardHandler = CheckinCardHandler();
    _goodsUsageCardHandler = GoodsUsageCardHandler();
    _checkNfcStatus();
  }

  Future<void> _checkNfcStatus() async {
    await _controller.checkNfcStatus();
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _readNfc() async {
    setState(() {
      _isReading = true;
    });

    // 先显示等待对话框
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text('nfc_pleaseBringPhoneNearNFC'.tr),
              const SizedBox(height: 8),
              Text(
                '等待读取NFC数据...',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final result = await _controller.readNfc();

      // 关闭等待对话框
      if (mounted) {
        Navigator.of(context).pop();
      }

      setState(() {
        _isReading = false;
      });

      if (result.success) {
        final readData = result.data ?? '';
        if (readData.isNotEmpty) {
          _controller.showSuccess('读取成功');
          _showNfcDataDialog(readData);
        } else {
          _controller.showError('未检测到NFC数据');
        }
      } else {
        _controller.showError(result.error ?? '读取失败');
      }
    } catch (e) {
      // 关闭等待对话框
      if (mounted) {
        Navigator.of(context).pop();
      }
      setState(() {
        _isReading = false;
      });
      _controller.showError('读取错误: $e');
    }
  }

  /// 写入多条 NFC 记录
  Future<void> _writeNfcRecords(List<Map<String, String>> records) async {
    setState(() {
      _isWriting = true;
    });

    // 显示等待对话框
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text('nfc_pleaseBringPhoneNearNFC'.tr),
              const SizedBox(height: 8),
              Text(
                '正在写入 ${records.length} 条记录...',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final result = await _controller.writeNfcRecords(records);

      // 关闭等待对话框
      if (mounted) {
        Navigator.of(context).pop();
      }

      setState(() {
        _isWriting = false;
      });

      if (result.success) {
        _controller.showSuccess('写入成功');
      } else {
        _controller.showError(result.error ?? '写入失败');
      }
    } catch (e) {
      // 关闭等待对话框
      if (mounted) {
        Navigator.of(context).pop();
      }
      setState(() {
        _isWriting = false;
      });
      _controller.showError('写入错误: $e');
    }
  }

  void _showNfcDataDialog(String data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('nfc_nfcData'.tr),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '读取到的数据：',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(data),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('nfc_close'.tr),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Clipboard.setData(ClipboardData(text: data));
              Toast.success('已复制到剪贴板');
            },
            child: Text('nfc_copyData'.tr),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('nfc_nfcController'.tr),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _checkNfcStatus,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // NFC 状态卡片
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'NFC状态',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          _controller.isNfcSupported ? Icons.check_circle : Icons.cancel,
                          color: _controller.isNfcSupported ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _controller.isNfcSupported ? '支持NFC' : '不支持NFC',
                          style: TextStyle(
                            color: _controller.isNfcSupported ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          _controller.isNfcEnabled ? Icons.check_circle : Icons.cancel,
                          color: _controller.isNfcEnabled ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _controller.isNfcEnabled ? 'NFC已启用' : 'NFC未启用',
                          style: TextStyle(
                            color: _controller.isNfcEnabled ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                    if (!_controller.isNfcEnabled)
                      Padding(
                        padding: const EdgeInsets.only(top: 12.0),
                        child: ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.settings),
                          label: Text('nfc_enableNFC'.tr),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // NFC操作卡片 - 一行两个
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _readCardHandler.buildCard(context, _controller.isNfcEnabled, _isReading),
                const SizedBox(width: 16),
                _writeCardHandler.buildCard(context, _controller.isNfcEnabled, _isWriting),
              ],
            ),
            const SizedBox(height: 16),
            // 写入签到卡片
            _checkinCardHandler.buildCard(context, _controller.isNfcEnabled, false),
            const SizedBox(height: 16),
            // 写入物品使用记录卡片
            _goodsUsageCardHandler.buildCard(context, _controller.isNfcEnabled, false),
          ],
        ),
      ),
    );
  }
}

class NfcPlugin extends PluginBase {
  static NfcPlugin? _instance;

  static NfcPlugin get instance {
    if (_instance == null) {
      _instance = PluginManager.instance.getPlugin('nfc') as NfcPlugin?;
      if (_instance == null) {
        throw StateError('NfcPlugin has not been initialized');
      }
    }
    return _instance!;
  }

  @override
  String get id => 'nfc';

  @override
  IconData get icon => Icons.nfc;

  @override
  Color get color => Colors.orange;

  @override
  Future<void> initialize() async {
    await loadSettings({});
  }

  @override
  Future<void> registerToApp(
    PluginManager pluginManager,
    ConfigManager configManager,
  ) async {
    // 插件已在 initialize() 中完成初始化
    // 这里可以添加额外的应用级注册逻辑
  }

  @override
  Widget buildMainView(BuildContext context) {
    return const NfcMainView();
  }

  @override
  Widget? buildCardView(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.nfc, size: 48, color: color),
            const SizedBox(height: 8),
            const Text(
              'NFC控制器',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              '读取和写入NFC标签',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  @override
  String? getPluginName(context) {
    return 'nfc_pluginName'.tr;
  }
}

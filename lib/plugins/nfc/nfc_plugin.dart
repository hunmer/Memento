import 'dart:async';
import 'package:Memento/core/plugin_base.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/core/config_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:memento_nfc/memento_nfc.dart';
import 'package:Memento/core/services/toast_service.dart';
import 'package:get/get.dart';

/// NFC控制器插件主视图
class NfcMainView extends StatefulWidget {
  const NfcMainView({super.key});

  @override
  State<NfcMainView> createState() => _NfcMainViewState();
}

class _NfcMainViewState extends State<NfcMainView> {
  bool _isNfcSupported = false;
  bool _isNfcEnabled = false;
  bool _isReading = false;
  bool _isWriting = false;

  @override
  void initState() {
    super.initState();
    _checkNfcStatus();
  }

  Future<void> _checkNfcStatus() async {
    final nfc = MementoNfc();
    try {
      final supported = await nfc.isNfcSupported();
      final enabled = await nfc.isNfcEnabled();
      setState(() {
        _isNfcSupported = supported;
        _isNfcEnabled = enabled;
      });
    } catch (e) {
      print('Error checking NFC status: $e');
    }
  }

  Future<void> _readNfc() async {
    if (!_isNfcEnabled) {
      _showError('请先启用NFC');
      return;
    }

    setState(() {
      _isReading = true;
    });

    // 先显示等待对话框
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => WillPopScope(
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
      final nfc = MementoNfc();
      final result = await nfc.readNfc();

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
          _showSuccess('读取成功');
          // 显示读取到的数据对话框
          _showNfcDataDialog(readData);
        } else {
          _showError('未检测到NFC数据');
        }
      } else {
        _showError(result.error ?? '读取失败');
      }
    } catch (e) {
      // 关闭等待对话框
      if (mounted) {
        Navigator.of(context).pop();
      }
      setState(() {
        _isReading = false;
      });
      _showError('读取错误: $e');
    }
  }

  Future<void> _writeNfc(String data) async {
    if (!_isNfcEnabled) {
      _showError('请先启用NFC');
      return;
    }

    setState(() {
      _isWriting = true;
    });

    // 先显示等待对话框
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => WillPopScope(
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
                    '正在写入数据...\n$data',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
    );

    try {
      final nfc = MementoNfc();
      final result = await nfc.writeNfc(data);

      // 关闭等待对话框
      if (mounted) {
        Navigator.of(context).pop();
      }

      setState(() {
        _isWriting = false;
      });

      if (result.success) {
        _showSuccess('写入成功');
      } else {
        _showError(result.error ?? '写入失败');
      }
    } catch (e) {
      // 关闭等待对话框
      if (mounted) {
        Navigator.of(context).pop();
      }
      setState(() {
        _isWriting = false;
      });
      _showError('写入错误: $e');
    }
  }

  void _showError(String message) {
    Toast.error(message);
  }

  void _showSuccess(String message) {
    Toast.success(message);
  }

  void _showWriteDialog() {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('nfc_writeNFCData'.tr),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  decoration: const InputDecoration(hintText: '请输入要写入的数据'),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue[700],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '点击"开始写入"后，请将手机靠近NFC标签',
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('nfc_cancel'.tr),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  if (controller.text.isNotEmpty) {
                    _writeNfc(controller.text);
                  }
                },
                child: Text('nfc_startWriting'.tr),
              ),
            ],
          ),
    );
  }

  void _showNfcDataDialog(String data) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
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
                          _isNfcSupported ? Icons.check_circle : Icons.cancel,
                          color: _isNfcSupported ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isNfcSupported ? '支持NFC' : '不支持NFC',
                          style: TextStyle(
                            color: _isNfcSupported ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          _isNfcEnabled ? Icons.check_circle : Icons.cancel,
                          color: _isNfcEnabled ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isNfcEnabled ? 'NFC已启用' : 'NFC未启用',
                          style: TextStyle(
                            color: _isNfcEnabled ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                    if (!_isNfcEnabled)
                      Padding(
                        padding: const EdgeInsets.only(top: 12.0),
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // 尝试打开NFC设置
                            if (Theme.of(context).platform ==
                                TargetPlatform.android) {
                              // Android: 打开NFC设置
                              // 需要添加权限
                            } else if (Theme.of(context).platform ==
                                TargetPlatform.iOS) {
                              // iOS: 打开设置
                              // iOS无法直接打开NFC设置，需要引导用户手动打开
                            }
                          },
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
                // 读取NFC卡片
                Expanded(
                  child: Card(
                    elevation: 2,
                    child: InkWell(
                      onTap: _isReading || !_isNfcEnabled ? null : _readNfc,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                shape: BoxShape.circle,
                              ),
                              child: _isReading
                                  ? const Center(
                                    child: SizedBox(
                                      width: 32,
                                      height: 32,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 3,
                                      ),
                                    ),
                                  )
                                  : Icon(
                                    Icons.nfc,
                                    size: 32,
                                    color: _isNfcEnabled
                                        ? Colors.blue[700]
                                        : Colors.grey,
                                  ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _isReading ? '读取中...' : '读取NFC',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '将手机靠近\nNFC标签读取',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // 写入NFC卡片
                Expanded(
                  child: Card(
                    elevation: 2,
                    child: InkWell(
                      onTap: _isWriting || !_isNfcEnabled
                          ? null
                          : _showWriteDialog,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: Colors.orange[50],
                                shape: BoxShape.circle,
                              ),
                              child: _isWriting
                                  ? const Center(
                                    child: SizedBox(
                                      width: 32,
                                      height: 32,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 3,
                                      ),
                                    ),
                                  )
                                  : Icon(
                                    Icons.edit,
                                    size: 32,
                                    color: _isNfcEnabled
                                        ? Colors.orange[700]
                                        : Colors.grey,
                                  ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _isWriting ? '写入中...' : '写入NFC',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '输入数据后\n靠近标签写入',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
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

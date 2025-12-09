import 'dart:async';
import 'package:Memento/core/plugin_base.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/core/config_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:memento_nfc/memento_nfc.dart';
import 'package:Memento/core/services/toast_service.dart';
import 'package:Memento/core/services/plugin_data_selector/index.dart';
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
  bool _isWritingCheckin = false;

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

  void _showError(String message) {
    Toast.error(message);
  }

  void _showSuccess(String message) {
    Toast.success(message);
  }

  void _showWriteDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => _NfcWriteDialog(
        onWrite: (records) {
          Navigator.pop(dialogContext);
          _writeNfcRecords(records);
        },
      ),
    );
  }

  /// 写入多条 NFC 记录
  Future<void> _writeNfcRecords(List<Map<String, String>> records) async {
    if (!_isNfcEnabled) {
      _showError('请先启用NFC');
      return;
    }

    setState(() {
      _isWriting = true;
    });

    // 显示等待对话框
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
      final nfc = MementoNfc();
      final result = await nfc.writeNfcRecords(records);

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

  /// 写入签到到 NFC
  Future<void> _writeCheckinToNfc() async {
    if (!_isNfcEnabled) {
      _showError('请先启用NFC');
      return;
    }

    // 打开签到项目选择器
    if (!mounted) return;

    final result = await pluginDataSelectorService.showSelector(
      context,
      'checkin.item',
    );

    if (result == null || result.cancelled) {
      return;
    }

    // 获取选择的签到项目 ID 和名称
    final itemId = result.path.isNotEmpty ? result.path.last.selectedItem.id : null;
    final itemName = result.path.isNotEmpty ? result.path.last.selectedItem.title : null;

    if (itemId == null) {
      Toast.error('未能获取签到项目 ID');
      return;
    }

    // 构建深度链接 URL
    final deepLinkUrl = 'memento://checkin/item?itemId=$itemId&action=checkin';

    // 使用与 _writeNfc 相同的方式写入
    setState(() {
      _isWritingCheckin = true;
    });

    // 先显示等待对话框
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (dialogContext) => WillPopScope(
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
                    '正在写入签到数据...\n签到项: $itemName',
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
      // 同时写入 URI 和 AAR 记录，确保扫描时打开正确的应用
      // URI 记录包含深度链接，AAR 记录确保打开 Memento 应用
      final writeResult = await nfc.writeNfcRecords([
        {'type': 'URI', 'data': deepLinkUrl},
        {'type': 'AAR', 'data': 'github.hunmer.memento'},
      ]);

      // 关闭等待对话框
      if (mounted) {
        Navigator.of(context).pop();
      }

      setState(() {
        _isWritingCheckin = false;
      });

      if (writeResult.success) {
        _showSuccess('写入成功！扫描此标签即可快速签到「$itemName」');
      } else {
        _showError(writeResult.error ?? '写入失败');
      }
    } catch (e) {
      // 关闭等待对话框
      if (mounted) {
        Navigator.of(context).pop();
      }
      setState(() {
        _isWritingCheckin = false;
      });
      _showError('写入错误: $e');
    }
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
            const SizedBox(height: 16),
            // 写入签到卡片
            Card(
              elevation: 2,
              child: InkWell(
                onTap: _isWritingCheckin || !_isNfcEnabled
                    ? null
                    : _writeCheckinToNfc,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.teal[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: _isWritingCheckin
                            ? const Center(
                                child: SizedBox(
                                  width: 28,
                                  height: 28,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                  ),
                                ),
                              )
                            : Icon(
                                Icons.checklist,
                                size: 28,
                                color: _isNfcEnabled
                                    ? Colors.teal[700]
                                    : Colors.grey,
                              ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isWritingCheckin ? '写入中...' : '写入签到',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '选择签到项后写入NFC标签，扫描即可自动签到',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: _isNfcEnabled ? Colors.teal[700] : Colors.grey,
                      ),
                    ],
                  ),
                ),
              ),
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

/// NFC 记录类型
enum NfcRecordType {
  uri('URI', '链接/URI', Icons.link),
  text('TEXT', '纯文本', Icons.text_fields),
  mime('MIME', 'MIME类型', Icons.data_object),
  aar('AAR', '应用记录', Icons.android),
  external_('EXTERNAL', '外部类型', Icons.extension);

  final String value;
  final String label;
  final IconData icon;
  const NfcRecordType(this.value, this.label, this.icon);
}

/// NFC 记录数据模型
class NfcRecordItem {
  NfcRecordType type;
  String data;
  final TextEditingController controller;

  NfcRecordItem({
    this.type = NfcRecordType.text,
    this.data = '',
  }) : controller = TextEditingController(text: data);

  void dispose() {
    controller.dispose();
  }

  Map<String, String> toMap() {
    return {
      'type': type.value,
      'data': controller.text,
    };
  }
}

/// NFC 写入对话框
class _NfcWriteDialog extends StatefulWidget {
  final Function(List<Map<String, String>>) onWrite;

  const _NfcWriteDialog({required this.onWrite});

  @override
  State<_NfcWriteDialog> createState() => _NfcWriteDialogState();
}

class _NfcWriteDialogState extends State<_NfcWriteDialog> {
  final List<NfcRecordItem> _records = [];

  @override
  void initState() {
    super.initState();
    // 默认添加一条空记录
    _addRecord();
  }

  @override
  void dispose() {
    for (var record in _records) {
      record.dispose();
    }
    super.dispose();
  }

  void _addRecord() {
    setState(() {
      _records.add(NfcRecordItem());
    });
  }

  void _removeRecord(int index) {
    if (_records.length > 1) {
      setState(() {
        _records[index].dispose();
        _records.removeAt(index);
      });
    }
  }

  String _getHintText(NfcRecordType type) {
    switch (type) {
      case NfcRecordType.uri:
        return '例如: https://example.com 或 memento://...';
      case NfcRecordType.text:
        return '输入要写入的文本内容';
      case NfcRecordType.mime:
        return '格式: mime类型|内容 (例如: application/json|{"key":"value"})';
      case NfcRecordType.aar:
        return '应用包名 (例如: github.hunmer.memento)';
      case NfcRecordType.external_:
        return '格式: domain:type|内容 (例如: memento:checkin|item_id)';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.edit_note),
          const SizedBox(width: 8),
          Text('nfc_writeNFCData'.tr),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 提示信息
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '支持添加多条记录，点击"开始写入"后靠近NFC标签',
                      style: TextStyle(color: Colors.blue[700], fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // 记录列表
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.4,
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _records.length,
                itemBuilder: (context, index) {
                  final record = _records[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 记录头部：类型选择 + 删除按钮
                          Row(
                            children: [
                              Text(
                                '记录 ${index + 1}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              const Spacer(),
                              // 类型选择下拉框
                              DropdownButton<NfcRecordType>(
                                value: record.type,
                                isDense: true,
                                underline: const SizedBox(),
                                items: NfcRecordType.values.map((type) {
                                  return DropdownMenuItem(
                                    value: type,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(type.icon, size: 16),
                                        const SizedBox(width: 4),
                                        Text(type.label, style: const TextStyle(fontSize: 13)),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      record.type = value;
                                    });
                                  }
                                },
                              ),
                              const SizedBox(width: 8),
                              // 删除按钮
                              if (_records.length > 1)
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 20),
                                  color: Colors.red,
                                  onPressed: () => _removeRecord(index),
                                  constraints: const BoxConstraints(),
                                  padding: EdgeInsets.zero,
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // 数据输入框
                          TextField(
                            controller: record.controller,
                            decoration: InputDecoration(
                              hintText: _getHintText(record.type),
                              hintStyle: const TextStyle(fontSize: 12),
                              border: const OutlineInputBorder(),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              isDense: true,
                            ),
                            maxLines: 2,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            // 添加记录按钮
            TextButton.icon(
              onPressed: _addRecord,
              icon: const Icon(Icons.add),
              label: const Text('添加记录'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('nfc_cancel'.tr),
        ),
        ElevatedButton.icon(
          onPressed: () {
            // 过滤空记录
            final records = _records
                .where((r) => r.controller.text.isNotEmpty)
                .map((r) => r.toMap())
                .toList();
            if (records.isEmpty) {
              Toast.error('请至少输入一条记录');
              return;
            }
            widget.onWrite(records);
          },
          icon: const Icon(Icons.nfc),
          label: Text('nfc_startWriting'.tr),
        ),
      ],
    );
  }
}

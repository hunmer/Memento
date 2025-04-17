import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:crop_your_image/crop_your_image.dart';
import 'dart:typed_data';
import 'dart:convert';
import '../models/goods_item.dart';
import '../models/custom_field.dart';
import '../models/usage_record.dart';
import '../../../widgets/circle_icon_picker.dart';
import 'image_picker_dialog.dart';

class GoodsItemForm extends StatefulWidget {
  final GoodsItem? item;
  final Function(GoodsItem) onSave;

  const GoodsItemForm({super.key, this.item, required this.onSave});

  @override
  State<GoodsItemForm> createState() => _GoodsItemFormState();
}

class _GoodsItemFormState extends State<GoodsItemForm>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final _cropController = CropController();
  Uint8List? _imageBytes;
  bool _isCropping = false;

  late String _title;
  String? _imageUrl;
  IconData? _icon;
  Color? _iconColor;
  List<String> _tags = [];
  DateTime? _purchaseDate;
  double? _purchasePrice;
  List<UsageRecord> _usageRecords = [];
  List<CustomField> _customFields = [];
  String? _notes;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    if (widget.item != null) {
      _title = widget.item!.title;
      _imageUrl = widget.item!.imageUrl;
      _icon = widget.item!.icon;
      _iconColor = widget.item!.iconColor;
      _tags = List.from(widget.item!.tags);
      _purchaseDate = widget.item!.purchaseDate;
      _purchasePrice = widget.item!.purchasePrice;
      _usageRecords = List.from(widget.item!.usageRecords);
      _customFields = List.from(widget.item!.customFields);
      _notes = widget.item!.notes;
    } else {
      _title = '';
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _addCustomField() {
    setState(() {
      _customFields.add(CustomField(key: '', value: ''));
    });
  }

  void _removeCustomField(int index) {
    setState(() {
      _customFields.removeAt(index);
    });
  }

  void _addUsageRecord() {
    setState(() {
      _usageRecords.add(UsageRecord(date: DateTime.now()));
    });
  }

  void _removeUsageRecord(int index) {
    setState(() {
      _usageRecords.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(widget.item == null ? '新增物品' : '编辑物品'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                _formKey.currentState!.save();
                // TODO: 在实际应用中，这里应该先上传图片到服务器，获取URL后再保存
                // 临时解决方案：如果有新裁剪的图片，使用base64编码作为URL
                String? finalImageUrl = _imageUrl;
                if (_imageBytes != null) {
                  // 将图片数据转换为base64字符串作为临时URL
                  finalImageUrl =
                      'data:image/png;base64,${base64Encode(_imageBytes!)}';
                }

                final item = GoodsItem(
                  id: widget.item?.id ?? const Uuid().v4(),
                  title: _title,
                  imageUrl: finalImageUrl,
                  icon: _icon,
                  iconColor: _iconColor,
                  tags: _tags,
                  purchaseDate: _purchaseDate,
                  purchasePrice: _purchasePrice,
                  usageRecords: _usageRecords,
                  customFields: _customFields,
                  notes: _notes,
                );
                widget.onSave(item);
              }
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: '基础'), Tab(text: '价格'), Tab(text: '信息')],
        ),
      ),
      body: Form(
        key: _formKey,
        child: TabBarView(
          controller: _tabController,
          children: [
            // 基础信息
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // 图标选择
                  CircleIconPicker(
                    currentIcon: _icon ?? Icons.image,
                    backgroundColor: _iconColor ?? Colors.blue,
                    onIconSelected: (icon) {
                      setState(() {
                        _icon = icon;
                      });
                    },
                    onColorSelected: (color) {
                      setState(() {
                        _iconColor = color;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  // 图片选择
                  Card(
                    child: InkWell(
                      onTap: () async {
                        final result = await showDialog<Map<String, dynamic>>(
                          context: context,
                          builder:
                              (context) =>
                                  ImagePickerDialog(initialUrl: _imageUrl),
                        );
                        if (result != null && result['bytes'] != null) {
                          setState(() {
                            _imageBytes = result['bytes'];
                            _isCropping = true;
                          });
                        }
                      },
                      child:
                          _isCropping
                              ? SizedBox(
                                height: 400,
                                child: Stack(
                                  children: [
                                    Crop(
                                      image: _imageBytes!,
                                      controller: _cropController,
                                      onCropped: (result) {
                                        switch (result) {
                                          case CropSuccess(:final croppedImage):
                                            setState(() {
                                              _imageBytes = croppedImage;
                                              _isCropping = false;
                                              // 注意：此时我们直接使用内存中的图像数据
                                              // 实际应用中，您可能需要在这里上传图片到服务器并获取URL
                                              // _imageUrl = "服务器返回的URL";
                                            });
                                          case CropFailure(:final cause):
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text('裁剪失败: $cause'),
                                              ),
                                            );
                                        }
                                      },
                                    ),
                                    Positioned(
                                      bottom: 16,
                                      left: 0,
                                      right: 0,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          ElevatedButton(
                                            onPressed: () {
                                              setState(() {
                                                _isCropping = false;
                                                _imageBytes = null;
                                              });
                                            },
                                            child: const Text('取消'),
                                          ),
                                          const SizedBox(width: 16),
                                          ElevatedButton(
                                            onPressed: _cropController.crop,
                                            child: const Text('确认裁切'),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              )
                              : Container(
                                height: 120,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child:
                                    _imageBytes != null
                                        ? ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                          child: Image.memory(
                                            _imageBytes!,
                                            fit: BoxFit.cover,
                                          ),
                                        )
                                        : _imageUrl != null &&
                                            _imageUrl!.isNotEmpty
                                        ? ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                          child: Image.network(
                                            _imageUrl!,
                                            fit: BoxFit.cover,
                                            errorBuilder: (
                                              context,
                                              error,
                                              stackTrace,
                                            ) {
                                              return const Center(
                                                child: Icon(
                                                  Icons.broken_image,
                                                  size: 48,
                                                  color: Colors.grey,
                                                ),
                                              );
                                            },
                                          ),
                                        )
                                        : const Center(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.add_photo_alternate,
                                                size: 48,
                                                color: Colors.grey,
                                              ),
                                              SizedBox(height: 8),
                                              Text(
                                                '点击选择图片',
                                                style: TextStyle(
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                              ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 标题
                  TextFormField(
                    initialValue: _title,
                    decoration: const InputDecoration(
                      labelText: '标题',
                      hintText: '输入物品名称',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '请输入标题';
                      }
                      return null;
                    },
                    onSaved: (value) => _title = value!,
                  ),
                  const SizedBox(height: 16),
                  // 标签
                  Wrap(
                    spacing: 8,
                    children: [
                      ..._tags
                          .map(
                            (tag) => Chip(
                              label: Text(tag),
                              onDeleted: () {
                                setState(() {
                                  _tags.remove(tag);
                                });
                              },
                            ),
                          )
                          .toList(),
                      ActionChip(
                        label: const Icon(Icons.add, size: 20),
                        onPressed: () async {
                          final tag = await showDialog<String>(
                            context: context,
                            builder: (context) => _AddTagDialog(),
                          );
                          if (tag != null) {
                            setState(() {
                              _tags.add(tag);
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // 价格信息
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // 购入日期
                  ListTile(
                    title: const Text('购入日期'),
                    subtitle: Text(
                      _purchaseDate?.toString().split(' ')[0] ?? '未设置',
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _purchaseDate ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() {
                          _purchaseDate = date;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  // 购入价格
                  TextFormField(
                    initialValue: _purchasePrice?.toString(),
                    decoration: const InputDecoration(
                      labelText: '购入价格',
                      hintText: '输入购入价格',
                    ),
                    keyboardType: TextInputType.number,
                    onSaved: (value) {
                      if (value != null && value.isNotEmpty) {
                        _purchasePrice = double.tryParse(value);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  // 使用记录
                  Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          title: const Text('使用记录'),
                          trailing: IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: _addUsageRecord,
                          ),
                        ),
                        if (_usageRecords.isNotEmpty)
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _usageRecords.length,
                            itemBuilder: (context, index) {
                              final record = _usageRecords[index];
                              return ListTile(
                                title: Text(
                                  record.date.toString().split(' ')[0],
                                ),
                                subtitle: Text(record.note ?? ''),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () => _removeUsageRecord(index),
                                ),
                                onTap: () async {
                                  final date = await showDatePicker(
                                    context: context,
                                    initialDate: record.date,
                                    firstDate: DateTime(2000),
                                    lastDate: DateTime.now(),
                                  );
                                  if (date != null) {
                                    setState(() {
                                      _usageRecords[index] = UsageRecord(
                                        date: date,
                                        note: record.note,
                                      );
                                    });
                                  }
                                },
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // 附加信息
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // 备注
                  TextFormField(
                    initialValue: _notes,
                    decoration: const InputDecoration(
                      labelText: '备注',
                      hintText: '输入备注信息',
                    ),
                    maxLines: 3,
                    onSaved: (value) => _notes = value,
                  ),
                  const SizedBox(height: 16),
                  // 自定义字段
                  Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          title: const Text('自定义字段'),
                          trailing: IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: _addCustomField,
                          ),
                        ),
                        if (_customFields.isNotEmpty)
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _customFields.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        initialValue: _customFields[index].key,
                                        decoration: const InputDecoration(
                                          labelText: '字段名',
                                        ),
                                        onChanged: (value) {
                                          setState(() {
                                            _customFields[index] = CustomField(
                                              key: value,
                                              value: _customFields[index].value,
                                            );
                                          });
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: TextFormField(
                                        initialValue:
                                            _customFields[index].value,
                                        decoration: const InputDecoration(
                                          labelText: '字段值',
                                        ),
                                        onChanged: (value) {
                                          setState(() {
                                            _customFields[index] = CustomField(
                                              key: _customFields[index].key,
                                              value: value,
                                            );
                                          });
                                        },
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete),
                                      onPressed:
                                          () => _removeCustomField(index),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddTagDialog extends StatefulWidget {
  @override
  _AddTagDialogState createState() => _AddTagDialogState();
}

class _AddTagDialogState extends State<_AddTagDialog> {
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('添加标签'),
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(
          labelText: '标签名称',
          hintText: '输入标签名称',
        ),
      ),
      actions: [
        TextButton(
          child: const Text('取消'),
          onPressed: () => Navigator.of(context).pop(),
        ),
        TextButton(
          child: const Text('确定'),
          onPressed: () {
            if (_controller.text.isNotEmpty) {
              Navigator.of(context).pop(_controller.text);
            }
          },
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

import 'package:flutter/material.dart';
import 'package:Memento/widgets/form_fields/image_picker_field.dart';
import 'package:Memento/widgets/form_fields/form_builder_wrapper.dart';
import 'package:Memento/widgets/form_fields/config.dart';
import 'package:Memento/widgets/form_fields/types.dart';

/// 图片选择器示例
///
/// 展示 ImagePickerField 组件的各种用法：
/// - 基础使用
/// - 布局比例 (flex)
/// - 默认图片
/// - FormBuilderWrapper 集成
class ImagePickerExample extends StatefulWidget {
  const ImagePickerExample({super.key});

  @override
  State<ImagePickerExample> createState() => _ImagePickerExampleState();
}

class _ImagePickerExampleState extends State<ImagePickerExample> {
  // 基础用法状态
  String? _basicSelectedImage;

  // 带 flex 比例的示例状态
  String? _flexSelectedImage;

  // 带默认图片的示例状态
  String? _defaultImageSelectedImage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('图片选择器'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题
            Text(
              'ImagePickerField',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            const Text('集成图片选择对话框，提供图片预览功能。'),
            const SizedBox(height: 32),

            // 1. 基础用法
            _buildSectionTitle('1. 基础用法'),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    ImagePickerField(
                      labelText: '封面图片',
                      currentImage: _basicSelectedImage,
                      onImageChanged: (result) {
                        setState(() {
                          _basicSelectedImage = result['url'] as String;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 2. 带布局比例 (flex)
            _buildSectionTitle('2. 带布局比例 (flex)'),
            const SizedBox(height: 16),
            const Text('通过 flex 参数控制图片选择器在行中的占比'),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 图片选择器占比 2
                    Expanded(
                      flex: 2,
                      child: ImagePickerField(
                        labelText: '大图 (flex=2)',
                        currentImage: _flexSelectedImage,
                        previewWidth: double.infinity,
                        previewHeight: 150,
                        borderRadius: 16,
                        showShadow: true,
                        onImageChanged: (result) {
                          setState(() {
                            _flexSelectedImage = result['url'] as String;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    // 文本说明占比 1
                    Expanded(
                      flex: 1,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.image,
                              size: 40,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '右侧说明',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '图片选择器占据 2/3 宽度，说明文字占据 1/3',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 3. 带默认图片
            _buildSectionTitle('3. 带默认图片'),
            const SizedBox(height: 16),
            const Text('使用 defaultImagePath 设置未选择图片时显示的占位图'),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    ImagePickerField(
                      labelText: '头像',
                      currentImage: _defaultImageSelectedImage,
                      previewWidth: 120,
                      previewHeight: 120,
                      borderRadius: 60, // 圆形
                      defaultImagePath: 'assets/images/default_avatar.png',
                      showLabel: true,
                      onImageChanged: (result) {
                        setState(() {
                          _defaultImageSelectedImage = result['url'] as String;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _defaultImageSelectedImage == null
                          ? '未选择头像，显示默认图片'
                          : '已选择自定义头像',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 4. FormBuilderWrapper 集成
            _buildSectionTitle('4. FormBuilderWrapper 集成'),
            const SizedBox(height: 16),
            const Text('在表单中使用图片选择器字段'),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: FormBuilderWrapper(
                  config: FormConfig(
                    fields: [
                      FormFieldConfig(
                        name: 'title',
                        type: FormFieldType.text,
                        labelText: '标题',
                        hintText: '输入内容标题',
                        initialValue: '',
                      ),
                      FormFieldConfig(
                        name: 'cover',
                        type: FormFieldType.imagePicker,
                        labelText: '封面图片',
                        extra: {
                          'flex': 1,
                          'previewWidth': double.infinity,
                          'previewHeight': 180.0,
                          'borderRadius': 12.0,
                          'showShadow': true,
                        },
                      ),
                      FormFieldConfig(
                        name: 'gallery',
                        type: FormFieldType.imagePicker,
                        labelText: '相册图片',
                        hintText: '选择多张图片',
                        extra: {
                          'multiple': true,
                          'previewWidth': 80.0,
                          'previewHeight': 80.0,
                          'borderRadius': 8.0,
                        },
                      ),
                    ],
                    submitButtonText: '提交',
                    showSubmitButton: true,
                    showResetButton: true,
                    onSubmit: (values) {
                      _showSubmitDialog(values);
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }

  void _showSubmitDialog(Map<String, dynamic> values) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('表单提交'),
        content: SingleChildScrollView(
          child: ListBody(
            children: [
              Text('标题: ${values['title'] ?? '(空)'}'),
              const SizedBox(height: 8),
              Text('封面: ${values['cover'] ?? '(未选择)'}'),
              const SizedBox(height: 8),
              Text('相册: ${values['gallery'] ?? '(未选择)'}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }
}

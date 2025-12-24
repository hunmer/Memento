import 'package:flutter/material.dart';
import 'package:Memento/core/services/plugin_data_selector/models/index.dart';
import 'package:Memento/widgets/data_selector_sheet/data_selector_sheet.dart';
import 'package:Memento/widgets/smooth_bottom_sheet.dart';

/// 数据选择器示例
class DataSelectorExample extends StatefulWidget {
  const DataSelectorExample({super.key});

  @override
  State<DataSelectorExample> createState() => _DataSelectorExampleState();
}

class _DataSelectorExampleState extends State<DataSelectorExample> {
  dynamic _selectedResult;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('数据选择器'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader(context, '组件说明'),
          _buildDescription(context),
          const SizedBox(height: 24),
          _buildSectionHeader(context, '功能特性'),
          _buildFeatures(),
          const SizedBox(height: 24),
          _buildSectionHeader(context, '示例演示'),
          _buildDemoButtons(context),
          if (_selectedResult != null) ...[
            const SizedBox(height: 16),
            _buildResultCard(context),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge,
    );
  }

  Widget _buildDescription(BuildContext context) {
    return Text(
      'DataSelectorSheet 是一个支持树形数据结构的多级选择器组件，提供搜索、面包屑导航、网格/列表视图切换等功能。',
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
    );
  }

  Widget _buildFeatures() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFeatureItem('树形数据结构', '支持多级选择，每级可自定义数据加载器'),
        _buildFeatureItem('搜索功能', '本地搜索过滤，支持自定义搜索规则'),
        _buildFeatureItem('面包屑导航', '显示选择路径，支持点击跳转'),
        _buildFeatureItem('多种视图', '列表视图、网格视图、日历视图'),
        _buildFeatureItem('选择模式', '单选/多选，可设置最大选择数量'),
      ],
    );
  }

  Widget _buildFeatureItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 14),
                children: [
                  TextSpan(
                    text: title,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  TextSpan(
                    text: ' - $description',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDemoButtons(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _buildDemoButton(
          context,
          icon: Icons.list,
          label: '单级列表',
          color: Colors.blue,
          onPressed: () => _showSingleLevelSelector(context),
        ),
        _buildDemoButton(
          context,
          icon: Icons.account_tree,
          label: '多级树形',
          color: Colors.green,
          onPressed: () => _showMultiLevelSelector(context),
        ),
        _buildDemoButton(
          context,
          icon: Icons.grid_view,
          label: '网格视图',
          color: Colors.purple,
          onPressed: () => _showGridSelector(context),
        ),
        _buildDemoButton(
          context,
          icon: Icons.checklist,
          label: '多选模式',
          color: Colors.orange,
          onPressed: () => _showMultiSelector(context),
        ),
      ],
    );
  }

  Widget _buildDemoButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildResultCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '选择结果',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _selectedResult.toString(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                  ),
            ),
          ],
        ),
      ),
    );
  }

  /// 单级列表选择器
  Future<void> _showSingleLevelSelector(BuildContext context) async {
    final definition = SelectorDefinition(
      id: 'example.categories',
      pluginId: 'widgets_gallery',
      name: '分类选择',
      icon: Icons.category,
      color: Colors.blue,
      searchable: true,
      steps: [
        SelectorStep(
          id: 'category',
          title: '选择分类',
          viewType: SelectorViewType.list,
          isFinalStep: true,
          dataLoader: (_) async => _getCategories(),
        ),
      ],
    );

    final result = await SmoothBottomSheet.show<SelectorResult>(
      context: context,
      builder: (context) => DataSelectorSheet(
        definition: definition,
        config: const SelectorConfig(
          title: '选择分类',
        ),
      ),
    );

    if (result != null && !result.cancelled) {
      setState(() => _selectedResult = result.data);
    }
  }

  /// 多级树形选择器
  Future<void> _showMultiLevelSelector(BuildContext context) async {
    final definition = SelectorDefinition(
      id: 'example.file_tree',
      pluginId: 'widgets_gallery',
      name: '文件选择',
      icon: Icons.folder,
      color: Colors.green,
      searchable: true,
      steps: [
        SelectorStep(
          id: 'folder',
          title: '选择文件夹',
          viewType: SelectorViewType.list,
          dataLoader: (_) async => _getFolders(),
        ),
        SelectorStep(
          id: 'file',
          title: '选择文件',
          viewType: SelectorViewType.list,
          isFinalStep: true,
          dataLoader: (previous) async {
            final folderId = previous['folder']?['id'];
            return _getFiles(folderId ?? 'documents');
          },
        ),
      ],
    );

    final result = await SmoothBottomSheet.show<SelectorResult>(
      context: context,
      builder: (context) => DataSelectorSheet(
        definition: definition,
        config: const SelectorConfig(
          title: '选择文件',
        ),
      ),
    );

    if (result != null && !result.cancelled) {
      setState(() => _selectedResult = result.data);
    }
  }

  /// 网格视图选择器
  Future<void> _showGridSelector(BuildContext context) async {
    final definition = SelectorDefinition(
      id: 'example.colors',
      pluginId: 'widgets_gallery',
      name: '颜色选择',
      icon: Icons.palette,
      color: Colors.purple,
      searchable: true,
      steps: [
        SelectorStep(
          id: 'color',
          title: '选择颜色',
          viewType: SelectorViewType.grid,
          isFinalStep: true,
          gridCrossAxisCount: 4,
          gridChildAspectRatio: 1.2,
          dataLoader: (_) async => _getColors(),
        ),
      ],
    );

    final result = await SmoothBottomSheet.show<SelectorResult>(
      context: context,
      builder: (context) => DataSelectorSheet(
        definition: definition,
        config: const SelectorConfig(
          title: '选择颜色',
        ),
      ),
    );

    if (result != null && !result.cancelled) {
      setState(() => _selectedResult = result.data);
    }
  }

  /// 多选模式选择器
  Future<void> _showMultiSelector(BuildContext context) async {
    final definition = SelectorDefinition(
      id: 'example.tags',
      pluginId: 'widgets_gallery',
      name: '标签选择',
      icon: Icons.local_offer,
      color: Colors.orange,
      searchable: true,
      selectionMode: SelectionMode.multiple,
      maxSelectionCount: 3,
      steps: [
        SelectorStep(
          id: 'tag',
          title: '选择标签（最多3个）',
          viewType: SelectorViewType.list,
          isFinalStep: true,
          dataLoader: (_) async => _getTags(),
        ),
      ],
    );

    final result = await SmoothBottomSheet.show<SelectorResult>(
      context: context,
      builder: (context) => DataSelectorSheet(
        definition: definition,
        config: const SelectorConfig(
          title: '选择标签',
          confirmText: '确定',
          cancelText: '取消',
        ),
      ),
    );

    if (result != null && !result.cancelled) {
      setState(() => _selectedResult = result.data);
    }
  }

  // 示例数据：分类
  List<SelectableItem> _getCategories() {
    return [
      SelectableItem(
        id: 'tech',
        title: '技术',
        subtitle: '技术相关内容',
        icon: Icons.computer,
        color: Colors.blue,
        rawData: {'id': 'tech', 'name': '技术'},
      ),
      SelectableItem(
        id: 'life',
        title: '生活',
        subtitle: '日常生活记录',
        icon: Icons.home,
        color: Colors.green,
        rawData: {'id': 'life', 'name': '生活'},
      ),
      SelectableItem(
        id: 'work',
        title: '工作',
        subtitle: '工作相关事项',
        icon: Icons.work,
        color: Colors.orange,
        rawData: {'id': 'work', 'name': '工作'},
      ),
      SelectableItem(
        id: 'study',
        title: '学习',
        subtitle: '学习笔记与资料',
        icon: Icons.school,
        color: Colors.purple,
        rawData: {'id': 'study', 'name': '学习'},
      ),
    ];
  }

  // 示例数据：文件夹
  List<SelectableItem> _getFolders() {
    return [
      SelectableItem(
        id: 'documents',
        title: '文档',
        subtitle: '12 个文件',
        icon: Icons.description,
        rawData: {'id': 'documents', 'name': '文档'},
      ),
      SelectableItem(
        id: 'images',
        title: '图片',
        subtitle: '24 个文件',
        icon: Icons.image,
        rawData: {'id': 'images', 'name': '图片'},
      ),
      SelectableItem(
        id: 'downloads',
        title: '下载',
        subtitle: '8 个文件',
        icon: Icons.download,
        rawData: {'id': 'downloads', 'name': '下载'},
      ),
    ];
  }

  // 示例数据：文件
  List<SelectableItem> _getFiles(String folderId) {
    final Map<String, List<SelectableItem>> files = {
      'documents': [
        SelectableItem(
          id: 'doc1',
          title: '项目计划.docx',
          subtitle: '1.2 MB',
          icon: Icons.insert_drive_file,
          color: Colors.blue,
          rawData: {'id': 'doc1', 'name': '项目计划.docx'},
        ),
        SelectableItem(
          id: 'doc2',
          title: '会议记录.txt',
          subtitle: '45 KB',
          icon: Icons.text_snippet,
          color: Colors.grey,
          rawData: {'id': 'doc2', 'name': '会议记录.txt'},
        ),
      ],
      'images': [
        SelectableItem(
          id: 'img1',
          title: '截图001.png',
          subtitle: '2.4 MB',
          icon: Icons.image,
          color: Colors.green,
          rawData: {'id': 'img1', 'name': '截图001.png'},
        ),
        SelectableItem(
          id: 'img2',
          title: '照片002.jpg',
          subtitle: '3.1 MB',
          icon: Icons.photo,
          color: Colors.orange,
          rawData: {'id': 'img2', 'name': '照片002.jpg'},
        ),
      ],
      'downloads': [
        SelectableItem(
          id: 'dwl1',
          title: '安装包.exe',
          subtitle: '128 MB',
          icon: Icons.download,
          color: Colors.purple,
          rawData: {'id': 'dwl1', 'name': '安装包.exe'},
        ),
      ],
    };
    return files[folderId] ?? [];
  }

  // 示例数据：颜色
  List<SelectableItem> _getColors() {
    final colors = [
      {'name': '红色', 'color': Colors.red, 'code': '#F44336'},
      {'name': '粉色', 'color': Colors.pink, 'code': '#E91E63'},
      {'name': '紫色', 'color': Colors.purple, 'code': '#9C27B0'},
      {'name': '蓝色', 'color': Colors.blue, 'code': '#2196F3'},
      {'name': '青色', 'color': Colors.cyan, 'code': '#00BCD4'},
      {'name': '绿色', 'color': Colors.green, 'code': '#4CAF50'},
      {'name': '橙色', 'color': Colors.orange, 'code': '#FF9800'},
      {'name': '黄色', 'color': Colors.yellow, 'code': '#FFEB3B'},
      {'name': '灰色', 'color': Colors.grey, 'code': '#9E9E9E'},
      {'name': '棕色', 'color': Colors.brown, 'code': '#795548'},
      {'name': '靛蓝', 'color': Colors.indigo, 'code': '#3F51B5'},
      {'name': '蓝灰', 'color': Colors.blueGrey, 'code': '#607D8B'},
    ];

    return colors.map((c) {
      return SelectableItem(
        id: c['code'] as String,
        title: c['name'] as String,
        subtitle: c['code'] as String,
        color: c['color'] as Color,
        rawData: c,
      );
    }).toList();
  }

  // 示例数据：标签
  List<SelectableItem> _getTags() {
    return [
      SelectableItem(
        id: 'urgent',
        title: '紧急',
        icon: Icons.priority_high,
        color: Colors.red,
        rawData: {'id': 'urgent', 'name': '紧急'},
      ),
      SelectableItem(
        id: 'important',
        title: '重要',
        icon: Icons.star,
        color: Colors.orange,
        rawData: {'id': 'important', 'name': '重要'},
      ),
      SelectableItem(
        id: 'todo',
        title: '待办',
        icon: Icons.check_circle_outline,
        color: Colors.blue,
        rawData: {'id': 'todo', 'name': '待办'},
      ),
      SelectableItem(
        id: 'in_progress',
        title: '进行中',
        icon: Icons.pending,
        color: Colors.green,
        rawData: {'id': 'in_progress', 'name': '进行中'},
      ),
      SelectableItem(
        id: 'done',
        title: '已完成',
        icon: Icons.check_circle,
        color: Colors.grey,
        rawData: {'id': 'done', 'name': '已完成'},
      ),
      SelectableItem(
        id: 'review',
        title: '待审核',
        icon: Icons.rate_review,
        color: Colors.purple,
        rawData: {'id': 'review', 'name': '待审核'},
      ),
    ];
  }
}

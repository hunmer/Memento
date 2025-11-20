import 'package:flutter/material.dart';
import '../../../services/suggested_questions_service.dart';
import '../../../../../core/storage/storage_manager.dart';

/// 预设问题选择对话框
class SuggestedQuestionsDialog extends StatefulWidget {
  final StorageManager storage;

  const SuggestedQuestionsDialog({
    super.key,
    required this.storage,
  });

  @override
  State<SuggestedQuestionsDialog> createState() =>
      _SuggestedQuestionsDialogState();
}

class _SuggestedQuestionsDialogState extends State<SuggestedQuestionsDialog> {
  // 存储上次选中分类的 key
  static const String _lastCategoryKey = 'agent_chat/suggested_questions_last_category';

  final _service = SuggestedQuestionsService();
  Map<String, List<String>>? _questions;
  String? _selectedCategory;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    try {
      final questions = await _service.getCategorizedQuestions();
      if (mounted) {
        // 尝试读取上次选中的分类
        String? lastCategory;
        try {
          lastCategory = await widget.storage.getString(_lastCategoryKey);
        } catch (e) {
          // 如果读取失败，忽略错误
          lastCategory = null;
        }

        setState(() {
          _questions = questions;
          // 优先使用上次选中的分类（如果存在且有效），否则选中第一个
          if (questions.isNotEmpty) {
            if (lastCategory != null && questions.containsKey(lastCategory)) {
              _selectedCategory = lastCategory;
            } else {
              _selectedCategory = questions.keys.first;
            }
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载问题失败: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// 保存当前选中的分类
  Future<void> _saveSelectedCategory(String category) async {
    try {
      await widget.storage.setString(_lastCategoryKey, category);
    } catch (e) {
      // 保存失败不影响功能，忽略错误
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 标题栏
          _buildHeader(),

          // 分类按钮横向滚动列表
          if (!_isLoading && _questions != null && _questions!.isNotEmpty)
            _buildCategoryTabs(),

          // 内容区域
          Flexible(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _questions == null || _questions!.isEmpty
                    ? _buildEmptyState()
                    : _buildQuestionsList(),
          ),
        ],
      ),
    );
  }

  /// 构建标题栏
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.lightbulb_outline, color: Colors.orange),
          const SizedBox(width: 8),
          const Text(
            '你可以问',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  /// 构建分类标签栏
  Widget _buildCategoryTabs() {
    return Container(
      height: 50,
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: _questions!.length,
        itemBuilder: (context, index) {
          final categoryKey = _questions!.keys.elementAt(index);
          final categoryName = _service.getCategoryName(categoryKey);
          final isSelected = _selectedCategory == categoryKey;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: FilterChip(
              label: Text(categoryName),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedCategory = categoryKey;
                });
                // 保存选中的分类
                _saveSelectedCategory(categoryKey);
              },
              backgroundColor: Colors.white,
              selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
              checkmarkColor: Theme.of(context).primaryColor,
              labelStyle: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Theme.of(context).primaryColor : Colors.grey[700],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          );
        },
      ),
    );
  }

  /// 构建空状态
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              '暂无可用的问题示例',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建问题列表（只显示选中分类的问题）
  Widget _buildQuestionsList() {
    if (_selectedCategory == null) return const SizedBox.shrink();

    final questions = _questions![_selectedCategory] ?? [];

    return ListView.separated(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: questions.length,
      separatorBuilder: (context, index) => Divider(
        color: Colors.grey[200],
        height: 1,
        indent: 16,
        endIndent: 16,
      ),
      itemBuilder: (context, index) => _buildQuestionItem(questions[index]),
    );
  }

  /// 构建单个问题项
  Widget _buildQuestionItem(String question) {
    return InkWell(
      onTap: () => Navigator.pop(context, question),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(question, style: const TextStyle(fontSize: 15)),
            ),
            Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}

/// 显示预设问题对话框
Future<String?> showSuggestedQuestionsDialog(
  BuildContext context,
  StorageManager storage,
) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => SuggestedQuestionsDialog(storage: storage),
  );
}

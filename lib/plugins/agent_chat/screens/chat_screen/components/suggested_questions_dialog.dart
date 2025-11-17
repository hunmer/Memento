import 'package:flutter/material.dart';
import '../../../services/suggested_questions_service.dart';

/// 预设问题选择对话框
class SuggestedQuestionsDialog extends StatefulWidget {
  const SuggestedQuestionsDialog({super.key});

  @override
  State<SuggestedQuestionsDialog> createState() =>
      _SuggestedQuestionsDialogState();
}

class _SuggestedQuestionsDialogState extends State<SuggestedQuestionsDialog> {
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
        setState(() {
          _questions = questions;
          // 默认选中第一个分类
          if (questions.isNotEmpty) {
            _selectedCategory = questions.keys.first;
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

  /// 构建问题列表
  Widget _buildQuestionsList() {
    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(vertical: 8),
      children:
          _questions!.entries.map((entry) {
            return _buildCategorySection(entry.key, entry.value);
          }).toList(),
    );
  }

  /// 构建分类区域
  Widget _buildCategorySection(String categoryKey, List<String> questions) {
    final categoryName = _service.getCategoryName(categoryKey);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 分类标题
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            categoryName,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
        ),

        // 问题列表
        ...questions.map((question) => _buildQuestionItem(question)),

        // 分隔线
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Divider(color: Colors.grey[200], height: 1),
        ),
      ],
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
Future<String?> showSuggestedQuestionsDialog(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => const SuggestedQuestionsDialog(),
  );
}

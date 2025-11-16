import 'dart:convert';
import 'package:flutter/services.dart';

/// 预设问题管理服务
/// 根据工具配置动态生成预设问题示例
class SuggestedQuestionsService {
  /// 问题分类
  static const Map<String, String> _categories = {
    'todo': '📝 待办任务',
    'notes': '📒 笔记管理',
    'tracker': '📊 目标追踪',
    'store': '🛒 积分商店',
    'timer': '⏱️ 计时器',
    'ui': '💬 界面交互',
    'system': '🔧 系统功能',
  };

  /// 获取所有可用工具
  Future<List<String>> getAvailableTools() async {
    try {
      final String indexContent = await rootBundle.loadString(
        'lib/plugins/agent_chat/tools/index.json',
      );
      final List<dynamic> tools = jsonDecode(indexContent);
      return tools.map((e) => e[0].toString()).toList();
    } catch (e) {
      return [];
    }
  }

  /// 获取分类的预设问题
  Future<Map<String, List<String>>> getCategorizedQuestions() async {
    final availableTools = await getAvailableTools();
    final Map<String, List<String>> result = {};

    // 根据可用工具筛选问题
    for (final category in _categories.keys) {
      final questions = _getQuestionsForCategory(category, availableTools);
      if (questions.isNotEmpty) {
        result[category] = questions;
      }
    }

    return result;
  }

  /// 获取指定分类的问题
  List<String> _getQuestionsForCategory(
    String category,
    List<String> availableTools,
  ) {
    final allQuestions = _getAllQuestions();
    final categoryQuestions = allQuestions[category] ?? [];

    // 过滤掉不可用的问题（基于工具是否启用）
    return categoryQuestions.where((q) {
      return _isQuestionAvailable(q, category, availableTools);
    }).toList();
  }

  /// 检查问题是否可用（对应的工具是否存在）
  bool _isQuestionAvailable(
    String question,
    String category,
    List<String> availableTools,
  ) {
    // 检查该分类的任何工具是否可用
    final categoryPrefix = '${category}_';
    return availableTools.any((tool) => tool.startsWith(categoryPrefix));
  }

  /// 获取分类名称
  String getCategoryName(String categoryKey) {
    return _categories[categoryKey] ?? categoryKey;
  }

  /// 预设问题库
  Map<String, List<String>> _getAllQuestions() {
    return {
      'todo': [
        '我今天有哪些待办任务？',
        '帮我创建一个高优先级的任务：完成项目文档',
        '有哪些任务已经过期了？',
        '把任务"写周报"标记为已完成',
        '查看所有进行中的任务',
      ],
      'notes': [
        '帮我创建一个新笔记，标题是"每日总结"',
        '搜索所有包含"项目"关键词的笔记',
        '有哪些带"工作"标签的笔记？',
        '列出我的所有笔记文件夹',
        '创建一个名为"学习笔记"的文件夹',
      ],
      'tracker': [
        '查看我所有的目标',
        '帮我记录今天的运动数据',
        '我的健身目标进度怎么样？',
        '创建一个新目标：每天读书30分钟',
        '查看本周的目标统计',
      ],
      'store': [
        '我现在有多少积分？',
        '商店里有哪些商品可以兑换？',
        '帮我兑换一个商品',
        '查看我的兑换历史',
        '给我添加100积分',
      ],
      'timer': [
        '帮我创建一个25分钟的专注计时器',
        '查看所有计时器',
        '启动"工作"计时器',
        '暂停当前计时器',
        '查看我的计时历史记录',
      ],
      'ui': [
        '显示一个提示：保存成功',
        '弹出一个确认对话框问我是否删除',
        '在顶部显示一个长时间的提示',
      ],
      'system': [
        '你能帮我做什么？',
        '有哪些可用的工具？',
        '如何使用待办任务功能？',
        '系统支持哪些插件？',
      ],
    };
  }

  /// 获取随机推荐问题（跨分类）
  Future<List<String>> getRandomQuestions({int count = 5}) async {
    final categorized = await getCategorizedQuestions();
    final allQuestions = <String>[];

    categorized.forEach((category, questions) {
      allQuestions.addAll(questions);
    });

    allQuestions.shuffle();
    return allQuestions.take(count).toList();
  }
}

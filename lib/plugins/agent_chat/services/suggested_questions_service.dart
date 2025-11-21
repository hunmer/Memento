import 'dart:convert';
import 'package:flutter/services.dart';
import '../../openai/models/ai_agent.dart';
import '../../openai/services/request_service.dart';

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
    'chat': '💬 频道聊天',
    'diary': '📔 日记本',
    'activity': '🎯 活动记录',
    'checkin': '✅ 签到打卡',
    'bill': '💰 账单管理',
    'calendar': '📅 日历事件',
    'calendar_album': '📷 日记相册',
    'contact': '👥 联系人',
    'database': '🗄️ 自定义数据库',
    'day': '🎂 纪念日',
    'goods': '📦 物品管理',
    'habits': '🎯 习惯养成',
    'nodes': '📚 笔记本',
    'ui': '💡 界面交互',
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
        '创建一个紧急任务：明天下午3点前提交报告',
        '删除已完成的任务',
        '我有多少个待办任务？',
      ],
      'notes': [
        '帮我创建一个新笔记，标题是"每日总结"',
        '搜索所有包含"项目"关键词的笔记',
        '有哪些带"工作"标签的笔记？',
        '列出我的所有笔记文件夹',
        '创建一个名为"学习笔记"的文件夹',
        '把笔记移到"工作"文件夹',
        '删除名为"测试"的笔记',
        '重命名文件夹为"重要资料"',
      ],
      'tracker': [
        '查看我所有的目标',
        '帮我记录今天的运动数据',
        '我的健身目标进度怎么样？',
        '创建一个新目标：每天读书30分钟',
        '查看本周的目标统计',
        '删除"减肥"目标',
        '更新我的跑步记录',
        '我今天完成了多少目标？',
      ],
      'store': [
        '我现在有多少积分？',
        '商店里有哪些商品可以兑换？',
        '帮我兑换一个商品',
        '查看我的兑换历史',
        '给我添加100积分',
        '创建一个新商品：迟到券',
        '查看我的积分历史',
        '使用我兑换的物品',
        '归档不再需要的商品',
      ],
      'timer': [
        '帮我创建一个25分钟的专注计时器',
        '查看所有计时器',
        '启动"工作"计时器',
        '暂停当前计时器',
        '查看我的计时历史记录',
        '停止正在运行的计时器',
        '重置计时器',
        '删除不需要的计时器',
      ],
      'chat': [
        '查看所有聊天频道',
        '在"工作"频道发送一条消息',
        '创建一个新频道：项目讨论',
        '删除"测试"频道',
        '获取最近的聊天消息',
        '删除某条消息',
        '显示当前用户信息',
      ],
      'diary': [
        '我今天写了多少字日记？',
        '本月的日记字数统计',
        '本月写日记的进度如何？',
        '加载今天的日记',
        '保存我的日记内容',
        '删除某一天的日记',
        '查看我的日记统计数据',
        '11月15日有日记吗？',
      ],
      'activity': [
        '查看我今天的活动记录',
        '创建一个新活动：跑步30分钟',
        '删除某个活动记录',
        '更新活动的标签',
        '查看今日活动统计',
        '获取所有标签分组',
        '显示最近使用的标签',
        '我今天做了哪些事情？',
      ],
      'checkin': [
        '查看所有签到项目',
        '帮我签到"早起"',
        '查看我的签到历史',
        '获取签到统计数据',
        '创建一个新的签到项目：每日学习',
        '我今天签到了几次？',
        '连续签到了多少天？',
      ],
      'bill': [
        '查看所有账户',
        '创建一个新账户：支付宝',
        '更新账户余额',
        '删除不用的账户',
        '查看本月的账单列表',
        '记录一笔支出：午餐50元',
        '记录一笔收入：工资5000元',
        '删除某条账单记录',
        '查看本月的财务统计',
        '各个分类的支出是多少？',
        '我这个月花了多少钱？',
      ],
      'calendar': [
        '查看所有日历事件',
        '今天有什么安排？',
        '查看本周的事件',
        '创建一个新事件：明天下午2点开会',
        '更新某个事件的时间',
        '删除某个事件',
        '把某个事件标记为已完成',
        '查看所有已完成的事件',
      ],
      'calendar_album': [
        '查看所有日记相册',
        '查看11月15日的照片日记',
        '添加一条新的照片日记',
        '更新某条日记的内容',
        '删除某条照片日记',
        '查看所有标签',
        '查看带"旅行"标签的照片',
        '查看本月的所有照片',
        '获取照片统计信息',
      ],
      'contact': [
        '查看所有联系人',
        '查看某个联系人的详细信息',
        '创建一个新联系人',
        '更新联系人信息',
        '删除某个联系人',
        '记录与某人的交互：今天一起吃饭',
        '查看与某人的交互历史',
        '删除某条交互记录',
        '获取最近联系的人',
        '查看所有联系人标签',
      ],
      'database': [
        '查看所有自定义数据库',
        '创建一个新数据库：书籍清单',
        '更新数据库结构',
        '删除某个数据库',
        '查看数据库中的所有记录',
        '创建一条新记录',
        '更新某条记录',
        '删除某条记录',
        '查询符合条件的记录',
        '统计记录数量',
      ],
      'day': [
        '查看所有纪念日',
        '创建一个纪念日：结婚纪念日',
        '更新纪念日信息',
        '删除某个纪念日',
        '计算距离春节还有多少天',
        '查看即将到来的纪念日',
        '我的生日还有几天？',
      ],
      'goods': [
        '查看所有物品仓库',
        '查看某个仓库的详情',
        '创建一个新仓库：书房',
        '更新仓库信息',
        '删除某个仓库',
        '清空仓库中的所有物品',
        '查看所有物品',
        '查看某个物品的详情',
        '创建一个新物品：MacBook Pro',
        '更新物品信息',
        '删除某个物品',
        '记录物品使用：今天用了笔记本',
        '获取物品统计信息',
      ],
      'habits': [
        '查看所有习惯',
        '查看某个习惯的详情',
        '创建一个新习惯：每天阅读',
        '更新习惯设置',
        '删除某个习惯',
        '查看所有技能',
        '创建一个新技能：编程',
        '更新技能信息',
        '删除某个技能',
        '打卡完成习惯',
        '查看习惯完成记录',
        '删除某条完成记录',
        '获取习惯统计数据',
        '查看今天的习惯清单',
        '开始计时练习',
        '停止计时',
        '查看计时器状态',
      ],
      'nodes': [
        '查看所有笔记本',
        '查看某个笔记本的详情',
        '创建一个新笔记本：工作笔记',
        '更新笔记本信息',
        '删除某个笔记本',
        '查看所有节点',
        '查看某个节点的详情',
        '创建一个新节点',
        '更新节点内容',
        '删除某个节点',
        '移动节点到其他位置',
        '获取笔记本的节点树',
        '获取节点的路径',
      ],
      'ui': [
        '显示一个提示：保存成功',
        '弹出一个确认对话框问我是否删除',
        '在顶部显示一个长时间的提示',
        '显示提示：操作完成',
        '弹出警告对话框',
      ],
      'system': [
        '你能帮我做什么？',
        '有哪些可用的工具？',
        '如何使用待办任务功能？',
        '系统支持哪些插件？',
        '介绍一下你的功能',
        '如何管理我的日记？',
        '怎么创建一个习惯？',
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

  /// 使用 AI 智能生成问题建议
  /// [agent] - AI 助手
  /// [count] - 生成问题数量
  /// 返回 AI 生成的问题列表
  Future<List<String>> generateQuestionsWithAI({
    required AIAgent agent,
    int count = 5,
  }) async {
    try {
      // 构建生成问题的提示词
      final prompt = '''
你是一个智能助手，需要根据以下系统提示词，生成 $count 个用户可能想要请求你帮忙完成的任务。

系统提示词:
${agent.systemPrompt}

要求:
1. 生成的内容必须是【请求式任务】，而不是【提问式问题】
2. 使用"帮我..."、"请帮我..."、"能帮我..."等请求句式
3. 要充分挖掘你的能力范围，展示你能为用户做什么
4. 任务要具体、实用，让用户一看就想点击
5. 每条内容控制在 30 字以内
6. 直接返回任务列表，每行一条，不要添加序号或其他格式
7. 不要返回任何解释说明，只返回任务本身

好的示例:
- 帮我分析今天的工作安排
- 帮我写一封感谢邮件
- 帮我整理会议纪要

坏的示例（不要生成这类）:
- 如何提高工作效率？
- 什么是番茄工作法？
- 你能做什么？

请生成 $count 条请求式任务:''';

      // 使用流式 API 收集完整响应
      final StringBuffer responseBuffer = StringBuffer();
      bool hasError = false;

      await RequestService.streamResponse(
        agent: agent,
        prompt: prompt,
        onToken: (token) {
          responseBuffer.write(token);
        },
        onError: (error) {
          hasError = true;
        },
        onComplete: () {},
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          hasError = true;
        },
      );

      if (hasError) {
        // 如果出错,降级到预设问题
        return await getRandomQuestions(count: count);
      }

      // 解析 AI 返回的问题列表
      final response = responseBuffer.toString();
      final questions = response
          .split('\n')
          .map((q) => q.trim())
          .where((q) => q.isNotEmpty && !q.startsWith('//') && !q.startsWith('#'))
          .take(count)
          .toList();

      return questions.isNotEmpty ? questions : await getRandomQuestions(count: count);
    } catch (e) {
      // 如果 AI 生成失败,降级到预设问题
      return await getRandomQuestions(count: count);
    }
  }
}

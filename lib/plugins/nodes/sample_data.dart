import 'package:flutter/material.dart';
import 'models/notebook.dart';
import 'models/node.dart';

// 节点插件的示例数据
// 当插件的 JSON 文件不存在时，自动加载这些示例数据
class NodesSampleData {
  // 获取示例笔记本列表
  static List<Notebook> getSampleNotebooks() {
    return [
      _createWorkNotebook(),
      _createLifeNotebook(),
      _createLearningNotebook(),
    ];
  }

  // 创建"工作项目"笔记本
  static Notebook _createWorkNotebook() {
    final notebookId = 'work-notebook-001';

    // 创建根节点
    final projectANode = Node(
      id: 'node-project-a',
      title: '项目A - Memento 应用开发',
      createdAt: DateTime(2025, 1, 1, 9, 0),
      tags: ['重要', '开发'],
      status: NodeStatus.doing,
      startDate: DateTime(2025, 1, 1),
      endDate: DateTime(2025, 3, 31),
      customFields: [
        CustomField(key: '优先级', value: '高'),
        CustomField(key: '负责人', value: '张三'),
        CustomField(key: '预算', value: '50万'),
      ],
      notes: '开发一个跨平台的个人助手应用，支持多种功能插件',
      parentId: '',
      pathValue: '项目A - Memento 应用开发',
      color: Colors.blue,
      isExpanded: true,
    );

    // 创建项目A的子节点
    final task1 = Node(
      id: 'node-task-1',
      title: '核心架构设计',
      createdAt: DateTime(2025, 1, 2, 10, 0),
      tags: ['架构', '重要'],
      status: NodeStatus.done,
      customFields: [
        CustomField(key: '预计工期', value: '2周'),
        CustomField(key: '完成度', value: '100%'),
      ],
      notes: '完成插件化架构设计，确定数据存储方案',
      parentId: 'node-project-a',
      pathValue: '项目A - Memento 应用开发/核心架构设计',
      color: Colors.green,
    );

    final task2 = Node(
      id: 'node-task-2',
      title: 'UI 界面开发',
      createdAt: DateTime(2025, 1, 15, 9, 0),
      tags: ['UI', '开发'],
      status: NodeStatus.doing,
      startDate: DateTime(2025, 1, 15),
      endDate: DateTime(2025, 2, 15),
      customFields: [
        CustomField(key: '预计工期', value: '4周'),
        CustomField(key: '完成度', value: '60%'),
      ],
      notes: '实现主界面、设置页面、各插件界面',
      parentId: 'node-project-a',
      pathValue: '项目A - Memento 应用开发/UI 界面开发',
      color: Colors.orange,
      isExpanded: true,
    );

    // 任务2的子任务
    final subtask1 = Node(
      id: 'node-subtask-1',
      title: '主屏幕设计',
      createdAt: DateTime(2025, 1, 16, 9, 0),
      tags: ['UI', '主屏幕'],
      status: NodeStatus.done,
      customFields: [
        CustomField(key: '预计工期', value: '1周'),
      ],
      notes: '设计并实现插件网格布局',
      parentId: 'node-task-2',
      pathValue: '项目A - Memento 应用开发/UI 界面开发/主屏幕设计',
      color: Colors.green,
    );

    final subtask2 = Node(
      id: 'node-subtask-2',
      title: '设置页面',
      createdAt: DateTime(2025, 1, 23, 9, 0),
      tags: ['UI', '设置'],
      status: NodeStatus.doing,
      customFields: [
        CustomField(key: '预计工期', value: '1周'),
        CustomField(key: '完成度', value: '80%'),
      ],
      notes: '实现 WebDAV 同步、主题设置等功能',
      parentId: 'node-task-2',
      pathValue: '项目A - Memento 应用开发/UI 界面开发/设置页面',
      color: Colors.orange,
    );

    task2.children.addAll([subtask1, subtask2]);

    final task3 = Node(
      id: 'node-task-3',
      title: '功能插件开发',
      createdAt: DateTime(2025, 2, 1, 9, 0),
      tags: ['插件', '开发'],
      status: NodeStatus.todo,
      startDate: DateTime(2025, 2, 16),
      endDate: DateTime(2025, 3, 15),
      customFields: [
        CustomField(key: '预计工期', value: '4周'),
        CustomField(key: '插件数量', value: '8个'),
      ],
      notes: '开发日记、记账、待办等核心功能插件',
      parentId: 'node-project-a',
      pathValue: '项目A - Memento 应用开发/功能插件开发',
      color: Colors.grey,
    );

    projectANode.children.addAll([task1, task2, task3]);

    // 创建第二个项目
    final projectBNode = Node(
      id: 'node-project-b',
      title: '项目B - 内部管理系统',
      createdAt: DateTime(2025, 2, 1, 9, 0),
      tags: ['管理', '内部'],
      status: NodeStatus.todo,
      startDate: DateTime(2025, 4, 1),
      endDate: DateTime(2025, 6, 30),
      customFields: [
        CustomField(key: '优先级', value: '中'),
        CustomField(key: '负责人', value: '李四'),
      ],
      notes: '为公司内部开发管理系统',
      parentId: '',
      pathValue: '项目B - 内部管理系统',
      color: Colors.purple,
    );

    // 创建笔记本
    return Notebook(
      id: notebookId,
      title: '💼 工作项目',
      icon: Icons.work,
      color: const Color(0xFF2196F3),
      nodes: [projectANode, projectBNode],
    );
  }

  // 创建"生活记录"笔记本
  static Notebook _createLifeNotebook() {
    final notebookId = 'life-notebook-001';

    final healthNode = Node(
      id: 'node-health',
      title: '健康管理',
      createdAt: DateTime(2025, 1, 1, 8, 0),
      tags: ['健康', '重要'],
      status: NodeStatus.doing,
      customFields: [
        CustomField(key: '目标体重', value: '70kg'),
        CustomField(key: '当前体重', value: '75kg'),
      ],
      notes: '保持健康的生活方式',
      parentId: '',
      pathValue: '健康管理',
      color: Colors.green,
      isExpanded: true,
    );

    final exerciseNode = Node(
      id: 'node-exercise',
      title: '运动计划',
      createdAt: DateTime(2025, 1, 2, 7, 0),
      tags: ['运动', '日常'],
      status: NodeStatus.doing,
      startDate: DateTime(2025, 1, 1),
      endDate: DateTime(2025, 12, 31),
      customFields: [
        CustomField(key: '频次', value: '每周3次'),
        CustomField(key: '运动类型', value: '跑步、健身'),
      ],
      notes: '每周至少运动3次，每次30分钟以上',
      parentId: 'node-health',
      pathValue: '健康管理/运动计划',
      color: Colors.orange,
    );

    final dietNode = Node(
      id: 'node-diet',
      title: '饮食计划',
      createdAt: DateTime(2025, 1, 2, 8, 0),
      tags: ['饮食', '健康'],
      status: NodeStatus.doing,
      customFields: [
        CustomField(key: '早餐', value: '燕麦粥+鸡蛋'),
        CustomField(key: '午餐', value: '蔬菜沙拉+瘦肉'),
        CustomField(key: '晚餐', value: '清蒸鱼+蔬菜'),
      ],
      notes: '控制热量摄入，营养均衡',
      parentId: 'node-health',
      pathValue: '健康管理/饮食计划',
      color: Colors.teal,
    );

    healthNode.children.addAll([exerciseNode, dietNode]);

    final financeNode = Node(
      id: 'node-finance',
      title: '理财规划',
      createdAt: DateTime(2025, 1, 5, 10, 0),
      tags: ['理财', '重要'],
      status: NodeStatus.todo,
      customFields: [
        CustomField(key: '月收入', value: '15000元'),
        CustomField(key: '月支出', value: '8000元'),
        CustomField(key: '储蓄目标', value: '5000元/月'),
      ],
      notes: '合理规划收入支出，增加储蓄和投资',
      parentId: '',
      pathValue: '理财规划',
      color: Colors.amber,
    );

    final travelNode = Node(
      id: 'node-travel',
      title: '旅行计划',
      createdAt: DateTime(2025, 1, 10, 14, 0),
      tags: ['旅行', '兴趣'],
      status: NodeStatus.todo,
      startDate: DateTime(2025, 7, 1),
      endDate: DateTime(2025, 7, 10),
      customFields: [
        CustomField(key: '目的地', value: '日本'),
        CustomField(key: '预算', value: '15000元'),
        CustomField(key: '天数', value: '10天'),
      ],
      notes: '计划去日本旅行，体验当地文化',
      parentId: '',
      pathValue: '旅行计划',
      color: Colors.pink,
    );

    return Notebook(
      id: notebookId,
      title: '🏠 生活记录',
      icon: Icons.home,
      color: const Color(0xFF4CAF50),
      nodes: [healthNode, financeNode, travelNode],
    );
  }

  // 创建"学习成长"笔记本
  static Notebook _createLearningNotebook() {
    final notebookId = 'learning-notebook-001';

    final flutterNode = Node(
      id: 'node-flutter',
      title: 'Flutter 开发进阶',
      createdAt: DateTime(2025, 1, 1, 20, 0),
      tags: ['Flutter', '开发', '重要'],
      status: NodeStatus.doing,
      startDate: DateTime(2025, 1, 1),
      endDate: DateTime(2025, 6, 30),
      customFields: [
        CustomField(key: '学习时长', value: '2小时/天'),
        CustomField(key: '目标', value: '掌握Flutter高级开发'),
      ],
      notes: '系统学习Flutter框架，深入理解其原理',
      parentId: '',
      pathValue: 'Flutter 开发进阶',
      color: Colors.blue,
      isExpanded: true,
    );

    final widgetNode = Node(
      id: 'node-widget',
      title: 'Widget 组件',
      createdAt: DateTime(2025, 1, 15, 20, 0),
      tags: ['Widget', 'UI'],
      status: NodeStatus.doing,
      customFields: [
        CustomField(key: '完成度', value: '70%'),
        CustomField(key: '重点', value: '自定义Widget'),
      ],
      notes: '学习Flutter Widget系统，理解渲染原理',
      parentId: 'node-flutter',
      pathValue: 'Flutter 开发进阶/Widget 组件',
      color: Colors.orange,
      isExpanded: true,
    );

    final layoutWidgetNode = Node(
      id: 'node-layout',
      title: '布局组件',
      createdAt: DateTime(2025, 1, 16, 20, 0),
      tags: ['布局', 'Widget'],
      status: NodeStatus.done,
      customFields: [
        CustomField(key: '完成度', value: '100%'),
      ],
      notes: '掌握Row、Column、Stack等布局组件',
      parentId: 'node-widget',
      pathValue: 'Flutter 开发进阶/Widget 组件/布局组件',
      color: Colors.green,
    );

    final stateNode = Node(
      id: 'node-state',
      title: '状态管理',
      createdAt: DateTime(2025, 1, 20, 20, 0),
      tags: ['状态管理', '重要'],
      status: NodeStatus.todo,
      customFields: [
        CustomField(key: '预计工期', value: '2周'),
      ],
      notes: '学习Provider、Bloc、Riverpod等状态管理方案',
      parentId: 'node-widget',
      pathValue: 'Flutter 开发进阶/Widget 组件/状态管理',
      color: Colors.grey,
    );

    widgetNode.children.addAll([layoutWidgetNode, stateNode]);

    final englishNode = Node(
      id: 'node-english',
      title: '英语提升',
      createdAt: DateTime(2025, 1, 1, 7, 0),
      tags: ['英语', '语言'],
      status: NodeStatus.doing,
      startDate: DateTime(2025, 1, 1),
      endDate: DateTime(2025, 12, 31),
      customFields: [
        CustomField(key: '目标', value: '雅思7分'),
        CustomField(key: '当前水平', value: '雅思6分'),
      ],
      notes: '提高英语听说读写能力',
      parentId: '',
      pathValue: '英语提升',
      color: Colors.indigo,
    );

    final readingNode = Node(
      id: 'node-reading',
      title: '阅读计划',
      createdAt: DateTime(2025, 1, 5, 21, 0),
      tags: ['阅读', '习惯'],
      status: NodeStatus.todo,
      customFields: [
        CustomField(key: '目标', value: '每月4本书'),
        CustomField(key: '类型', value: '技术、文学、历史'),
      ],
      notes: '培养阅读习惯，扩展知识面',
      parentId: '',
      pathValue: '阅读计划',
      color: Colors.deepOrange,
    );

    return Notebook(
      id: notebookId,
      title: '📚 学习成长',
      icon: Icons.school,
      color: const Color(0xFF9C27B0),
      nodes: [flutterNode, englishNode, readingNode],
    );
  }
}

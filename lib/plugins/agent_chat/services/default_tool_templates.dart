import '../models/saved_tool_template.dart';
import '../models/tool_call_step.dart';

/// 默认工具模板库
///
/// 为所有预设问题提供完整的工具模板，包含可执行的 JavaScript 代码
class DefaultToolTemplates {
  /// 获取所有默认模板
  static List<SavedToolTemplate> getAll() {
    return [
      // ==================== 待办任务 ====================
      ..._todoTemplates,

      // ==================== 笔记管理 ====================
      ..._notesTemplates,

      // ==================== 目标追踪 ====================
      ..._trackerTemplates,

      // ==================== 积分商店 ====================
      ..._storeTemplates,

      // ==================== 计时器 ====================
      ..._timerTemplates,

      // ==================== 频道聊天 ====================
      ..._chatTemplates,

      // ==================== 日记本 ====================
      ..._diaryTemplates,

      // ==================== 活动记录 ====================
      ..._activityTemplates,

      // ==================== 签到打卡 ====================
      ..._checkinTemplates,

      // ==================== 账单管理 ====================
      ..._billTemplates,

      // ==================== 日历事件 ====================
      ..._calendarTemplates,

      // ==================== 日记相册 ====================
      ..._calendarAlbumTemplates,

      // ==================== 联系人 ====================
      ..._contactTemplates,

      // ==================== 自定义数据库 ====================
      ..._databaseTemplates,

      // ==================== 纪念日 ====================
      ..._dayTemplates,

      // ==================== 物品管理 ====================
      ..._goodsTemplates,

      // ==================== 习惯养成 ====================
      ..._habitsTemplates,

      // ==================== 笔记本 ====================
      ..._nodesTemplates,
    ];
  }

  // ==================== 待办任务模板 ====================
  static final List<SavedToolTemplate> _todoTemplates = [
    SavedToolTemplate(
      id: 'default-todo-today',
      name: '查看今日待办',
      description: '获取今天需要完成的所有待办任务',
      steps: [
        ToolCallStep(
          method: 'run_js',
          title: '获取今日待办任务',
          desc: '查询今天到期的所有待办任务',
          data: '''
const today = new Date();
today.setHours(0, 0, 0, 0);
const tomorrow = new Date(today);
tomorrow.setDate(tomorrow.getDate() + 1);

const tasks = await Memento.plugins.todo.getTasks({
  status: 'todo'
});

// 过滤今天到期的任务
const todayTasks = tasks.filter(task => {
  if (!task.dueDate) return false;
  const dueDate = new Date(task.dueDate);
  return dueDate >= today && dueDate < tomorrow;
});

return {
  count: todayTasks.length,
  tasks: todayTasks.map(t => ({
    id: t.id,
    title: t.title,
    priority: t.priority,
    dueDate: t.dueDate
  }))
};
''',
        ),
      ],
      createdAt: DateTime(2025, 1, 1),
      tags: ['todo', '待办', '今日'],
      declaredTools: [
        {'id': 'todo_getTasks', 'name': '获取任务列表'}
      ],
    ),
    SavedToolTemplate(
      id: 'default-todo-create-high',
      name: '创建高优先级任务',
      description: '创建一个高优先级的待办任务',
      steps: [
        ToolCallStep(
          method: 'run_js',
          title: '创建高优先级任务',
          desc: '创建一个紧急重要的任务',
          data: '''
const task = await Memento.plugins.todo.createTask({
  title: '完成项目文档',
  priority: 'high',
  status: 'todo'
});

return {
  success: true,
  task: {
    id: task.id,
    title: task.title,
    priority: task.priority
  }
};
''',
        ),
      ],
      createdAt: DateTime(2025, 1, 1),
      tags: ['todo', '创建', '高优先级'],
      declaredTools: [
        {'id': 'todo_createTask', 'name': '创建任务'}
      ],
    ),
    SavedToolTemplate(
      id: 'default-todo-overdue',
      name: '查看过期任务',
      description: '获取所有已过期但未完成的任务',
      steps: [
        ToolCallStep(
          method: 'run_js',
          title: '获取过期任务',
          desc: '查询所有已过期的待办任务',
          data: '''
const now = new Date();
const tasks = await Memento.plugins.todo.getTasks({
  status: 'todo'
});

const overdueTasks = tasks.filter(task => {
  if (!task.dueDate) return false;
  return new Date(task.dueDate) < now;
});

return {
  count: overdueTasks.length,
  tasks: overdueTasks.map(t => ({
    id: t.id,
    title: t.title,
    priority: t.priority,
    dueDate: t.dueDate,
    daysOverdue: Math.floor((now - new Date(t.dueDate)) / (1000 * 60 * 60 * 24))
  }))
};
''',
        ),
      ],
      createdAt: DateTime(2025, 1, 1),
      tags: ['todo', '过期', '查询'],
      declaredTools: [
        {'id': 'todo_getTasks', 'name': '获取任务列表'}
      ],
    ),
    SavedToolTemplate(
      id: 'default-todo-complete',
      name: '完成指定任务',
      description: '将指定的任务标记为已完成',
      steps: [
        ToolCallStep(
          method: 'run_js',
          title: '完成任务',
          desc: '标记任务为已完成状态',
          data: '''
// 先获取任务列表
const tasks = await Memento.plugins.todo.getTasks({
  status: 'todo'
});

// 查找包含"周报"的任务
const task = tasks.find(t => t.title.includes('周报'));

if (!task) {
  return { success: false, message: '未找到包含"周报"的任务' };
}

// 更新任务状态
await Memento.plugins.todo.updateTask(task.id, {
  status: 'done'
});

return {
  success: true,
  message: '任务已完成',
  task: {
    id: task.id,
    title: task.title
  }
};
''',
        ),
      ],
      createdAt: DateTime(2025, 1, 1),
      tags: ['todo', '完成', '更新'],
      declaredTools: [
        {'id': 'todo_getTasks', 'name': '获取任务列表'},
        {'id': 'todo_updateTask', 'name': '更新任务'}
      ],
    ),
    SavedToolTemplate(
      id: 'default-todo-in-progress',
      name: '查看进行中任务',
      description: '获取所有正在进行中的任务',
      steps: [
        ToolCallStep(
          method: 'run_js',
          title: '获取进行中任务',
          desc: '查询所有状态为进行中的任务',
          data: '''
const tasks = await Memento.plugins.todo.getTasks({
  status: 'doing'
});

return {
  count: tasks.length,
  tasks: tasks.map(t => ({
    id: t.id,
    title: t.title,
    priority: t.priority,
    dueDate: t.dueDate
  }))
};
''',
        ),
      ],
      createdAt: DateTime(2025, 1, 1),
      tags: ['todo', '进行中', '查询'],
      declaredTools: [
        {'id': 'todo_getTasks', 'name': '获取任务列表'}
      ],
    ),
    SavedToolTemplate(
      id: 'default-todo-count',
      name: '统计待办任务数量',
      description: '统计各状态的任务数量',
      steps: [
        ToolCallStep(
          method: 'run_js',
          title: '统计任务数量',
          desc: '分别统计待办、进行中、已完成的任务数',
          data: '''
const todoTasks = await Memento.plugins.todo.getTasks({ status: 'todo' });
const doingTasks = await Memento.plugins.todo.getTasks({ status: 'doing' });
const doneTasks = await Memento.plugins.todo.getTasks({ status: 'done' });

return {
  todo: todoTasks.length,
  doing: doingTasks.length,
  done: doneTasks.length,
  total: todoTasks.length + doingTasks.length + doneTasks.length
};
''',
        ),
      ],
      createdAt: DateTime(2025, 1, 1),
      tags: ['todo', '统计', '数量'],
      declaredTools: [
        {'id': 'todo_getTasks', 'name': '获取任务列表'}
      ],
    ),
  ];

  // ==================== 笔记管理模板 ====================
  static final List<SavedToolTemplate> _notesTemplates = [
    SavedToolTemplate(
      id: 'default-notes-create',
      name: '创建新笔记',
      description: '创建一个新的笔记',
      steps: [
        ToolCallStep(
          method: 'run_js',
          title: '创建笔记',
          desc: '创建一个标题为"每日总结"的笔记',
          data: '''
const note = await Memento.plugins.notes.createNote({
  title: '每日总结',
  content: '## 今日完成\\n\\n## 明日计划\\n\\n## 遇到的问题\\n',
  tags: ['日总结']
});

return {
  success: true,
  note: {
    id: note.id,
    title: note.title
  }
};
''',
        ),
      ],
      createdAt: DateTime(2025, 1, 1),
      tags: ['notes', '创建', '笔记'],
      declaredTools: [
        {'id': 'notes_createNote', 'name': '创建笔记'}
      ],
    ),
    SavedToolTemplate(
      id: 'default-notes-search',
      name: '搜索笔记',
      description: '搜索包含指定关键词的笔记',
      steps: [
        ToolCallStep(
          method: 'run_js',
          title: '搜索笔记',
          desc: '搜索包含"项目"关键词的笔记',
          data: '''
const notes = await Memento.plugins.notes.searchNotes({
  query: '项目'
});

return {
  count: notes.length,
  notes: notes.map(n => ({
    id: n.id,
    title: n.title,
    updatedAt: n.updatedAt
  }))
};
''',
        ),
      ],
      createdAt: DateTime(2025, 1, 1),
      tags: ['notes', '搜索', '查询'],
      declaredTools: [
        {'id': 'notes_searchNotes', 'name': '搜索笔记'}
      ],
    ),
    SavedToolTemplate(
      id: 'default-notes-by-tag',
      name: '按标签查找笔记',
      description: '获取带有指定标签的所有笔记',
      steps: [
        ToolCallStep(
          method: 'run_js',
          title: '按标签查找',
          desc: '查找带"工作"标签的笔记',
          data: '''
const notes = await Memento.plugins.notes.getNotesByTag({
  tag: '工作'
});

return {
  count: notes.length,
  notes: notes.map(n => ({
    id: n.id,
    title: n.title,
    tags: n.tags
  }))
};
''',
        ),
      ],
      createdAt: DateTime(2025, 1, 1),
      tags: ['notes', '标签', '查询'],
      declaredTools: [
        {'id': 'notes_getNotesByTag', 'name': '按标签获取笔记'}
      ],
    ),
    SavedToolTemplate(
      id: 'default-notes-folders',
      name: '获取笔记文件夹',
      description: '列出所有笔记文件夹',
      steps: [
        ToolCallStep(
          method: 'run_js',
          title: '获取文件夹列表',
          desc: '列出所有笔记文件夹',
          data: '''
const folders = await Memento.plugins.notes.getFolders();

return {
  count: folders.length,
  folders: folders.map(f => ({
    id: f.id,
    name: f.name,
    noteCount: f.noteCount || 0
  }))
};
''',
        ),
      ],
      createdAt: DateTime(2025, 1, 1),
      tags: ['notes', '文件夹', '列表'],
      declaredTools: [
        {'id': 'notes_getFolders', 'name': '获取文件夹列表'}
      ],
    ),
    SavedToolTemplate(
      id: 'default-notes-create-folder',
      name: '创建笔记文件夹',
      description: '创建一个新的笔记文件夹',
      steps: [
        ToolCallStep(
          method: 'run_js',
          title: '创建文件夹',
          desc: '创建名为"学习笔记"的文件夹',
          data: '''
const folder = await Memento.plugins.notes.createFolder({
  name: '学习笔记'
});

return {
  success: true,
  folder: {
    id: folder.id,
    name: folder.name
  }
};
''',
        ),
      ],
      createdAt: DateTime(2025, 1, 1),
      tags: ['notes', '文件夹', '创建'],
      declaredTools: [
        {'id': 'notes_createFolder', 'name': '创建文件夹'}
      ],
    ),
  ];

  // ==================== 目标追踪模板 ====================
  static final List<SavedToolTemplate> _trackerTemplates = [
    SavedToolTemplate(
      id: 'default-tracker-all',
      name: '查看所有目标',
      description: '获取所有追踪目标及其进度',
      steps: [
        ToolCallStep(
          method: 'run_js',
          title: '获取目标列表',
          desc: '查询所有追踪目标',
          data: '''
const goals = await Memento.plugins.tracker.getGoals();

return {
  count: goals.length,
  goals: goals.map(g => ({
    id: g.id,
    name: g.name,
    target: g.target,
    current: g.current,
    unit: g.unit,
    progress: g.target > 0 ? Math.round((g.current / g.target) * 100) : 0
  }))
};
''',
        ),
      ],
      createdAt: DateTime(2025, 1, 1),
      tags: ['tracker', '目标', '查询'],
      declaredTools: [
        {'id': 'tracker_getGoals', 'name': '获取目标列表'}
      ],
    ),
    SavedToolTemplate(
      id: 'default-tracker-record',
      name: '记录数据',
      description: '记录今天的目标数据',
      steps: [
        ToolCallStep(
          method: 'run_js',
          title: '记录运动数据',
          desc: '记录今天的运动数据',
          data: '''
// 先获取目标
const goals = await Memento.plugins.tracker.getGoals();
const exerciseGoal = goals.find(g => g.name.includes('运动') || g.name.includes('健身'));

if (!exerciseGoal) {
  return { success: false, message: '未找到运动相关目标' };
}

// 记录数据
const record = await Memento.plugins.tracker.addRecord({
  goalId: exerciseGoal.id,
  value: 30,
  note: '今日运动完成'
});

return {
  success: true,
  record: {
    goalName: exerciseGoal.name,
    value: record.value,
    date: record.date
  }
};
''',
        ),
      ],
      createdAt: DateTime(2025, 1, 1),
      tags: ['tracker', '记录', '数据'],
      declaredTools: [
        {'id': 'tracker_getGoals', 'name': '获取目标列表'},
        {'id': 'tracker_addRecord', 'name': '添加记录'}
      ],
    ),
    SavedToolTemplate(
      id: 'default-tracker-create',
      name: '创建新目标',
      description: '创建一个新的追踪目标',
      steps: [
        ToolCallStep(
          method: 'run_js',
          title: '创建目标',
          desc: '创建每天阅读30分钟的目标',
          data: '''
const goal = await Memento.plugins.tracker.createGoal({
  name: '每天读书30分钟',
  target: 30,
  unit: '分钟',
  frequency: 'daily'
});

return {
  success: true,
  goal: {
    id: goal.id,
    name: goal.name,
    target: goal.target,
    unit: goal.unit
  }
};
''',
        ),
      ],
      createdAt: DateTime(2025, 1, 1),
      tags: ['tracker', '创建', '目标'],
      declaredTools: [
        {'id': 'tracker_createGoal', 'name': '创建目标'}
      ],
    ),
    SavedToolTemplate(
      id: 'default-tracker-stats',
      name: '查看目标统计',
      description: '查看本周的目标完成统计',
      steps: [
        ToolCallStep(
          method: 'run_js',
          title: '获取统计数据',
          desc: '统计本周目标完成情况',
          data: '''
const goals = await Memento.plugins.tracker.getGoals();
const now = new Date();
const weekStart = new Date(now);
weekStart.setDate(now.getDate() - now.getDay());
weekStart.setHours(0, 0, 0, 0);

const stats = [];
for (const goal of goals) {
  const records = await Memento.plugins.tracker.getRecords({
    goalId: goal.id,
    startDate: weekStart.toISOString()
  });

  const total = records.reduce((sum, r) => sum + r.value, 0);
  stats.push({
    name: goal.name,
    weeklyTotal: total,
    target: goal.target * 7,
    completion: goal.target > 0 ? Math.round((total / (goal.target * 7)) * 100) : 0
  });
}

return { weekStats: stats };
''',
        ),
      ],
      createdAt: DateTime(2025, 1, 1),
      tags: ['tracker', '统计', '本周'],
      declaredTools: [
        {'id': 'tracker_getGoals', 'name': '获取目标列表'},
        {'id': 'tracker_getRecords', 'name': '获取记录'}
      ],
    ),
  ];

  // ==================== 积分商店模板 ====================
  static final List<SavedToolTemplate> _storeTemplates = [
    SavedToolTemplate(
      id: 'default-store-balance',
      name: '查看积分余额',
      description: '获取当前的积分余额',
      steps: [
        ToolCallStep(
          method: 'run_js',
          title: '获取积分余额',
          desc: '查询当前积分余额',
          data: '''
const balance = await Memento.plugins.store.getBalance();

return {
  balance: balance,
  message: '当前积分余额: ' + balance + ' 分'
};
''',
        ),
      ],
      createdAt: DateTime(2025, 1, 1),
      tags: ['store', '积分', '余额'],
      declaredTools: [
        {'id': 'store_getBalance', 'name': '获取积分余额'}
      ],
    ),
    SavedToolTemplate(
      id: 'default-store-products',
      name: '查看商品列表',
      description: '获取商店中可兑换的商品',
      steps: [
        ToolCallStep(
          method: 'run_js',
          title: '获取商品列表',
          desc: '查询可兑换的商品',
          data: '''
const products = await Memento.plugins.store.getProducts();

return {
  count: products.length,
  products: products.map(p => ({
    id: p.id,
    name: p.name,
    price: p.price,
    stock: p.stock
  }))
};
''',
        ),
      ],
      createdAt: DateTime(2025, 1, 1),
      tags: ['store', '商品', '列表'],
      declaredTools: [
        {'id': 'store_getProducts', 'name': '获取商品列表'}
      ],
    ),
    SavedToolTemplate(
      id: 'default-store-add-points',
      name: '添加积分',
      description: '给账户添加积分',
      steps: [
        ToolCallStep(
          method: 'run_js',
          title: '添加积分',
          desc: '添加100积分',
          data: '''
await Memento.plugins.store.addPoints({
  amount: 100,
  reason: '完成任务奖励'
});

const newBalance = await Memento.plugins.store.getBalance();

return {
  success: true,
  added: 100,
  newBalance: newBalance
};
''',
        ),
      ],
      createdAt: DateTime(2025, 1, 1),
      tags: ['store', '积分', '添加'],
      declaredTools: [
        {'id': 'store_addPoints', 'name': '添加积分'},
        {'id': 'store_getBalance', 'name': '获取积分余额'}
      ],
    ),
    SavedToolTemplate(
      id: 'default-store-history',
      name: '查看兑换历史',
      description: '获取积分兑换历史记录',
      steps: [
        ToolCallStep(
          method: 'run_js',
          title: '获取兑换历史',
          desc: '查询兑换记录',
          data: '''
const history = await Memento.plugins.store.getExchangeHistory();

return {
  count: history.length,
  history: history.map(h => ({
    productName: h.productName,
    price: h.price,
    date: h.date
  }))
};
''',
        ),
      ],
      createdAt: DateTime(2025, 1, 1),
      tags: ['store', '历史', '兑换'],
      declaredTools: [
        {'id': 'store_getExchangeHistory', 'name': '获取兑换历史'}
      ],
    ),
  ];

  // ==================== 计时器模板 ====================
  static final List<SavedToolTemplate> _timerTemplates = [
    SavedToolTemplate(
      id: 'default-timer-create-pomodoro',
      name: '创建番茄计时器',
      description: '创建一个25分钟的专注计时器',
      steps: [
        ToolCallStep(
          method: 'run_js',
          title: '创建计时器',
          desc: '创建25分钟番茄计时器',
          data: '''
const timer = await Memento.plugins.timer.createTimer({
  name: '专注工作',
  duration: 25 * 60,
  type: 'countdown'
});

return {
  success: true,
  timer: {
    id: timer.id,
    name: timer.name,
    duration: '25分钟'
  }
};
''',
        ),
      ],
      createdAt: DateTime(2025, 1, 1),
      tags: ['timer', '创建', '番茄'],
      declaredTools: [
        {'id': 'timer_createTimer', 'name': '创建计时器'}
      ],
    ),
    SavedToolTemplate(
      id: 'default-timer-list',
      name: '查看所有计时器',
      description: '获取所有计时器列表',
      steps: [
        ToolCallStep(
          method: 'run_js',
          title: '获取计时器列表',
          desc: '查询所有计时器',
          data: '''
const timers = await Memento.plugins.timer.getTimers();

return {
  count: timers.length,
  timers: timers.map(t => ({
    id: t.id,
    name: t.name,
    duration: Math.floor(t.duration / 60) + '分钟',
    status: t.status
  }))
};
''',
        ),
      ],
      createdAt: DateTime(2025, 1, 1),
      tags: ['timer', '列表', '查询'],
      declaredTools: [
        {'id': 'timer_getTimers', 'name': '获取计时器列表'}
      ],
    ),
    SavedToolTemplate(
      id: 'default-timer-start',
      name: '启动计时器',
      description: '启动指定的计时器',
      steps: [
        ToolCallStep(
          method: 'run_js',
          title: '启动计时器',
          desc: '启动"工作"计时器',
          data: '''
const timers = await Memento.plugins.timer.getTimers();
const workTimer = timers.find(t => t.name.includes('工作'));

if (!workTimer) {
  return { success: false, message: '未找到"工作"计时器' };
}

await Memento.plugins.timer.startTimer({ id: workTimer.id });

return {
  success: true,
  message: '计时器已启动',
  timer: {
    id: workTimer.id,
    name: workTimer.name
  }
};
''',
        ),
      ],
      createdAt: DateTime(2025, 1, 1),
      tags: ['timer', '启动', '控制'],
      declaredTools: [
        {'id': 'timer_getTimers', 'name': '获取计时器列表'},
        {'id': 'timer_startTimer', 'name': '启动计时器'}
      ],
    ),
    SavedToolTemplate(
      id: 'default-timer-history',
      name: '查看计时历史',
      description: '获取计时器使用历史记录',
      steps: [
        ToolCallStep(
          method: 'run_js',
          title: '获取计时历史',
          desc: '查询计时历史记录',
          data: '''
const history = await Memento.plugins.timer.getHistory();

return {
  count: history.length,
  history: history.slice(0, 10).map(h => ({
    timerName: h.timerName,
    duration: Math.floor(h.duration / 60) + '分钟',
    date: h.date
  }))
};
''',
        ),
      ],
      createdAt: DateTime(2025, 1, 1),
      tags: ['timer', '历史', '记录'],
      declaredTools: [
        {'id': 'timer_getHistory', 'name': '获取计时历史'}
      ],
    ),
  ];

  // ==================== 频道聊天模板 ====================
  static final List<SavedToolTemplate> _chatTemplates = [
    SavedToolTemplate(
      id: 'default-chat-channels',
      name: '查看聊天频道',
      description: '获取所有聊天频道列表',
      steps: [
        ToolCallStep(
          method: 'run_js',
          title: '获取频道列表',
          desc: '查询所有聊天频道',
          data: '''
const channels = await Memento.plugins.chat.getChannels();

return {
  count: channels.length,
  channels: channels.map(c => ({
    id: c.id,
    name: c.name,
    messageCount: c.messageCount || 0
  }))
};
''',
        ),
      ],
      createdAt: DateTime(2025, 1, 1),
      tags: ['chat', '频道', '列表'],
      declaredTools: [
        {'id': 'chat_getChannels', 'name': '获取频道列表'}
      ],
    ),
    SavedToolTemplate(
      id: 'default-chat-send',
      name: '发送消息',
      description: '在指定频道发送消息',
      steps: [
        ToolCallStep(
          method: 'run_js',
          title: '发送消息',
          desc: '在"工作"频道发送消息',
          data: '''
const channels = await Memento.plugins.chat.getChannels();
const workChannel = channels.find(c => c.name.includes('工作'));

if (!workChannel) {
  return { success: false, message: '未找到"工作"频道' };
}

const message = await Memento.plugins.chat.sendMessage({
  channelId: workChannel.id,
  content: '这是一条测试消息'
});

return {
  success: true,
  message: {
    id: message.id,
    channelName: workChannel.name,
    content: message.content
  }
};
''',
        ),
      ],
      createdAt: DateTime(2025, 1, 1),
      tags: ['chat', '发送', '消息'],
      declaredTools: [
        {'id': 'chat_getChannels', 'name': '获取频道列表'},
        {'id': 'chat_sendMessage', 'name': '发送消息'}
      ],
    ),
    SavedToolTemplate(
      id: 'default-chat-create-channel',
      name: '创建频道',
      description: '创建一个新的聊天频道',
      steps: [
        ToolCallStep(
          method: 'run_js',
          title: '创建频道',
          desc: '创建名为"项目讨论"的频道',
          data: '''
const channel = await Memento.plugins.chat.createChannel({
  name: '项目讨论'
});

return {
  success: true,
  channel: {
    id: channel.id,
    name: channel.name
  }
};
''',
        ),
      ],
      createdAt: DateTime(2025, 1, 1),
      tags: ['chat', '创建', '频道'],
      declaredTools: [
        {'id': 'chat_createChannel', 'name': '创建频道'}
      ],
    ),
  ];

  // ==================== 日记本模板 ====================
  static final List<SavedToolTemplate> _diaryTemplates = [
    SavedToolTemplate(
      id: 'default-diary-today',
      name: '加载今日日记',
      description: '获取今天的日记内容',
      steps: [
        ToolCallStep(
          method: 'run_js',
          title: '加载今日日记',
          desc: '获取今天的日记',
          data: '''
const today = new Date().toISOString().split('T')[0];
const entry = await Memento.plugins.diary.getEntry({ date: today });

if (!entry) {
  return { exists: false, message: '今天还没有写日记' };
}

return {
  exists: true,
  entry: {
    date: entry.date,
    content: entry.content,
    wordCount: entry.content ? entry.content.length : 0
  }
};
''',
        ),
      ],
      createdAt: DateTime(2025, 1, 1),
      tags: ['diary', '今日', '日记'],
      declaredTools: [
        {'id': 'diary_getEntry', 'name': '获取日记'}
      ],
    ),
    SavedToolTemplate(
      id: 'default-diary-stats',
      name: '日记统计',
      description: '获取日记写作统计数据',
      steps: [
        ToolCallStep(
          method: 'run_js',
          title: '获取统计数据',
          desc: '查询日记统计信息',
          data: '''
const stats = await Memento.plugins.diary.getStats();

return {
  totalEntries: stats.totalEntries,
  totalWords: stats.totalWords,
  currentStreak: stats.currentStreak,
  longestStreak: stats.longestStreak
};
''',
        ),
      ],
      createdAt: DateTime(2025, 1, 1),
      tags: ['diary', '统计', '数据'],
      declaredTools: [
        {'id': 'diary_getStats', 'name': '获取统计'}
      ],
    ),
    SavedToolTemplate(
      id: 'default-diary-month',
      name: '本月日记统计',
      description: '统计本月的日记字数',
      steps: [
        ToolCallStep(
          method: 'run_js',
          title: '本月统计',
          desc: '统计本月日记字数',
          data: '''
const now = new Date();
const year = now.getFullYear();
const month = now.getMonth() + 1;

const entries = await Memento.plugins.diary.getMonthEntries({
  year: year,
  month: month
});

const totalWords = entries.reduce((sum, e) => {
  return sum + (e.content ? e.content.length : 0);
}, 0);

return {
  year: year,
  month: month,
  entryCount: entries.length,
  totalWords: totalWords,
  avgWords: entries.length > 0 ? Math.round(totalWords / entries.length) : 0
};
''',
        ),
      ],
      createdAt: DateTime(2025, 1, 1),
      tags: ['diary', '本月', '统计'],
      declaredTools: [
        {'id': 'diary_getMonthEntries', 'name': '获取月份日记'}
      ],
    ),
    SavedToolTemplate(
      id: 'default-diary-save',
      name: '保存日记',
      description: '保存今天的日记内容',
      steps: [
        ToolCallStep(
          method: 'run_js',
          title: '保存日记',
          desc: '保存日记内容',
          data: '''
const today = new Date().toISOString().split('T')[0];

await Memento.plugins.diary.saveEntry({
  date: today,
  content: '今天是充实的一天。\\n\\n完成了很多工作，感觉很有成就感。'
});

return {
  success: true,
  date: today,
  message: '日记已保存'
};
''',
        ),
      ],
      createdAt: DateTime(2025, 1, 1),
      tags: ['diary', '保存', '日记'],
      declaredTools: [
        {'id': 'diary_saveEntry', 'name': '保存日记'}
      ],
    ),
  ];

  // ==================== 活动记录模板 ====================
  static final List<SavedToolTemplate> _activityTemplates = [
    SavedToolTemplate(
      id: 'default-activity-today',
      name: '查看今日活动',
      description: '获取今天的活动记录',
      steps: [
        ToolCallStep(
          method: 'run_js',
          title: '获取今日活动',
          desc: '查询今天的活动记录',
          data: '''
const today = new Date();
today.setHours(0, 0, 0, 0);

const activities = await Memento.plugins.activity.getActivities({
  startDate: today.toISOString()
});

return {
  count: activities.length,
  activities: activities.map(a => ({
    id: a.id,
    name: a.name,
    tags: a.tags,
    duration: a.duration,
    createdAt: a.createdAt
  }))
};
''',
        ),
      ],
      createdAt: DateTime(2025, 1, 1),
      tags: ['activity', '今日', '活动'],
      declaredTools: [
        {'id': 'activity_getActivities', 'name': '获取活动列表'}
      ],
    ),
    SavedToolTemplate(
      id: 'default-activity-create',
      name: '创建活动记录',
      description: '创建一个新的活动记录',
      steps: [
        ToolCallStep(
          method: 'run_js',
          title: '创建活动',
          desc: '记录跑步30分钟',
          data: '''
const activity = await Memento.plugins.activity.createActivity({
  name: '跑步',
  duration: 30,
  tags: ['运动', '健身']
});

return {
  success: true,
  activity: {
    id: activity.id,
    name: activity.name,
    duration: activity.duration + '分钟',
    tags: activity.tags
  }
};
''',
        ),
      ],
      createdAt: DateTime(2025, 1, 1),
      tags: ['activity', '创建', '记录'],
      declaredTools: [
        {'id': 'activity_createActivity', 'name': '创建活动'}
      ],
    ),
    SavedToolTemplate(
      id: 'default-activity-stats',
      name: '活动统计',
      description: '查看今日活动统计数据',
      steps: [
        ToolCallStep(
          method: 'run_js',
          title: '获取统计数据',
          desc: '统计今日活动',
          data: '''
const stats = await Memento.plugins.activity.getTodayStats();

return {
  totalActivities: stats.totalActivities,
  totalDuration: stats.totalDuration + '分钟',
  tagBreakdown: stats.tagBreakdown
};
''',
        ),
      ],
      createdAt: DateTime(2025, 1, 1),
      tags: ['activity', '统计', '今日'],
      declaredTools: [
        {'id': 'activity_getTodayStats', 'name': '获取今日统计'}
      ],
    ),
    SavedToolTemplate(
      id: 'default-activity-tags',
      name: '获取活动标签',
      description: '获取所有活动标签分组',
      steps: [
        ToolCallStep(
          method: 'run_js',
          title: '获取标签分组',
          desc: '查询所有标签分组',
          data: '''
const tagGroups = await Memento.plugins.activity.getTagGroups();

return {
  groups: tagGroups.map(g => ({
    name: g.name,
    tags: g.tags,
    color: g.color
  }))
};
''',
        ),
      ],
      createdAt: DateTime(2025, 1, 1),
      tags: ['activity', '标签', '分组'],
      declaredTools: [
        {'id': 'activity_getTagGroups', 'name': '获取标签分组'}
      ],
    ),
  ];

  // ==================== 签到打卡模板 ====================
  static final List<SavedToolTemplate> _checkinTemplates = [
    SavedToolTemplate(
      id: 'default-checkin-items',
      name: '查看签到项目',
      description: '获取所有签到项目列表',
      steps: [
        ToolCallStep(
          method: 'run_js',
          title: '获取签到项目',
          desc: '查询所有签到项目',
          data: '''
const items = await Memento.plugins.checkin.getItems();

return {
  count: items.length,
  items: items.map(i => ({
    id: i.id,
    name: i.name,
    streak: i.streak,
    lastCheckin: i.lastCheckin
  }))
};
''',
        ),
      ],
      createdAt: DateTime(2025, 1, 1),
      tags: ['checkin', '项目', '列表'],
      declaredTools: [
        {'id': 'checkin_getItems', 'name': '获取签到项目'}
      ],
    ),
    SavedToolTemplate(
      id: 'default-checkin-do',
      name: '执行签到',
      description: '对指定项目执行签到',
      steps: [
        ToolCallStep(
          method: 'run_js',
          title: '执行签到',
          desc: '签到"早起"项目',
          data: '''
const items = await Memento.plugins.checkin.getItems();
const item = items.find(i => i.name.includes('早起'));

if (!item) {
  return { success: false, message: '未找到"早起"签到项目' };
}

await Memento.plugins.checkin.checkin({ itemId: item.id });

return {
  success: true,
  item: {
    name: item.name,
    newStreak: item.streak + 1
  }
};
''',
        ),
      ],
      createdAt: DateTime(2025, 1, 1),
      tags: ['checkin', '签到', '打卡'],
      declaredTools: [
        {'id': 'checkin_getItems', 'name': '获取签到项目'},
        {'id': 'checkin_checkin', 'name': '执行签到'}
      ],
    ),
    SavedToolTemplate(
      id: 'default-checkin-stats',
      name: '签到统计',
      description: '获取签到统计数据',
      steps: [
        ToolCallStep(
          method: 'run_js',
          title: '获取统计数据',
          desc: '查询签到统计',
          data: '''
const stats = await Memento.plugins.checkin.getStats();

return {
  todayCount: stats.todayCount,
  totalCheckins: stats.totalCheckins,
  longestStreak: stats.longestStreak
};
''',
        ),
      ],
      createdAt: DateTime(2025, 1, 1),
      tags: ['checkin', '统计', '数据'],
      declaredTools: [
        {'id': 'checkin_getStats', 'name': '获取签到统计'}
      ],
    ),
    SavedToolTemplate(
      id: 'default-checkin-create',
      name: '创建签到项目',
      description: '创建新的签到项目',
      steps: [
        ToolCallStep(
          method: 'run_js',
          title: '创建项目',
          desc: '创建"每日学习"签到项目',
          data: '''
const item = await Memento.plugins.checkin.createItem({
  name: '每日学习',
  description: '每天学习新知识'
});

return {
  success: true,
  item: {
    id: item.id,
    name: item.name
  }
};
''',
        ),
      ],
      createdAt: DateTime(2025, 1, 1),
      tags: ['checkin', '创建', '项目'],
      declaredTools: [
        {'id': 'checkin_createItem', 'name': '创建签到项目'}
      ],
    ),
  ];

  // ==================== 账单管理模板 ====================
  static final List<SavedToolTemplate> _billTemplates = [
    SavedToolTemplate(
      id: 'default-bill-accounts',
      name: '查看所有账户',
      description: '获取所有账户列表及余额',
      steps: [
        ToolCallStep(
          method: 'run_js',
          title: '获取账户列表',
          desc: '查询所有账户',
          data: '''
const accounts = await Memento.plugins.bill.getAccounts();

return {
  count: accounts.length,
  accounts: accounts.map(a => ({
    id: a.id,
    name: a.name,
    balance: a.balance,
    type: a.type
  }))
};
''',
        ),
      ],
      createdAt: DateTime(2025, 1, 1),
      tags: ['bill', '账户', '列表'],
      declaredTools: [
        {'id': 'bill_getAccounts', 'name': '获取账户列表'}
      ],
    ),
    SavedToolTemplate(
      id: 'default-bill-expense',
      name: '记录支出',
      description: '记录一笔支出',
      steps: [
        ToolCallStep(
          method: 'run_js',
          title: '记录支出',
          desc: '记录午餐50元支出',
          data: '''
const accounts = await Memento.plugins.bill.getAccounts();
const defaultAccount = accounts[0];

if (!defaultAccount) {
  return { success: false, message: '没有可用账户' };
}

const bill = await Memento.plugins.bill.createBill({
  accountId: defaultAccount.id,
  type: 'expense',
  amount: 50,
  category: '餐饮',
  note: '午餐'
});

return {
  success: true,
  bill: {
    id: bill.id,
    amount: bill.amount,
    category: bill.category,
    note: bill.note
  }
};
''',
        ),
      ],
      createdAt: DateTime(2025, 1, 1),
      tags: ['bill', '支出', '记录'],
      declaredTools: [
        {'id': 'bill_getAccounts', 'name': '获取账户列表'},
        {'id': 'bill_createBill', 'name': '创建账单'}
      ],
    ),
    SavedToolTemplate(
      id: 'default-bill-income',
      name: '记录收入',
      description: '记录一笔收入',
      steps: [
        ToolCallStep(
          method: 'run_js',
          title: '记录收入',
          desc: '记录工资5000元收入',
          data: '''
const accounts = await Memento.plugins.bill.getAccounts();
const defaultAccount = accounts[0];

if (!defaultAccount) {
  return { success: false, message: '没有可用账户' };
}

const bill = await Memento.plugins.bill.createBill({
  accountId: defaultAccount.id,
  type: 'income',
  amount: 5000,
  category: '工资',
  note: '月工资'
});

return {
  success: true,
  bill: {
    id: bill.id,
    amount: bill.amount,
    category: bill.category
  }
};
''',
        ),
      ],
      createdAt: DateTime(2025, 1, 1),
      tags: ['bill', '收入', '记录'],
      declaredTools: [
        {'id': 'bill_getAccounts', 'name': '获取账户列表'},
        {'id': 'bill_createBill', 'name': '创建账单'}
      ],
    ),
    SavedToolTemplate(
      id: 'default-bill-month-stats',
      name: '本月财务统计',
      description: '查看本月的收支统计',
      steps: [
        ToolCallStep(
          method: 'run_js',
          title: '获取统计数据',
          desc: '统计本月收支',
          data: '''
const now = new Date();
const stats = await Memento.plugins.bill.getMonthStats({
  year: now.getFullYear(),
  month: now.getMonth() + 1
});

return {
  income: stats.income,
  expense: stats.expense,
  balance: stats.income - stats.expense,
  categoryBreakdown: stats.categoryBreakdown
};
''',
        ),
      ],
      createdAt: DateTime(2025, 1, 1),
      tags: ['bill', '统计', '本月'],
      declaredTools: [
        {'id': 'bill_getMonthStats', 'name': '获取月统计'}
      ],
    ),
    SavedToolTemplate(
      id: 'default-bill-create-account',
      name: '创建账户',
      description: '创建一个新账户',
      steps: [
        ToolCallStep(
          method: 'run_js',
          title: '创建账户',
          desc: '创建"支付宝"账户',
          data: '''
const account = await Memento.plugins.bill.createAccount({
  name: '支付宝',
  type: 'digital',
  balance: 0
});

return {
  success: true,
  account: {
    id: account.id,
    name: account.name,
    type: account.type
  }
};
''',
        ),
      ],
      createdAt: DateTime(2025, 1, 1),
      tags: ['bill', '账户', '创建'],
      declaredTools: [
        {'id': 'bill_createAccount', 'name': '创建账户'}
      ],
    ),
  ];

  // ==================== 日历事件模板 ====================
  static final List<SavedToolTemplate> _calendarTemplates = [
    SavedToolTemplate(
      id: 'default-calendar-today',
      name: '查看今日安排',
      description: '获取今天的日历事件',
      steps: [
        ToolCallStep(
          method: 'run_js',
          title: '获取今日事件',
          desc: '查询今天的安排',
          data: '''
const today = new Date();
today.setHours(0, 0, 0, 0);
const tomorrow = new Date(today);
tomorrow.setDate(tomorrow.getDate() + 1);

const events = await Memento.plugins.calendar.getEvents({
  startDate: today.toISOString(),
  endDate: tomorrow.toISOString()
});

return {
  count: events.length,
  events: events.map(e => ({
    id: e.id,
    title: e.title,
    startTime: e.startTime,
    endTime: e.endTime
  }))
};
''',
        ),
      ],
      createdAt: DateTime(2025, 1, 1),
      tags: ['calendar', '今日', '安排'],
      declaredTools: [
        {'id': 'calendar_getEvents', 'name': '获取事件列表'}
      ],
    ),
    SavedToolTemplate(
      id: 'default-calendar-week',
      name: '查看本周事件',
      description: '获取本周的日历事件',
      steps: [
        ToolCallStep(
          method: 'run_js',
          title: '获取本周事件',
          desc: '查询本周的安排',
          data: '''
const now = new Date();
const weekStart = new Date(now);
weekStart.setDate(now.getDate() - now.getDay());
weekStart.setHours(0, 0, 0, 0);

const weekEnd = new Date(weekStart);
weekEnd.setDate(weekStart.getDate() + 7);

const events = await Memento.plugins.calendar.getEvents({
  startDate: weekStart.toISOString(),
  endDate: weekEnd.toISOString()
});

return {
  count: events.length,
  events: events.map(e => ({
    id: e.id,
    title: e.title,
    date: e.startTime
  }))
};
''',
        ),
      ],
      createdAt: DateTime(2025, 1, 1),
      tags: ['calendar', '本周', '事件'],
      declaredTools: [
        {'id': 'calendar_getEvents', 'name': '获取事件列表'}
      ],
    ),
    SavedToolTemplate(
      id: 'default-calendar-create',
      name: '创建日历事件',
      description: '创建一个新的日历事件',
      steps: [
        ToolCallStep(
          method: 'run_js',
          title: '创建事件',
          desc: '创建明天下午2点的会议',
          data: '''
const tomorrow = new Date();
tomorrow.setDate(tomorrow.getDate() + 1);
tomorrow.setHours(14, 0, 0, 0);

const endTime = new Date(tomorrow);
endTime.setHours(15, 0, 0, 0);

const event = await Memento.plugins.calendar.createEvent({
  title: '项目会议',
  startTime: tomorrow.toISOString(),
  endTime: endTime.toISOString()
});

return {
  success: true,
  event: {
    id: event.id,
    title: event.title,
    startTime: event.startTime
  }
};
''',
        ),
      ],
      createdAt: DateTime(2025, 1, 1),
      tags: ['calendar', '创建', '事件'],
      declaredTools: [
        {'id': 'calendar_createEvent', 'name': '创建事件'}
      ],
    ),
  ];

  // ==================== 日记相册模板 ====================
  static final List<SavedToolTemplate> _calendarAlbumTemplates = [
    SavedToolTemplate(
      id: 'default-album-today',
      name: '查看今日照片',
      description: '获取今天的照片日记',
      steps: [
        ToolCallStep(
          method: 'run_js',
          title: '获取今日照片',
          desc: '查询今天的照片日记',
          data: '''
const today = new Date().toISOString().split('T')[0];
const photos = await Memento.plugins.calendarAlbum.getPhotos({
  date: today
});

return {
  count: photos.length,
  photos: photos.map(p => ({
    id: p.id,
    caption: p.caption,
    tags: p.tags
  }))
};
''',
        ),
      ],
      createdAt: DateTime(2025, 1, 1),
      tags: ['album', '今日', '照片'],
      declaredTools: [
        {'id': 'calendarAlbum_getPhotos', 'name': '获取照片'}
      ],
    ),
    SavedToolTemplate(
      id: 'default-album-tags',
      name: '查看相册标签',
      description: '获取所有照片标签',
      steps: [
        ToolCallStep(
          method: 'run_js',
          title: '获取标签列表',
          desc: '查询所有标签',
          data: '''
const tags = await Memento.plugins.calendarAlbum.getTags();

return {
  count: tags.length,
  tags: tags
};
''',
        ),
      ],
      createdAt: DateTime(2025, 1, 1),
      tags: ['album', '标签', '列表'],
      declaredTools: [
        {'id': 'calendarAlbum_getTags', 'name': '获取标签'}
      ],
    ),
    SavedToolTemplate(
      id: 'default-album-stats',
      name: '相册统计',
      description: '获取相册统计信息',
      steps: [
        ToolCallStep(
          method: 'run_js',
          title: '获取统计数据',
          desc: '查询相册统计',
          data: '''
const stats = await Memento.plugins.calendarAlbum.getStats();

return {
  totalPhotos: stats.totalPhotos,
  totalDays: stats.totalDays,
  tagCount: stats.tagCount
};
''',
        ),
      ],
      createdAt: DateTime(2025, 1, 1),
      tags: ['album', '统计', '数据'],
      declaredTools: [
        {'id': 'calendarAlbum_getStats', 'name': '获取统计'}
      ],
    ),
  ];

  // ==================== 联系人模板 ====================
  static final List<SavedToolTemplate> _contactTemplates = [
    SavedToolTemplate(
      id: 'default-contact-all',
      name: '查看所有联系人',
      description: '获取所有联系人列表',
      steps: [
        ToolCallStep(
          method: 'run_js',
          title: '获取联系人列表',
          desc: '查询所有联系人',
          data: '''
const contacts = await Memento.plugins.contact.getContacts();

return {
  count: contacts.length,
  contacts: contacts.map(c => ({
    id: c.id,
    name: c.name,
    phone: c.phone,
    email: c.email
  }))
};
''',
        ),
      ],
      createdAt: DateTime(2025, 1, 1),
      tags: ['contact', '联系人', '列表'],
      declaredTools: [
        {'id': 'contact_getContacts', 'name': '获取联系人列表'}
      ],
    ),
    SavedToolTemplate(
      id: 'default-contact-create',
      name: '创建联系人',
      description: '创建一个新的联系人',
      steps: [
        ToolCallStep(
          method: 'run_js',
          title: '创建联系人',
          desc: '添加新联系人',
          data: '''
const contact = await Memento.plugins.contact.createContact({
  name: '张三',
  phone: '13800138000',
  email: 'zhangsan@example.com'
});

return {
  success: true,
  contact: {
    id: contact.id,
    name: contact.name
  }
};
''',
        ),
      ],
      createdAt: DateTime(2025, 1, 1),
      tags: ['contact', '创建', '联系人'],
      declaredTools: [
        {'id': 'contact_createContact', 'name': '创建联系人'}
      ],
    ),
    SavedToolTemplate(
      id: 'default-contact-interaction',
      name: '记录交互',
      description: '记录与联系人的交互',
      steps: [
        ToolCallStep(
          method: 'run_js',
          title: '记录交互',
          desc: '记录今天一起吃饭',
          data: '''
const contacts = await Memento.plugins.contact.getContacts();
const contact = contacts[0];

if (!contact) {
  return { success: false, message: '没有联系人' };
}

const interaction = await Memento.plugins.contact.addInteraction({
  contactId: contact.id,
  type: '聚餐',
  note: '今天一起吃饭'
});

return {
  success: true,
  interaction: {
    contactName: contact.name,
    type: interaction.type,
    date: interaction.date
  }
};
''',
        ),
      ],
      createdAt: DateTime(2025, 1, 1),
      tags: ['contact', '交互', '记录'],
      declaredTools: [
        {'id': 'contact_getContacts', 'name': '获取联系人列表'},
        {'id': 'contact_addInteraction', 'name': '添加交互记录'}
      ],
    ),
    SavedToolTemplate(
      id: 'default-contact-recent',
      name: '最近联系',
      description: '获取最近联系的人',
      steps: [
        ToolCallStep(
          method: 'run_js',
          title: '获取最近联系',
          desc: '查询最近联系的人',
          data: '''
const recent = await Memento.plugins.contact.getRecentContacts({
  limit: 10
});

return {
  count: recent.length,
  contacts: recent.map(c => ({
    name: c.name,
    lastInteraction: c.lastInteraction
  }))
};
''',
        ),
      ],
      createdAt: DateTime(2025, 1, 1),
      tags: ['contact', '最近', '联系'],
      declaredTools: [
        {'id': 'contact_getRecentContacts', 'name': '获取最近联系'}
      ],
    ),
  ];

  // ==================== 自定义数据库模板 ====================
  static final List<SavedToolTemplate> _databaseTemplates = [
    SavedToolTemplate(
      id: 'default-database-all',
      name: '查看所有数据库',
      description: '获取所有自定义数据库列表',
      steps: [
        ToolCallStep(
          method: 'run_js',
          title: '获取数据库列表',
          desc: '查询所有数据库',
          data: '''
const databases = await Memento.plugins.database.getDatabases();

return {
  count: databases.length,
  databases: databases.map(db => ({
    id: db.id,
    name: db.name,
    recordCount: db.recordCount
  }))
};
''',
        ),
      ],
      createdAt: DateTime(2025, 1, 1),
      tags: ['database', '数据库', '列表'],
      declaredTools: [
        {'id': 'database_getDatabases', 'name': '获取数据库列表'}
      ],
    ),
    SavedToolTemplate(
      id: 'default-database-create',
      name: '创建数据库',
      description: '创建一个新的自定义数据库',
      steps: [
        ToolCallStep(
          method: 'run_js',
          title: '创建数据库',
          desc: '创建"书籍清单"数据库',
          data: '''
const database = await Memento.plugins.database.createDatabase({
  name: '书籍清单',
  fields: [
    { name: '书名', type: 'text', required: true },
    { name: '作者', type: 'text' },
    { name: '评分', type: 'number' },
    { name: '已读', type: 'boolean' }
  ]
});

return {
  success: true,
  database: {
    id: database.id,
    name: database.name
  }
};
''',
        ),
      ],
      createdAt: DateTime(2025, 1, 1),
      tags: ['database', '创建', '数据库'],
      declaredTools: [
        {'id': 'database_createDatabase', 'name': '创建数据库'}
      ],
    ),
    SavedToolTemplate(
      id: 'default-database-query',
      name: '查询记录',
      description: '查询数据库中的记录',
      steps: [
        ToolCallStep(
          method: 'run_js',
          title: '查询记录',
          desc: '查询符合条件的记录',
          data: '''
const databases = await Memento.plugins.database.getDatabases();
const db = databases[0];

if (!db) {
  return { success: false, message: '没有数据库' };
}

const records = await Memento.plugins.database.getRecords({
  databaseId: db.id
});

return {
  databaseName: db.name,
  count: records.length,
  records: records.slice(0, 10)
};
''',
        ),
      ],
      createdAt: DateTime(2025, 1, 1),
      tags: ['database', '查询', '记录'],
      declaredTools: [
        {'id': 'database_getDatabases', 'name': '获取数据库列表'},
        {'id': 'database_getRecords', 'name': '获取记录'}
      ],
    ),
  ];

  // ==================== 纪念日模板 ====================
  static final List<SavedToolTemplate> _dayTemplates = [
    SavedToolTemplate(
      id: 'default-day-all',
      name: '查看所有纪念日',
      description: '获取所有纪念日列表',
      steps: [
        ToolCallStep(
          method: 'run_js',
          title: '获取纪念日列表',
          desc: '查询所有纪念日',
          data: '''
const days = await Memento.plugins.day.getDays();

return {
  count: days.length,
  days: days.map(d => ({
    id: d.id,
    name: d.name,
    date: d.date,
    type: d.type
  }))
};
''',
        ),
      ],
      createdAt: DateTime(2025, 1, 1),
      tags: ['day', '纪念日', '列表'],
      declaredTools: [
        {'id': 'day_getDays', 'name': '获取纪念日列表'}
      ],
    ),
    SavedToolTemplate(
      id: 'default-day-upcoming',
      name: '即将到来的纪念日',
      description: '查看即将到来的纪念日',
      steps: [
        ToolCallStep(
          method: 'run_js',
          title: '获取即将到来',
          desc: '查询即将到来的纪念日',
          data: '''
const upcoming = await Memento.plugins.day.getUpcoming({
  days: 30
});

return {
  count: upcoming.length,
  days: upcoming.map(d => ({
    name: d.name,
    date: d.date,
    daysUntil: d.daysUntil
  }))
};
''',
        ),
      ],
      createdAt: DateTime(2025, 1, 1),
      tags: ['day', '即将', '纪念日'],
      declaredTools: [
        {'id': 'day_getUpcoming', 'name': '获取即将到来'}
      ],
    ),
    SavedToolTemplate(
      id: 'default-day-create',
      name: '创建纪念日',
      description: '创建一个新的纪念日',
      steps: [
        ToolCallStep(
          method: 'run_js',
          title: '创建纪念日',
          desc: '创建结婚纪念日',
          data: '''
const day = await Memento.plugins.day.createDay({
  name: '结婚纪念日',
  date: '2020-01-01',
  type: 'anniversary',
  repeat: 'yearly'
});

return {
  success: true,
  day: {
    id: day.id,
    name: day.name,
    date: day.date
  }
};
''',
        ),
      ],
      createdAt: DateTime(2025, 1, 1),
      tags: ['day', '创建', '纪念日'],
      declaredTools: [
        {'id': 'day_createDay', 'name': '创建纪念日'}
      ],
    ),
  ];

  // ==================== 物品管理模板 ====================
  static final List<SavedToolTemplate> _goodsTemplates = [
    SavedToolTemplate(
      id: 'default-goods-warehouses',
      name: '查看物品仓库',
      description: '获取所有物品仓库列表',
      steps: [
        ToolCallStep(
          method: 'run_js',
          title: '获取仓库列表',
          desc: '查询所有仓库',
          data: '''
const warehouses = await Memento.plugins.goods.getWarehouses();

return {
  count: warehouses.length,
  warehouses: warehouses.map(w => ({
    id: w.id,
    name: w.name,
    itemCount: w.itemCount
  }))
};
''',
        ),
      ],
      createdAt: DateTime(2025, 1, 1),
      tags: ['goods', '仓库', '列表'],
      declaredTools: [
        {'id': 'goods_getWarehouses', 'name': '获取仓库列表'}
      ],
    ),
    SavedToolTemplate(
      id: 'default-goods-items',
      name: '查看物品列表',
      description: '获取所有物品',
      steps: [
        ToolCallStep(
          method: 'run_js',
          title: '获取物品列表',
          desc: '查询所有物品',
          data: '''
const items = await Memento.plugins.goods.getItems();

return {
  count: items.length,
  items: items.map(i => ({
    id: i.id,
    name: i.name,
    warehouse: i.warehouseName,
    quantity: i.quantity
  }))
};
''',
        ),
      ],
      createdAt: DateTime(2025, 1, 1),
      tags: ['goods', '物品', '列表'],
      declaredTools: [
        {'id': 'goods_getItems', 'name': '获取物品列表'}
      ],
    ),
    SavedToolTemplate(
      id: 'default-goods-create',
      name: '创建物品',
      description: '创建一个新物品',
      steps: [
        ToolCallStep(
          method: 'run_js',
          title: '创建物品',
          desc: '创建"MacBook Pro"物品',
          data: '''
const warehouses = await Memento.plugins.goods.getWarehouses();
const warehouse = warehouses[0];

if (!warehouse) {
  return { success: false, message: '没有仓库' };
}

const item = await Memento.plugins.goods.createItem({
  name: 'MacBook Pro',
  warehouseId: warehouse.id,
  quantity: 1,
  description: '2023款 14寸'
});

return {
  success: true,
  item: {
    id: item.id,
    name: item.name,
    warehouse: warehouse.name
  }
};
''',
        ),
      ],
      createdAt: DateTime(2025, 1, 1),
      tags: ['goods', '创建', '物品'],
      declaredTools: [
        {'id': 'goods_getWarehouses', 'name': '获取仓库列表'},
        {'id': 'goods_createItem', 'name': '创建物品'}
      ],
    ),
    SavedToolTemplate(
      id: 'default-goods-stats',
      name: '物品统计',
      description: '获取物品统计信息',
      steps: [
        ToolCallStep(
          method: 'run_js',
          title: '获取统计数据',
          desc: '查询物品统计',
          data: '''
const stats = await Memento.plugins.goods.getStats();

return {
  totalItems: stats.totalItems,
  totalWarehouses: stats.totalWarehouses,
  totalValue: stats.totalValue
};
''',
        ),
      ],
      createdAt: DateTime(2025, 1, 1),
      tags: ['goods', '统计', '数据'],
      declaredTools: [
        {'id': 'goods_getStats', 'name': '获取统计'}
      ],
    ),
  ];

  // ==================== 习惯养成模板 ====================
  static final List<SavedToolTemplate> _habitsTemplates = [
    SavedToolTemplate(
      id: 'default-habits-all',
      name: '查看所有习惯',
      description: '获取所有习惯列表',
      steps: [
        ToolCallStep(
          method: 'run_js',
          title: '获取习惯列表',
          desc: '查询所有习惯',
          data: '''
const habits = await Memento.plugins.habits.getHabits();

return {
  count: habits.length,
  habits: habits.map(h => ({
    id: h.id,
    name: h.name,
    targetMinutes: h.targetMinutes,
    totalMinutes: h.totalMinutes
  }))
};
''',
        ),
      ],
      createdAt: DateTime(2025, 1, 1),
      tags: ['habits', '习惯', '列表'],
      declaredTools: [
        {'id': 'habits_getHabits', 'name': '获取习惯列表'}
      ],
    ),
    SavedToolTemplate(
      id: 'default-habits-create',
      name: '创建习惯',
      description: '创建一个新习惯',
      steps: [
        ToolCallStep(
          method: 'run_js',
          title: '创建习惯',
          desc: '创建每日阅读习惯',
          data: '''
const habit = await Memento.plugins.habits.createHabit({
  name: '每天阅读',
  targetMinutes: 30
});

return {
  success: true,
  habit: {
    id: habit.id,
    name: habit.name,
    targetMinutes: habit.targetMinutes
  }
};
''',
        ),
      ],
      createdAt: DateTime(2025, 1, 1),
      tags: ['habits', '创建', '习惯'],
      declaredTools: [
        {'id': 'habits_createHabit', 'name': '创建习惯'}
      ],
    ),
    SavedToolTemplate(
      id: 'default-habits-checkin',
      name: '打卡习惯',
      description: '完成习惯打卡',
      steps: [
        ToolCallStep(
          method: 'run_js',
          title: '打卡习惯',
          desc: '打卡完成习惯',
          data: '''
const habits = await Memento.plugins.habits.getHabits();
const habit = habits[0];

if (!habit) {
  return { success: false, message: '没有习惯' };
}

await Memento.plugins.habits.checkin({
  habitId: habit.id,
  minutes: 30
});

return {
  success: true,
  habit: {
    name: habit.name,
    minutes: 30
  }
};
''',
        ),
      ],
      createdAt: DateTime(2025, 1, 1),
      tags: ['habits', '打卡', '完成'],
      declaredTools: [
        {'id': 'habits_getHabits', 'name': '获取习惯列表'},
        {'id': 'habits_checkin', 'name': '打卡'}
      ],
    ),
    SavedToolTemplate(
      id: 'default-habits-stats',
      name: '习惯统计',
      description: '获取习惯统计数据',
      steps: [
        ToolCallStep(
          method: 'run_js',
          title: '获取统计数据',
          desc: '查询习惯统计',
          data: '''
const stats = await Memento.plugins.habits.getStats();

return {
  totalHabits: stats.totalHabits,
  todayCompleted: stats.todayCompleted,
  totalMinutes: stats.totalMinutes
};
''',
        ),
      ],
      createdAt: DateTime(2025, 1, 1),
      tags: ['habits', '统计', '数据'],
      declaredTools: [
        {'id': 'habits_getStats', 'name': '获取统计'}
      ],
    ),
    SavedToolTemplate(
      id: 'default-habits-today',
      name: '今日习惯清单',
      description: '查看今天的习惯清单',
      steps: [
        ToolCallStep(
          method: 'run_js',
          title: '获取今日习惯',
          desc: '查询今天的习惯清单',
          data: '''
const todayHabits = await Memento.plugins.habits.getTodayHabits();

return {
  count: todayHabits.length,
  habits: todayHabits.map(h => ({
    name: h.name,
    completed: h.completed,
    todayMinutes: h.todayMinutes,
    targetMinutes: h.targetMinutes
  }))
};
''',
        ),
      ],
      createdAt: DateTime(2025, 1, 1),
      tags: ['habits', '今日', '清单'],
      declaredTools: [
        {'id': 'habits_getTodayHabits', 'name': '获取今日习惯'}
      ],
    ),
  ];

  // ==================== 笔记本模板 ====================
  static final List<SavedToolTemplate> _nodesTemplates = [
    SavedToolTemplate(
      id: 'default-nodes-notebooks',
      name: '查看所有笔记本',
      description: '获取所有笔记本列表',
      steps: [
        ToolCallStep(
          method: 'run_js',
          title: '获取笔记本列表',
          desc: '查询所有笔记本',
          data: '''
const notebooks = await Memento.plugins.nodes.getNotebooks();

return {
  count: notebooks.length,
  notebooks: notebooks.map(n => ({
    id: n.id,
    name: n.name,
    nodeCount: n.nodeCount
  }))
};
''',
        ),
      ],
      createdAt: DateTime(2025, 1, 1),
      tags: ['nodes', '笔记本', '列表'],
      declaredTools: [
        {'id': 'nodes_getNotebooks', 'name': '获取笔记本列表'}
      ],
    ),
    SavedToolTemplate(
      id: 'default-nodes-create-notebook',
      name: '创建笔记本',
      description: '创建一个新的笔记本',
      steps: [
        ToolCallStep(
          method: 'run_js',
          title: '创建笔记本',
          desc: '创建"工作笔记"笔记本',
          data: '''
const notebook = await Memento.plugins.nodes.createNotebook({
  name: '工作笔记'
});

return {
  success: true,
  notebook: {
    id: notebook.id,
    name: notebook.name
  }
};
''',
        ),
      ],
      createdAt: DateTime(2025, 1, 1),
      tags: ['nodes', '创建', '笔记本'],
      declaredTools: [
        {'id': 'nodes_createNotebook', 'name': '创建笔记本'}
      ],
    ),
    SavedToolTemplate(
      id: 'default-nodes-tree',
      name: '获取节点树',
      description: '获取笔记本的节点树结构',
      steps: [
        ToolCallStep(
          method: 'run_js',
          title: '获取节点树',
          desc: '查询笔记本节点树',
          data: '''
const notebooks = await Memento.plugins.nodes.getNotebooks();
const notebook = notebooks[0];

if (!notebook) {
  return { success: false, message: '没有笔记本' };
}

const tree = await Memento.plugins.nodes.getTree({
  notebookId: notebook.id
});

return {
  notebookName: notebook.name,
  tree: tree
};
''',
        ),
      ],
      createdAt: DateTime(2025, 1, 1),
      tags: ['nodes', '节点', '树'],
      declaredTools: [
        {'id': 'nodes_getNotebooks', 'name': '获取笔记本列表'},
        {'id': 'nodes_getTree', 'name': '获取节点树'}
      ],
    ),
    SavedToolTemplate(
      id: 'default-nodes-create-node',
      name: '创建节点',
      description: '在笔记本中创建新节点',
      steps: [
        ToolCallStep(
          method: 'run_js',
          title: '创建节点',
          desc: '创建新节点',
          data: '''
const notebooks = await Memento.plugins.nodes.getNotebooks();
const notebook = notebooks[0];

if (!notebook) {
  return { success: false, message: '没有笔记本' };
}

const node = await Memento.plugins.nodes.createNode({
  notebookId: notebook.id,
  title: '新节点',
  content: '节点内容'
});

return {
  success: true,
  node: {
    id: node.id,
    title: node.title
  }
};
''',
        ),
      ],
      createdAt: DateTime(2025, 1, 1),
      tags: ['nodes', '创建', '节点'],
      declaredTools: [
        {'id': 'nodes_getNotebooks', 'name': '获取笔记本列表'},
        {'id': 'nodes_createNode', 'name': '创建节点'}
      ],
    ),
  ];
}

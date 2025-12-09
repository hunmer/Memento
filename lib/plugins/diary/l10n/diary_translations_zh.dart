/// 日记插件中文翻译
class DiaryTranslationsZh {
  static const Map<String, String> translations = {
    // 插件基本信息
    'diary_name': '日记',
    'diary_diaryPluginDescription': '日记管理插件',

    // 小组件相关
    'diary_widgetName': '日记',
    'diary_widgetDescription': '快速打开日记',
    'diary_overviewName': '日记概览',
    'diary_overviewDescription': '显示今日字数和本月进度',

    // 统计信息
    'diary_todayWordCount': '今日文字数',
    'diary_monthWordCount': '本月文字数',
    'diary_monthProgress': '本月完成度',

    // 日记编辑器
    'diary_titleHint': '给今天的日记起个标题...',
    'diary_contentHint': '写下今天的故事...',
    'diary_selectMood': '选择今天的心情',
    'diary_clearSelection': '清除选择',
    'diary_moodSelectorTooltip': '选择心情',

    // Activity form translations
    'diary_addActivity': '添加活动',
    'diary_editActivity': '编辑活动',
    'diary_activityName': '活动名称',
    'diary_unnamedActivity': '未命名活动',
    'diary_activityDescription': '活动描述',
    'diary_tagsHint': '例如: 工作, 学习, 运动',
    'diary_tagsHelperText': '可以直接输入新标签,将自动保存到未分组',
    'diary_editInterval': '修改时间间隔',
    'diary_confirmButton': '确定',
    'diary_cancelButton': '取消',
    'diary_endTimeError': '结束时间必须晚于开始时间',
    'diary_minDurationError': '活动时间必须至少为1分钟',
    'diary_dayEndError': '活动结束时间不能超过当天23:59',

    // Timeline app bar translations
    'diary_activityTimeline': '活动时间线',
    'diary_minutesSelected': '@minutes分钟已选中',
    'diary_switchToTimelineView': '切换到时间线视图',
    'diary_switchToGridView': '切换到网格视图',
    'diary_tagManagement': '标签管理',
    'diary_sortBy': '排序方式',
    'diary_sortByStartTimeAsc': '按开始时间升序',
    'diary_sortByDuration': '按活动时长排序',
    'diary_sortByStartTimeDesc': '按开始时间降序',

    // 心情与日记管理
    'diary_mood': '心情',
    'diary_cannotSelectFutureDate': '不能选择未来的日期',
    'diary_myDiary': '我的日记',
    'diary_recentlyUsed': '最近使用',
    'diary_deleteDiary': '删除日记',
    'diary_confirmDeleteDiary': '确认删除',
    'diary_deleteDiaryMessage': '确定要删除这篇日记吗?此操作无法撤销。',
    'diary_noDiaryForDate': '这一天还没有日记',

    // 按钮文本
    'diary_edit': '编辑',
    'diary_create': '新建',

    // 额外的翻译（在实现类中但未在抽象类中声明）
    'diary_cancel': '取消',
    'diary_save': '保存',
    'diary_close': '关闭',
    'diary_startTime': '开始时间',
    'diary_endTime': '结束时间',
    'diary_interval': '间隔',
    'diary_minutes': '分钟',
    'diary_tags': '标签',
    'diary_searchPlaceholder': '搜索日记内容...',
  };
}

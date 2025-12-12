/**
 * MCP 工具定义
 */
/**
 * 获取工具定义列表
 */
export function getToolDefinitions() {
    return [
        // ==================== Chat 工具 ====================
        {
            name: 'memento_chat_getChannels',
            description: '获取聊天频道列表',
            inputSchema: {
                type: 'object',
                properties: {
                    offset: { type: 'number', description: '偏移量' },
                    count: { type: 'number', description: '数量限制' },
                },
            },
        },
        {
            name: 'memento_chat_createChannel',
            description: '创建新的聊天频道',
            inputSchema: {
                type: 'object',
                properties: {
                    name: { type: 'string', description: '频道名称' },
                    description: { type: 'string', description: '频道描述' },
                },
                required: ['name'],
            },
        },
        {
            name: 'memento_chat_getMessages',
            description: '获取指定频道的消息列表',
            inputSchema: {
                type: 'object',
                properties: {
                    channelId: { type: 'string', description: '频道 ID' },
                    offset: { type: 'number', description: '偏移量' },
                    count: { type: 'number', description: '数量限制' },
                },
                required: ['channelId'],
            },
        },
        {
            name: 'memento_chat_sendMessage',
            description: '向频道发送消息',
            inputSchema: {
                type: 'object',
                properties: {
                    channelId: { type: 'string', description: '频道 ID' },
                    content: { type: 'string', description: '消息内容' },
                    senderId: { type: 'string', description: '发送者 ID' },
                    senderName: { type: 'string', description: '发送者名称' },
                },
                required: ['channelId', 'content', 'senderId', 'senderName'],
            },
        },
        // ==================== Notes 工具 ====================
        {
            name: 'memento_notes_getNotes',
            description: '获取笔记列表',
            inputSchema: {
                type: 'object',
                properties: {
                    folderId: { type: 'string', description: '文件夹 ID (可选)' },
                    offset: { type: 'number', description: '偏移量' },
                    count: { type: 'number', description: '数量限制' },
                },
            },
        },
        {
            name: 'memento_notes_createNote',
            description: '创建新笔记',
            inputSchema: {
                type: 'object',
                properties: {
                    title: { type: 'string', description: '笔记标题' },
                    content: { type: 'string', description: '笔记内容 (支持 Markdown)' },
                    folderId: { type: 'string', description: '文件夹 ID' },
                    tags: { type: 'array', items: { type: 'string' }, description: '标签列表' },
                },
                required: ['title', 'content'],
            },
        },
        {
            name: 'memento_notes_updateNote',
            description: '更新笔记',
            inputSchema: {
                type: 'object',
                properties: {
                    id: { type: 'string', description: '笔记 ID' },
                    title: { type: 'string', description: '新标题' },
                    content: { type: 'string', description: '新内容' },
                    tags: { type: 'array', items: { type: 'string' }, description: '新标签' },
                },
                required: ['id'],
            },
        },
        {
            name: 'memento_notes_searchNotes',
            description: '搜索笔记',
            inputSchema: {
                type: 'object',
                properties: {
                    keyword: { type: 'string', description: '搜索关键词' },
                    offset: { type: 'number', description: '偏移量' },
                    count: { type: 'number', description: '数量限制' },
                },
                required: ['keyword'],
            },
        },
        // ==================== Activity 工具 ====================
        {
            name: 'memento_activity_getActivities',
            description: '获取活动记录列表',
            inputSchema: {
                type: 'object',
                properties: {
                    date: { type: 'string', description: '日期 (YYYY-MM-DD)，默认今天' },
                    offset: { type: 'number', description: '偏移量' },
                    count: { type: 'number', description: '数量限制' },
                },
            },
        },
        {
            name: 'memento_activity_createActivity',
            description: '创建活动记录',
            inputSchema: {
                type: 'object',
                properties: {
                    startTime: { type: 'string', description: '开始时间 (ISO 8601)' },
                    endTime: { type: 'string', description: '结束时间 (ISO 8601)' },
                    title: { type: 'string', description: '活动标题' },
                    tags: { type: 'array', items: { type: 'string' }, description: '标签' },
                    description: { type: 'string', description: '描述' },
                    mood: { type: 'number', description: '心情值 (1-5)' },
                },
                required: ['startTime', 'endTime', 'title'],
            },
        },
        {
            name: 'memento_activity_getTodayStats',
            description: '获取今日活动统计',
            inputSchema: {
                type: 'object',
                properties: {},
            },
        },
        // ==================== Goods 工具 ====================
        {
            name: 'memento_goods_getWarehouses',
            description: '获取仓库列表',
            inputSchema: {
                type: 'object',
                properties: {
                    offset: { type: 'number', description: '偏移量' },
                    count: { type: 'number', description: '数量限制' },
                },
            },
        },
        {
            name: 'memento_goods_getItems',
            description: '获取物品列表',
            inputSchema: {
                type: 'object',
                properties: {
                    warehouseId: { type: 'string', description: '仓库 ID (可选)' },
                    offset: { type: 'number', description: '偏移量' },
                    count: { type: 'number', description: '数量限制' },
                },
            },
        },
        {
            name: 'memento_goods_createItem',
            description: '创建物品',
            inputSchema: {
                type: 'object',
                properties: {
                    name: { type: 'string', description: '物品名称' },
                    warehouseId: { type: 'string', description: '仓库 ID' },
                    description: { type: 'string', description: '描述' },
                    quantity: { type: 'number', description: '数量' },
                    category: { type: 'string', description: '分类' },
                    tags: { type: 'array', items: { type: 'string' }, description: '标签' },
                },
                required: ['name', 'warehouseId'],
            },
        },
        {
            name: 'memento_goods_searchItems',
            description: '搜索物品',
            inputSchema: {
                type: 'object',
                properties: {
                    keyword: { type: 'string', description: '搜索关键词' },
                    warehouseId: { type: 'string', description: '仓库 ID (可选)' },
                },
                required: ['keyword'],
            },
        },
        // ==================== Bill 工具 ====================
        {
            name: 'memento_bill_getAccounts',
            description: '获取账户列表',
            inputSchema: {
                type: 'object',
                properties: {
                    offset: { type: 'number', description: '偏移量' },
                    count: { type: 'number', description: '数量限制' },
                },
            },
        },
        {
            name: 'memento_bill_getBills',
            description: '获取账单列表',
            inputSchema: {
                type: 'object',
                properties: {
                    accountId: { type: 'string', description: '账户 ID' },
                    offset: { type: 'number', description: '偏移量' },
                    count: { type: 'number', description: '数量限制' },
                },
                required: ['accountId'],
            },
        },
        {
            name: 'memento_bill_createBill',
            description: '创建账单',
            inputSchema: {
                type: 'object',
                properties: {
                    accountId: { type: 'string', description: '账户 ID' },
                    type: { type: 'string', enum: ['income', 'expense', 'transfer'], description: '类型' },
                    amount: { type: 'number', description: '金额' },
                    category: { type: 'string', description: '分类' },
                    description: { type: 'string', description: '描述' },
                    date: { type: 'string', description: '日期 (YYYY-MM-DD)' },
                },
                required: ['accountId', 'type', 'amount'],
            },
        },
        {
            name: 'memento_bill_getStats',
            description: '获取账单统计',
            inputSchema: {
                type: 'object',
                properties: {
                    startDate: { type: 'string', description: '开始日期' },
                    endDate: { type: 'string', description: '结束日期' },
                },
            },
        },
        // ==================== Todo 工具 ====================
        {
            name: 'memento_todo_getTasks',
            description: '获取任务列表',
            inputSchema: {
                type: 'object',
                properties: {
                    completed: { type: 'string', description: '完成状态筛选 (true/false)' },
                    priority: { type: 'string', description: '优先级筛选 (0-3)' },
                    category: { type: 'string', description: '分类筛选' },
                    offset: { type: 'number', description: '偏移量' },
                    count: { type: 'number', description: '数量限制' },
                },
            },
        },
        {
            name: 'memento_todo_createTask',
            description: '创建任务',
            inputSchema: {
                type: 'object',
                properties: {
                    title: { type: 'string', description: '任务标题' },
                    description: { type: 'string', description: '任务描述' },
                    dueDate: { type: 'string', description: '截止日期 (YYYY-MM-DD)' },
                    priority: { type: 'number', description: '优先级 (0-3，3 最高)' },
                    category: { type: 'string', description: '分类' },
                    tags: { type: 'array', items: { type: 'string' }, description: '标签' },
                },
                required: ['title'],
            },
        },
        {
            name: 'memento_todo_updateTask',
            description: '更新任务',
            inputSchema: {
                type: 'object',
                properties: {
                    id: { type: 'string', description: '任务 ID' },
                    title: { type: 'string', description: '新标题' },
                    description: { type: 'string', description: '新描述' },
                    completed: { type: 'boolean', description: '完成状态' },
                    dueDate: { type: 'string', description: '新截止日期' },
                    priority: { type: 'number', description: '新优先级' },
                },
                required: ['id'],
            },
        },
        {
            name: 'memento_todo_completeTask',
            description: '完成任务',
            inputSchema: {
                type: 'object',
                properties: {
                    id: { type: 'string', description: '任务 ID' },
                },
                required: ['id'],
            },
        },
        {
            name: 'memento_todo_getTodayTasks',
            description: '获取今日任务',
            inputSchema: {
                type: 'object',
                properties: {},
            },
        },
        {
            name: 'memento_todo_getOverdueTasks',
            description: '获取过期任务',
            inputSchema: {
                type: 'object',
                properties: {},
            },
        },
        {
            name: 'memento_todo_searchTasks',
            description: '搜索任务',
            inputSchema: {
                type: 'object',
                properties: {
                    keyword: { type: 'string', description: '搜索关键词' },
                },
                required: ['keyword'],
            },
        },
        {
            name: 'memento_todo_getStats',
            description: '获取任务统计',
            inputSchema: {
                type: 'object',
                properties: {},
            },
        },
        // ==================== Diary 工具 ====================
        {
            name: 'memento_diary_getEntries',
            description: '获取日记列表',
            inputSchema: {
                type: 'object',
                properties: {
                    startDate: { type: 'string', description: '开始日期 (YYYY-MM-DD)' },
                    endDate: { type: 'string', description: '结束日期 (YYYY-MM-DD)' },
                    offset: { type: 'number', description: '偏移量' },
                    count: { type: 'number', description: '数量限制' },
                },
            },
        },
        {
            name: 'memento_diary_getEntry',
            description: '获取指定日期的日记',
            inputSchema: {
                type: 'object',
                properties: {
                    date: { type: 'string', description: '日期 (YYYY-MM-DD)' },
                },
                required: ['date'],
            },
        },
        {
            name: 'memento_diary_createEntry',
            description: '创建日记',
            inputSchema: {
                type: 'object',
                properties: {
                    date: { type: 'string', description: '日期 (YYYY-MM-DD)' },
                    content: { type: 'string', description: '日记内容 (支持 Markdown)' },
                    mood: { type: 'number', description: '心情 (1-5)' },
                    weather: { type: 'string', description: '天气' },
                    tags: { type: 'array', items: { type: 'string' }, description: '标签' },
                },
                required: ['date', 'content'],
            },
        },
        {
            name: 'memento_diary_updateEntry',
            description: '更新日记',
            inputSchema: {
                type: 'object',
                properties: {
                    date: { type: 'string', description: '日期 (YYYY-MM-DD)' },
                    content: { type: 'string', description: '新内容' },
                    mood: { type: 'number', description: '新心情' },
                    weather: { type: 'string', description: '新天气' },
                    tags: { type: 'array', items: { type: 'string' }, description: '新标签' },
                },
                required: ['date'],
            },
        },
        {
            name: 'memento_diary_searchEntries',
            description: '搜索日记',
            inputSchema: {
                type: 'object',
                properties: {
                    keyword: { type: 'string', description: '搜索关键词' },
                    startDate: { type: 'string', description: '开始日期' },
                    endDate: { type: 'string', description: '结束日期' },
                    mood: { type: 'string', description: '心情筛选' },
                },
            },
        },
        {
            name: 'memento_diary_getStats',
            description: '获取日记统计',
            inputSchema: {
                type: 'object',
                properties: {},
            },
        },
        // ==================== Checkin 工具 ====================
        {
            name: 'memento_checkin_getItems',
            description: '获取打卡项目列表',
            inputSchema: {
                type: 'object',
                properties: {
                    offset: { type: 'number', description: '偏移量' },
                    count: { type: 'number', description: '数量限制' },
                },
            },
        },
        {
            name: 'memento_checkin_createItem',
            description: '创建打卡项目',
            inputSchema: {
                type: 'object',
                properties: {
                    name: { type: 'string', description: '项目名称' },
                    icon: { type: 'string', description: '图标' },
                    color: { type: 'string', description: '颜色' },
                    group: { type: 'string', description: '分组' },
                    description: { type: 'string', description: '描述' },
                },
                required: ['name'],
            },
        },
        {
            name: 'memento_checkin_addRecord',
            description: '添加打卡记录',
            inputSchema: {
                type: 'object',
                properties: {
                    itemId: { type: 'string', description: '打卡项目 ID' },
                    date: { type: 'string', description: '日期 (YYYY-MM-DD)' },
                    note: { type: 'string', description: '备注' },
                },
                required: ['itemId', 'date'],
            },
        },
        {
            name: 'memento_checkin_getStats',
            description: '获取打卡统计',
            inputSchema: {
                type: 'object',
                properties: {},
            },
        },
        // ==================== Day 工具 ====================
        {
            name: 'memento_day_getMemorialDays',
            description: '获取纪念日列表',
            inputSchema: {
                type: 'object',
                properties: {
                    sortMode: { type: 'string', description: '排序模式' },
                    offset: { type: 'number', description: '偏移量' },
                    count: { type: 'number', description: '数量限制' },
                },
            },
        },
        {
            name: 'memento_day_createMemorialDay',
            description: '创建纪念日',
            inputSchema: {
                type: 'object',
                properties: {
                    name: { type: 'string', description: '纪念日名称' },
                    date: { type: 'string', description: '日期 (YYYY-MM-DD)' },
                    type: { type: 'string', description: '类型（倒计时/正计时）' },
                    description: { type: 'string', description: '描述' },
                    color: { type: 'string', description: '颜色' },
                },
                required: ['name', 'date'],
            },
        },
        {
            name: 'memento_day_searchMemorialDays',
            description: '搜索纪念日',
            inputSchema: {
                type: 'object',
                properties: {
                    sortMode: { type: 'string', description: '排序模式' },
                    startDate: { type: 'string', description: '开始日期' },
                    endDate: { type: 'string', description: '结束日期' },
                    includeExpired: { type: 'boolean', description: '包含已过期' },
                },
            },
        },
        {
            name: 'memento_day_getStats',
            description: '获取纪念日统计',
            inputSchema: {
                type: 'object',
                properties: {},
            },
        },
        // ==================== Tracker 工具 ====================
        {
            name: 'memento_tracker_getGoals',
            description: '获取追踪目标列表',
            inputSchema: {
                type: 'object',
                properties: {
                    offset: { type: 'number', description: '偏移量' },
                    count: { type: 'number', description: '数量限制' },
                },
            },
        },
        {
            name: 'memento_tracker_createGoal',
            description: '创建追踪目标',
            inputSchema: {
                type: 'object',
                properties: {
                    name: { type: 'string', description: '目标名称' },
                    targetValue: { type: 'number', description: '目标值' },
                    unit: { type: 'string', description: '单位' },
                    group: { type: 'string', description: '分组' },
                    description: { type: 'string', description: '描述' },
                },
                required: ['name', 'targetValue', 'unit'],
            },
        },
        {
            name: 'memento_tracker_addRecord',
            description: '添加追踪记录',
            inputSchema: {
                type: 'object',
                properties: {
                    goalId: { type: 'string', description: '目标 ID' },
                    value: { type: 'number', description: '记录值' },
                    date: { type: 'string', description: '日期 (YYYY-MM-DD)' },
                    note: { type: 'string', description: '备注' },
                },
                required: ['goalId', 'value', 'date'],
            },
        },
        {
            name: 'memento_tracker_getStats',
            description: '获取追踪统计',
            inputSchema: {
                type: 'object',
                properties: {},
            },
        },
        // ==================== Contact 工具 ====================
        {
            name: 'memento_contact_getContacts',
            description: '获取联系人列表',
            inputSchema: {
                type: 'object',
                properties: {
                    offset: { type: 'number', description: '偏移量' },
                    count: { type: 'number', description: '数量限制' },
                },
            },
        },
        {
            name: 'memento_contact_createContact',
            description: '创建联系人',
            inputSchema: {
                type: 'object',
                properties: {
                    name: { type: 'string', description: '姓名' },
                    phone: { type: 'string', description: '电话' },
                    email: { type: 'string', description: '邮箱' },
                    tags: { type: 'array', items: { type: 'string' }, description: '标签' },
                    notes: { type: 'string', description: '备注' },
                },
                required: ['name'],
            },
        },
        {
            name: 'memento_contact_searchContacts',
            description: '搜索联系人',
            inputSchema: {
                type: 'object',
                properties: {
                    keyword: { type: 'string', description: '搜索关键词' },
                },
                required: ['keyword'],
            },
        },
        {
            name: 'memento_contact_getStats',
            description: '获取联系人统计',
            inputSchema: {
                type: 'object',
                properties: {},
            },
        },
        // ==================== Calendar 工具 ====================
        {
            name: 'memento_calendar_getEvents',
            description: '获取日历事件列表',
            inputSchema: {
                type: 'object',
                properties: {
                    startDate: { type: 'string', description: '开始日期 (YYYY-MM-DD)' },
                    endDate: { type: 'string', description: '结束日期 (YYYY-MM-DD)' },
                    offset: { type: 'number', description: '偏移量' },
                    count: { type: 'number', description: '数量限制' },
                },
            },
        },
        {
            name: 'memento_calendar_createEvent',
            description: '创建日历事件',
            inputSchema: {
                type: 'object',
                properties: {
                    title: { type: 'string', description: '事件标题' },
                    startTime: { type: 'string', description: '开始时间 (ISO 8601)' },
                    endTime: { type: 'string', description: '结束时间 (ISO 8601)' },
                    description: { type: 'string', description: '描述' },
                    location: { type: 'string', description: '地点' },
                },
                required: ['title', 'startTime'],
            },
        },
        {
            name: 'memento_calendar_completeEvent',
            description: '完成日历事件',
            inputSchema: {
                type: 'object',
                properties: {
                    id: { type: 'string', description: '事件 ID' },
                },
                required: ['id'],
            },
        },
        {
            name: 'memento_calendar_searchEvents',
            description: '搜索日历事件',
            inputSchema: {
                type: 'object',
                properties: {
                    keyword: { type: 'string', description: '搜索关键词' },
                },
                required: ['keyword'],
            },
        },
    ];
}
//# sourceMappingURL=index.js.map
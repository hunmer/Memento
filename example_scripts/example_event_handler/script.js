// ========================================
// 示例脚本：事件处理器
// ========================================
//
// 功能：演示如何在脚本中访问事件数据
//
// 配置方法：
// 1. 在脚本元数据中添加触发器：
//    "triggers": [
//      {"event": "diary_entry_added"},
//      {"event": "todo_task_completed"}
//    ]
//
// 2. 启用脚本后，相关事件触发时会自动执行
// ========================================

// 打印调试信息
console.log('=== 事件触发 ===');
console.log('事件名称:', args.event);
console.log('脚本信息:', scriptInfo);

// 检查是否有事件数据
if (!args.eventData) {
    console.warn('⚠️ 没有事件数据');
    return {
        success: false,
        error: '此脚本需要通过事件触发器执行'
    };
}

// 打印完整的事件数据（用于调试）
console.log('事件数据:', JSON.stringify(args.eventData, null, 2));

// 根据不同的事件类型进行处理
switch (args.event) {
    case 'diary_entry_added':
        handleDiaryAdded();
        break;

    case 'diary_entry_updated':
        handleDiaryUpdated();
        break;

    case 'diary_entry_deleted':
        handleDiaryDeleted();
        break;

    case 'todo_task_added':
        handleTaskAdded();
        break;

    case 'todo_task_completed':
        handleTaskCompleted();
        break;

    case 'calendar_event_added':
        handleCalendarEventAdded();
        break;

    default:
        handleGenericEvent();
}

// ========================================
// 处理函数
// ========================================

function handleDiaryAdded() {
    console.log('📝 新日记已添加');

    const title = args.eventData.title || '无标题';
    const itemId = args.eventData.itemId;
    const addedTime = new Date(args.eventData.whenOccurred);

    console.log(`  标题: ${title}`);
    console.log(`  ID: ${itemId}`);
    console.log(`  时间: ${addedTime.toLocaleString('zh-CN')}`);

    // 示例：发送通知（如果有聊天插件）
    // await Memento.chat.sendMessage(
    //     'notifications',
    //     `📝 新日记: ${title}\n时间: ${addedTime.toLocaleString('zh-CN')}`
    // );

    return {
        success: true,
        message: `已处理日记添加事件: ${title}`
    };
}

function handleDiaryUpdated() {
    console.log('✏️ 日记已更新');

    const title = args.eventData.title;
    const itemId = args.eventData.itemId;

    console.log(`  标题: ${title}`);
    console.log(`  ID: ${itemId}`);

    return {
        success: true,
        message: `已处理日记更新事件: ${title}`
    };
}

function handleDiaryDeleted() {
    console.log('🗑️ 日记已删除');

    const title = args.eventData.title;
    const itemId = args.eventData.itemId;

    console.log(`  标题: ${title}`);
    console.log(`  ID: ${itemId}`);

    return {
        success: true,
        message: `已处理日记删除事件: ${title}`
    };
}

function handleTaskAdded() {
    console.log('✅ 新任务已添加');

    const title = args.eventData.title;
    const itemId = args.eventData.itemId;
    const addedTime = new Date(args.eventData.whenOccurred);

    console.log(`  任务: ${title}`);
    console.log(`  ID: ${itemId}`);
    console.log(`  时间: ${addedTime.toLocaleString('zh-CN')}`);

    return {
        success: true,
        message: `已处理任务添加事件: ${title}`
    };
}

function handleTaskCompleted() {
    console.log('🎉 任务已完成');

    const title = args.eventData.title;
    const itemId = args.eventData.itemId;
    const completedTime = new Date(args.eventData.whenOccurred);

    console.log(`  任务: ${title}`);
    console.log(`  ID: ${itemId}`);
    console.log(`  完成时间: ${completedTime.toLocaleString('zh-CN')}`);

    // 示例：记录到统计
    const stats = {
        task: title,
        completedAt: completedTime,
        date: completedTime.toLocaleDateString('zh-CN')
    };

    console.log('  统计数据:', stats);

    return {
        success: true,
        message: `已处理任务完成事件: ${title}`,
        stats: stats
    };
}

function handleCalendarEventAdded() {
    console.log('📅 日历事件已添加');

    const title = args.eventData.title;
    const itemId = args.eventData.itemId;

    console.log(`  事件: ${title}`);
    console.log(`  ID: ${itemId}`);

    return {
        success: true,
        message: `已处理日历事件添加: ${title}`
    };
}

function handleGenericEvent() {
    console.log('ℹ️ 处理通用事件');

    // 打印所有可用的事件数据字段
    console.log('可用字段:');
    for (const [key, value] of Object.entries(args.eventData)) {
        console.log(`  ${key}: ${value}`);
    }

    return {
        success: true,
        message: `已处理事件: ${args.event}`,
        eventData: args.eventData
    };
}


    // 获取脚本配置（getConfig 现在直接返回对象，无需 JSON.parse）
    const config = await Memento.script_executor.getConfig('ai_encouragement_bot');

    // 检查是否配置了 Agent
    if (!config.agentId) {
      console.log('未配置 AI 助手', 'warn');
      return { success: false, error: '未配置 AI 助手' };
    }

    // 获取 agent ID（agentId 可能是对象或字符串）
    const agentId = typeof config.agentId === 'object' ? config.agentId.id : config.agentId;

    // 获取触发的事件
    const eventName = args.event;
    const eventData = args.eventData;

    // 检查该事件是否已启用
    if (!config.enabledEvents || !config.enabledEvents.includes(eventName)) {
      console.log(`事件 ${eventName} 未在启用列表中`, 'info');
      return { success: true, message: '事件未启用' };
    }

    // 预设的事件解析
    const eventParsers = {
      'chat_message_sent': () => {
        const message = eventData.value.content;
        return `用户发送了新消息：${message}`;
      },
      'habit_checked': () => {
        const title = eventData.title || '某个习惯';
        return `用户完成了习惯打卡：${title}`;
      },
      'task_completed': () => {
        const title = eventData.title || '某个任务';
        return `用户完成了任务：${title}`;
      },
      'diary_entry_created': () => {
        const title = eventData.title || '一篇日记';
        return `用户写了一篇日记：${title}`;
      },
      'activity_added': () => {
        const title = eventData.title || '某个活动';
        return `用户记录了活动：${title}`;
      },
      'note_added': () => {
        const title = eventData.title || '某个笔记';
        return `用户添加了笔记：${title}`;
      },
      // Agent Chat 事件
      'agent_chat_conversation_added': () => {
        const title = eventData.title || '新会话';
        return `用户创建了一个新的 AI 对话：${title}`;
      },
      'agent_chat_conversation_updated': () => {
        const title = eventData.title || '会话';
        return `用户更新了 AI 对话：${title}`;
      },
      // Store 事件
      'store_product_added': () => {
        const title = eventData.title || '新商品';
        return `管理员添加了新商品：${title}`;
      },
      'store_user_item_added': () => {
        const title = eventData.title || '物品';
        return `用户兑换了物品：${title}`;
      },
      'store_user_item_used': () => {
        const title = eventData.title || '物品';
        return `用户使用了物品：${title}`;
      },
      'store_points_changed': () => {
        const reason = eventData.title || '积分变化';
        return `用户积分发生变化：${reason}`;
      },
      // Nodes 事件
      'nodes_notebook_added': () => {
        const title = eventData.title || '新笔记本';
        return `用户创建了新笔记本：${title}`;
      },
      'nodes_node_added': () => {
        const title = eventData.title || '新节点';
        return `用户添加了新节点：${title}`;
      },
      'nodes_node_updated': () => {
        const title = eventData.title || '节点';
        return `用户更新了节点：${title}`;
      },
      // OpenAI 事件
      'openai_agent_added': () => {
        const title = eventData.title || '新 AI 助手';
        return `用户创建了新 AI 助手：${title}`;
      },
      'openai_agent_updated': () => {
        const title = eventData.title || 'AI 助手';
        return `用户更新了 AI 助手配置：${title}`;
      },
      // Calendar 事件
      'calendar_event_added': () => {
        const title = eventData.title || '新日程';
        return `用户添加了新日程：${title}`;
      },
      'calendar_event_completed': () => {
        const title = eventData.title || '日程';
        return `用户完成了日程：${title}`;
      },
      // Bill 事件
      'bill_added': () => {
        const title = eventData.title || '账单';
        return `用户记录了账单：${title}`;
      },
      // Database 事件
      'database_added': () => {
        const title = eventData.title || '新数据库';
        return `用户创建了新数据库：${title}`;
      },
      'database_record_added': () => {
        const title = eventData.title || '记录';
        return `用户添加了数据库记录：${title}`;
      },
      // Day (纪念日) 事件
      'memorial_day_added': () => {
        const title = eventData.title || '新纪念日';
        return `用户添加了新纪念日：${title}`;
      },
      // Contact 事件
      'contact_created': () => {
        const title = eventData.title || '新联系人';
        return `用户添加了新联系人：${title}`;
      },
      // Goods 事件
      'goods_added': () => {
        const title = eventData.title || '新物品';
        return `用户添加了新物品：${title}`;
      },
      // Timer 事件
      'timer_item_progress': () => {
        const title = eventData.title || '计时器';
        return `用户的计时器有进度更新：${title}`;
      },
      'timer_item_changed': () => {
        const title = eventData.title || '计时器';
        return `用户的计时器状态变化：${title}`;
      },
      'timer_task_changed': () => {
        const title = eventData.title || '计时任务';
        return `用户的计时任务状态变化：${title}`;
      },
      // Tracker 事件
      'onRecordAdded': () => {
        const title = eventData.title || '记录';
        return `用户添加了追踪记录：${title}`;
      },
    };

    // 生成事件描述
    let eventDescription = '';
    if (eventParsers[eventName]) {
      eventDescription = eventParsers[eventName]();
    } else {
      eventDescription = `发生事件: ${eventName}`;
    }

    // 使用配置的模板或默认模板
    const promptTemplate = config.promptTemplate ||
      '根据以下事件，用一句话鼓励用户：{eventDescription}';
    const message = promptTemplate.replace('{eventDescription}', eventDescription);

    // 发送给 AI（使用 OpenAI Plugin 的 API）
    console.log(`发送消息给 AI: ${message}`, 'info');
    const result = await Memento.plugins.openai.sendMessage({
      agentId: agentId,
      message: message
    });

    if (result.error) {
      throw new Error(result.error);
    }

    // 使用真实的 AI 回复
    const encouragementText = result.response || '继续加油！';

    // 显示 Toast
    Memento.script_executor.showToast(encouragementText, 'success');

    console.log(`AI 鼓励消息已显示: ${encouragementText}`, 'info');

    return {
      success: true,
      message: '鼓励消息已显示',
      encouragement: encouragementText
    }
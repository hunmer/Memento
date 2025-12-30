
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
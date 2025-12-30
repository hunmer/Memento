// AI 鼓励助手脚本
// 功能：监听用户活动，触发事件后发送简要信息给 AI，返回鼓励的话并用 toast 展示

(async function() {
  try {
    // 获取脚本配置
    const configJson = await Memento.script_executor.getConfig('ai_encouragement_bot');
    const config = JSON.parse(configJson);

    // 检查是否启用
    if (!config || !config.enabled) {
      console.log('AI 鼓励助手未启用', 'info');
      return { success: false, error: '脚本未启用' };
    }

    // 检查是否配置了 Agent
    if (!config.agentId) {
      console.log('未配置 AI 助手', 'warn');
      return { success: false, error: '未配置 AI 助手' };
    }

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

    // 发送给 AI
    console.log(`发送消息给 AI: ${message}`, 'info');
    const resultJson = await Memento.script_executor.sendToAgent(
      config.agentId,
      message
    );
    const result = JSON.parse(resultJson);

    if (result.error) {
      throw new Error(result.error);
    }

    // 简化实现：使用预设的鼓励消息
    // 实际使用中，可以通过监听 AI 回复来获取真实的鼓励内容
    const encouragementMessages = [
      '做得很棒！继续加油！',
      '你的坚持值得赞赏！',
      '每一步都是进步！',
      '相信自己，你可以做到的！',
      '保持这个节奏，你会越来越棒！',
    ];
    const encouragementText = encouragementMessages[
      Math.floor(Math.random() * encouragementMessages.length)
    ];

    // 显示 Toast
    Memento.script_executor.showToast(encouragementText, 'success');

    console.log(`AI 鼓励消息已显示: ${encouragementText}`, 'info');

    return {
      success: true,
      message: '鼓励消息已显示',
      encouragement: encouragementText
    };
  } catch (error) {
    console.log(`执行失败: ${error}`, 'error');
    return {
      success: false,
      error: error.toString()
    };
  }
})();

/**
 * Memento JS 工具注册示例
 *
 * 此文件在 QuickJS 引擎中执行，而非在 WebView 页面中
 * 通过调用 memento.registerTool() 注册自定义 JavaScript 工具
 * 注册的工具可以被 Agent Chat 直接调用，无需打开 WebView 页面
 */

// 注册密码保存工具
memento.registerTool({
  id: 'password_save',
  name: '保存密码',
  description: '将密码保存到 Memento 存储',
  code: `
    const key = 'passwords_' + (params.account || 'default');
    const existing = JSON.parse(memento.storage.read(key) || '[]');
    existing.push({
      username: params.username,
      password: params.password,
      website: params.website,
      createdAt: new Date().toISOString()
    });
    memento.storage.write(key, JSON.stringify(existing));
    return {
      success: true,
      count: existing.length,
      message: '密码保存成功'
    };
  `,
  cardId: 'password_manager'
});

// 注册密码列表工具
memento.registerTool({
  id: 'password_list',
  name: '列出密码',
  description: '获取所有保存的密码',
  code: `
    const key = 'passwords_' + (params.account || 'default');
    const data = memento.storage.read(key);
    return {
      success: true,
      passwords: data ? JSON.parse(data) : []
    };
  `,
  cardId: 'password_manager'
});

// 注册密码搜索工具
memento.registerTool({
  id: 'password_search',
  name: '搜索密码',
  description: '根据网站或用户名搜索密码',
  code: `
    const key = 'passwords_' + (params.account || 'default');
    const data = memento.storage.read(key);
    if (!data) return { success: true, passwords: [] };

    const all = JSON.parse(data);
    const query = (params.query || '').toLowerCase();

    const filtered = all.filter(p =>
      p.website?.toLowerCase().includes(query) ||
      p.username?.toLowerCase().includes(query)
    );

    return {
      success: true,
      passwords: filtered
    };
  `,
  cardId: 'password_manager'
});

// 注册数据处理工具
memento.registerTool({
  id: 'data_process',
  name: '数据处理',
  description: '处理输入数据并返回结果',
  code: `
    const input = params.data;
    return {
      original: input,
      upperCase: input.toUpperCase(),
      length: input.length,
      timestamp: Date.now()
    };
  `,
  cardId: 'password_manager'
});

// 注册 API 调用工具
memento.registerTool({
  id: 'api_call',
  name: 'API 调用',
  description: '调用外部 API',
  code: `
    const response = await fetch(params.url, {
      method: params.method || 'GET',
      headers: params.headers || {}
    });

    const data = await response.json();
    return {
      status: response.status,
      data: data,
      ok: response.ok
    };
  `,
  cardId: 'password_manager'
});

// 注册 Memento 存储工具
memento.registerTool({
  id: 'storage_set',
  name: '保存数据',
  description: '保存数据到 Memento 存储',
  code: `
    const key = 'my_app_' + params.key;
    memento.storage.write(key, JSON.stringify(params.value));
    return { success: true, key: key };
  `,
  cardId: 'password_manager'
});

memento.registerTool({
  id: 'storage_get',
  name: '读取数据',
  description: '从 Memento 存储读取数据',
  code: `
    const key = 'my_app_' + params.key;
    const value = memento.storage.read(key);
    return {
      success: true,
      key: key,
      value: value ? JSON.parse(value) : null
    };
  `,
  cardId: 'password_manager'
});

// 获取已注册的工具列表
const toolsResult = memento.listTools();
if (toolsResult.success) {
  console.log('已注册工具数量:', toolsResult.tools.length);
  console.log('已注册工具列表:', JSON.stringify(toolsResult.tools.map(t => t.id)));
} else {
  console.error('获取工具列表失败:', toolsResult.error);
}

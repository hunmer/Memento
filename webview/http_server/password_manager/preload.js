/**
 * WebView 卡片预加载脚本
 *
 * 此文件在 QuickJS 引擎中执行，而非在 WebView 页面中
 * 通过调用 memento.registerTool() 注册特定于当前项目的自定义 JavaScript 工具
 * 注册的工具可以被 Agent Chat 直接调用，无需打开 WebView 页面
 */

// 注册密码保存工具
memento.registerTool({
  id: 'password_save',
  name: '保存密码',
  description: '将密码保存到 Memento 存储',
  parameters: [
    {
      name: 'username',
      type: 'string',
      optional: false,
      description: '用户名或账号'
    },
    {
      name: 'password',
      type: 'string',
      optional: false,
      description: '密码内容'
    },
    {
      name: 'website',
      type: 'string',
      optional: true,
      description: '网站域名（如：www.example.com）'
    },
    {
      name: 'account',
      type: 'string',
      optional: true,
      description: '账号分组名称，默认为 "default"'
    }
  ],
  examples: [
    {
      code: `const result = await memento.tools.password_save({
  username: 'john_doe',
  password: 'my_password_123',
  website: 'github.com',
  account: 'work'
});
setResult(result);`,
      comment: '保存工作账号密码'
    },
    {
      code: `const result = await memento.tools.password_save({
  username: 'john@example.com',
  password: 'email_password'
});
setResult(result);`,
      comment: '保存邮箱密码'
    }
  ],
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
  parameters: [
    {
      name: 'account',
      type: 'string',
      optional: true,
      description: '账号分组名称，默认为 "default"'
    }
  ],
  examples: [
    {
      code: `const result = await memento.tools.password_list();
setResult(result);`,
      comment: '获取默认分组的所有密码'
    },
    {
      code: `const result = await memento.tools.password_list({ account: 'work' });
setResult('工作账号数量: ' + result.passwords.length);`,
      comment: '获取工作分组密码数量'
    }
  ],
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
  parameters: [
    {
      name: 'query',
      type: 'string',
      optional: false,
      description: '搜索关键词（网站域名或用户名）'
    },
    {
      name: 'account',
      type: 'string',
      optional: true,
      description: '账号分组名称，默认为 "default"'
    }
  ],
  examples: [
    {
      code: `const result = await memento.tools.password_search({ query: 'github' });
setResult(result);`,
      comment: '搜索包含 "github" 的密码'
    },
    {
      code: `const result = await memento.tools.password_search({
  query: 'john',
  account: 'work'
});
setResult(result);`,
      comment: '在工作分组中搜索用户名包含 "john" 的密码'
    }
  ],
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
  description: '对输入数据进行格式化处理，返回原始数据及其转换结果',
  parameters: [
    {
      name: 'data',
      type: 'string',
      optional: false,
      description: '要处理的字符串数据'
    }
  ],
  examples: [
    {
      code: `const result = await memento.tools.data_process({ data: 'hello world' });
setResult(result);`,
      comment: '处理字符串数据'
    },
    {
      code: `const result = await memento.tools.data_process({ data: 'test' });
setResult('原始: ' + result.original + ', 大写: ' + result.upperCase);`,
      comment: '获取处理结果的特定字段'
    }
  ],
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
  description: '调用外部 HTTP API，支持 GET、POST 等方法',
  parameters: [
    {
      name: 'url',
      type: 'string',
      optional: false,
      description: 'API 接口地址'
    },
    {
      name: 'method',
      type: 'string',
      optional: true,
      description: 'HTTP 方法，默认为 "GET"'
    },
    {
      name: 'headers',
      type: 'object',
      optional: true,
      description: '请求头对象'
    }
  ],
  examples: [
    {
      code: `const result = await memento.tools.api_call({
  url: 'https://api.github.com/users/octocat'
});
setResult(result);`,
      comment: 'GET 请求获取 GitHub 用户信息'
    },
    {
      code: `const result = await memento.tools.api_call({
  url: 'https://httpbin.org/post',
  method: 'POST',
  headers: { 'Content-Type': 'application/json' }
});
setResult(result);`,
      comment: 'POST 请求示例'
    }
  ],
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
  description: '保存任意数据到 Memento 存储（会话级内存存储）',
  parameters: [
    {
      name: 'key',
      type: 'string',
      optional: false,
      description: '存储键名（会自动添加 "my_app_" 前缀）'
    },
    {
      name: 'value',
      type: 'any',
      optional: false,
      description: '要存储的数据（任意类型）'
    }
  ],
  examples: [
    {
      code: `const result = await memento.tools.storage_set({
  key: 'user_preference',
  value: { theme: 'dark', language: 'zh-CN' }
});
setResult(result);`,
      comment: '保存用户偏好设置'
    },
    {
      code: `const result = await memento.tools.storage_set({
  key: 'cache_data',
  value: [1, 2, 3, 4, 5]
});
setResult(result);`,
      comment: '保存数组数据'
    }
  ],
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
  description: '从 Memento 存储读取之前保存的数据',
  parameters: [
    {
      name: 'key',
      type: 'string',
      optional: false,
      description: '存储键名（会自动添加 "my_app_" 前缀）'
    }
  ],
  examples: [
    {
      code: `const result = await memento.tools.storage_get({ key: 'user_preference' });
setResult(result);`,
      comment: '读取用户偏好设置'
    },
    {
      code: `const result = await memento.tools.storage_get({ key: 'cache_data' });
if (result.value) {
  setResult('缓存数据长度: ' + result.value.length);
} else {
  setResult('未找到缓存数据');
}`,
      comment: '检查缓存数据是否存在'
    }
  ],
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

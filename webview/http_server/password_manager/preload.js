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

// 获取已注册的工具列表
const toolsResult = memento.listTools();
if (toolsResult.success) {
  console.log('已注册工具数量:', toolsResult.tools.length);
  console.log('已注册工具列表:', JSON.stringify(toolsResult.tools.map(t => t.id)));
} else {
  console.error('获取工具列表失败:', toolsResult.error);
}

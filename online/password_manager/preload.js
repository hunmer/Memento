/**
 * WebView 卡片预加载脚本
 *
 * 此文件在 QuickJS 引擎中执行，而非在 WebView 页面中
 * 通过调用 memento.registerTool() 注册特定于当前项目的自定义 JavaScript 工具
 * 注册的工具可以被 Agent Chat 直接调用，无需打开 WebView 页面
 *
 * 注意：Dart 端会在执行此脚本前验证 memento.registerTool 已存在
 * 因此无需在此脚本中轮询等待
 */

// 工具注册函数
function registerTools() {
  console.log('[Preload] 开始注册密码管理工具...');

  // 注册密码保存工具
  memento.registerTool({
  id: 'password_save',
  name: '保存密码',
  description: '将密码保存到 Memento 存储',
  parameters: [
    {
      name: 'name',
      type: 'string',
      optional: false,
      description: '密码条目名称（如：GitHub 账号）'
    },
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
      name: 'url',
      type: 'string',
      optional: true,
      description: '网站 URL（如：https://github.com）'
    },
    {
      name: 'category',
      type: 'string',
      optional: true,
      description: '分类名称'
    },
    {
      name: 'notes',
      type: 'string',
      optional: true,
      description: '备注信息'
    }
  ],
  examples: [
    {
      code: `const result = await memento.tools.password_save({
  name: 'GitHub 主账号',
  username: 'john_doe',
  password: 'my_password_123',
  url: 'https://github.com',
  category: '编程'
});
setResult(result);`,
      comment: '保存 GitHub 账号密码'
    },
    {
      code: `const result = await memento.tools.password_save({
  name: '邮箱',
  username: 'john@example.com',
  password: 'email_password'
});
setResult(result);`,
      comment: '保存邮箱密码'
    }
  ],
  code: `
    // 读取现有卡片数据
    const cardData = await memento.storage.readCardData('password_manager');
    const data = cardData || { passwords: [], updatedAt: new Date().toISOString() };

    // 生成唯一 ID
    const id = String(Date.now());
    const now = new Date().toISOString();

    // 添加新密码条目
    data.passwords.push({
      id: id,
      name: params.name,
      username: params.username,
      password: params.password,
      url: params.url || '',
      category: params.category || '',
      notes: params.notes || '',
      createdAt: now,
      updatedAt: now
    });
    data.updatedAt = now;

    // 保存回文件
    await memento.storage.writeCardData('password_manager', data);

    return {
      success: true,
      id: id,
      count: data.passwords.length,
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
      name: 'category',
      type: 'string',
      optional: true,
      description: '按分类筛选'
    }
  ],
  examples: [
    {
      code: `const result = await memento.tools.password_list();
setResult(result);`,
      comment: '获取所有密码'
    },
    {
      code: `const result = await memento.tools.password_list({ category: '编程' });
setResult('编程类密码数量: ' + result.passwords.length);`,
      comment: '获取指定分类的密码'
    }
  ],
  code: `
    // 从文件读取卡片数据
    const cardData = await memento.storage.readCardData('password_manager');

    if (!cardData || !cardData.passwords) {
      return {
        success: true,
        passwords: [],
        total: 0
      };
    }

    let passwords = cardData.passwords;

    // 如果指定了分类，进行筛选
    if (params.category) {
      passwords = passwords.filter(p => p.category === params.category);
    }

    return {
      success: true,
      passwords: passwords,
      total: passwords.length
    };
  `,
  cardId: 'password_manager'
});

// 注册密码搜索工具
memento.registerTool({
  id: 'password_search',
  name: '搜索密码',
  description: '根据网站、用户名或名称搜索密码',
  parameters: [
    {
      name: 'query',
      type: 'string',
      optional: false,
      description: '搜索关键词'
    }
  ],
  examples: [
    {
      code: `const result = await memento.tools.password_search({ query: 'github' });
setResult(result);`,
      comment: '搜索包含 "github" 的密码'
    },
    {
      code: `const result = await memento.tools.password_search({ query: 'john' });
setResult(result);`,
      comment: '搜索用户名包含 "john" 的密码'
    }
  ],
  code: `
    // 从文件读取卡片数据
    const cardData = await memento.storage.readCardData('password_manager');

    if (!cardData || !cardData.passwords) {
      return { success: true, passwords: [], total: 0 };
    }

    const query = (params.query || '').toLowerCase();

    const filtered = cardData.passwords.filter(p =>
      (p.name && p.name.toLowerCase().includes(query)) ||
      (p.url && p.url.toLowerCase().includes(query)) ||
      (p.username && p.username.toLowerCase().includes(query)) ||
      (p.category && p.category.toLowerCase().includes(query)) ||
      (p.notes && p.notes.toLowerCase().includes(query))
    );

    return {
      success: true,
      passwords: filtered,
      total: filtered.length
    };
  `,
  cardId: 'password_manager'
});

  console.log('[Preload] ✓ 密码管理工具注册完成');
  return true;
}

// 直接执行工具注册（Dart 端已确保 memento.registerTool 存在）
(function() {
  try {
    console.log('[Preload] 开始执行工具注册...');
    if (registerTools()) {
      console.log('[Preload] ✓ 所有工具注册成功');
    } else {
      console.log('[Preload] ✗ 工具注册失败');
    }
  } catch (error) {
    console.error('[Preload] 工具注册过程出错:', error.message);
  }
})();

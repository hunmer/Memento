# 测试 Memento JS API 的示例脚本

## 功能说明

这个示例脚本展示了如何在脚本中心的脚本中调用 Memento 的插件 API。

## 脚本目录结构

将以下文件放在 `<app_documents>/scripts/test_memento_api/` 目录下：

### metadata.json

```json
{
  "name": "测试 Memento API",
  "version": "1.0.0",
  "description": "测试调用 Memento 插件 API 的示例脚本",
  "icon": "bug_report",
  "author": "Memento Team",
  "updateUrl": null,
  "enabled": true,
  "type": "module",
  "triggers": []
}
```

### script.js

```javascript
// 测试 Memento API 脚本
(async function() {
  console.log('🚀 开始测试 Memento JS API...');

  // 1. 测试聊天插件 API
  try {
    console.log('\n=== 测试聊天插件 API ===');

    // 测试同步 API
    const syncTest = await Memento.chat.testSync();
    console.log('✅ 同步测试:', syncTest);

    // 获取所有频道
    const channels = await Memento.chat.getChannels();
    console.log('✅ 频道列表:', channels);

    // 获取当前用户
    const currentUser = await Memento.chat.getCurrentUser();
    console.log('✅ 当前用户:', currentUser);

    // 获取 AI 用户
    const aiUser = await Memento.chat.getAIUser();
    console.log('✅ AI 用户:', aiUser);

    // 如果有频道，获取第一个频道的消息
    if (channels && channels.length > 0) {
      const firstChannel = channels[0];
      const messages = await Memento.chat.getMessages(firstChannel.id);
      console.log(`✅ 频道 "${firstChannel.name}" 的消息数量:`, messages ? messages.length : 0);
    }

  } catch (error) {
    console.error('❌ 聊天插件 API 测试失败:', error);
  }

  // 2. 测试脚本互调
  try {
    console.log('\n=== 测试脚本互调 ===');

    // 如果你有其他脚本，可以这样调用
    // const result = await runScript('other_script_id', param1, param2);
    // console.log('✅ 脚本互调结果:', result);

    console.log('ℹ️ 脚本互调功能已就绪（需要其他脚本进行测试）');

  } catch (error) {
    console.error('❌ 脚本互调测试失败:', error);
  }

  // 3. 测试全局对象访问
  try {
    console.log('\n=== 测试全局对象 ===');

    // 检查 Memento 命名空间
    console.log('✅ Memento 版本:', Memento.version);
    console.log('✅ 已注册的插件:', Object.keys(Memento).filter(key => key !== 'version' && key !== 'plugins'));

  } catch (error) {
    console.error('❌ 全局对象测试失败:', error);
  }

  // 返回测试结果
  return {
    success: true,
    message: 'Memento JS API 测试完成',
    timestamp: new Date().toISOString(),
    testedAPIs: [
      'Memento.chat.testSync',
      'Memento.chat.getChannels',
      'Memento.chat.getCurrentUser',
      'Memento.chat.getAIUser',
      'Memento.chat.getMessages',
    ]
  };
})();
```

## 使用方法

1. 在手机/电脑上找到 Memento 的数据目录
2. 创建 `scripts/test_memento_api/` 目录
3. 将 `metadata.json` 和 `script.js` 文件放入该目录
4. 打开 Memento 应用，进入"脚本中心"
5. 找到"测试 Memento API"脚本
6. 点击"尝试运行"按钮
7. 查看执行结果和日志

## 预期输出

脚本执行后应该看到类似以下的日志：

```
🚀 开始测试 Memento JS API...

=== 测试聊天插件 API ===
✅ 同步测试: {"status":"ok","message":"同步测试成功！","timestamp":"2025-11-14T12:34:56.789Z"}
✅ 频道列表: [{"id":"channel1","name":"默认频道",...}]
✅ 当前用户: {"id":"user1","name":"我",...}
✅ AI 用户: {"id":"ai","name":"AI助手",...}
✅ 频道 "默认频道" 的消息数量: 10

=== 测试脚本互调 ===
ℹ️ 脚本互调功能已就绪（需要其他脚本进行测试）

=== 测试全局对象 ===
✅ Memento 版本: 1.0.0
✅ 已注册的插件: ["chat", "openai", "diary", ...]
```

## 可用的 API 列表

根据您的 Memento 版本和已安装的插件，可用的 API 可能有所不同。常见的 API 包括：

### 聊天插件 (Memento.chat.*)
- `testSync()` - 同步测试
- `getChannels()` - 获取所有频道
- `createChannel(name, type)` - 创建新频道
- `deleteChannel(channelId)` - 删除频道
- `sendMessage(channelId, content, type)` - 发送消息
- `getMessages(channelId)` - 获取频道消息
- `deleteMessage(messageId)` - 删除消息
- `getCurrentUser()` - 获取当前用户
- `getAIUser()` - 获取AI用户

### 脚本中心全局 API
- `runScript(scriptId, ...params)` - 执行其他脚本

### 其他插件
请查阅各插件的文档以了解它们提供的 JS API。

## 注意事项

1. **异步操作**：所有 API 调用都是异步的，必须使用 `await` 或 `.then()`
2. **错误处理**：始终使用 `try-catch` 包裹 API 调用
3. **返回值**：大多数 API 返回 JSON 格式的数据
4. **权限**：某些 API 可能需要特定的权限或条件才能正常工作
5. **兼容性**：不同版本的 Memento 可能提供不同的 API

## 扩展示例

### 示例 1: 创建频道并发送消息

```javascript
// 创建新频道
const newChannel = await Memento.chat.createChannel('测试频道', 'normal');
console.log('创建的频道:', newChannel);

// 发送消息到新频道
const message = await Memento.chat.sendMessage(
  newChannel.id,
  '这是通过脚本发送的消息！',
  'text'
);
console.log('发送的消息:', message);
```

### 示例 2: 批量处理频道消息

```javascript
// 获取所有频道
const channels = await Memento.chat.getChannels();

// 遍历每个频道
for (const channel of channels) {
  const messages = await Memento.chat.getMessages(channel.id);
  console.log(`频道 "${channel.name}" 有 ${messages.length} 条消息`);

  // 分析消息内容
  const textMessages = messages.filter(m => m.type === 'text');
  console.log(`  其中 ${textMessages.length} 条是文本消息`);
}
```

### 示例 3: 调用其他脚本

```javascript
// 假设有一个数据分析脚本
const analysisResult = await runScript('data_analyzer', {
  startDate: '2025-01-01',
  endDate: '2025-12-31'
});

console.log('数据分析结果:', analysisResult);

// 基于分析结果发送报告
if (analysisResult.success) {
  await Memento.chat.sendMessage(
    'report_channel',
    `数据分析完成：${JSON.stringify(analysisResult)}`,
    'text'
  );
}
```

## 故障排除

### 问题 1: API 调用返回 undefined
- **原因**：插件可能未注册 JS API
- **解决**：检查插件是否实现了 `JSBridgePlugin` mixin

### 问题 2: 脚本执行超时
- **原因**：API 调用时间过长（默认超时 5 秒）
- **解决**：减少 API 调用次数，或修改 ScriptExecutor 的超时设置

### 问题 3: 循环调用错误
- **原因**：脚本 A 调用脚本 B，脚本 B 又调用脚本 A
- **解决**：重新设计脚本调用关系，避免循环依赖

## 更新日志

- **v1.0.0** (2025-11-14): 初始版本，支持聊天插件 API 测试

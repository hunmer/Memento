# Memento JavaScript Bridge Mock - 快速参考

## 🚀 快速开始

### 1. 在 HTML 中引入
```html
<script src="memento_mock.js"></script>
<script>
  Memento.ready(() => {
    // Memento 已准备就绪
  });
</script>
```

### 2. 在浏览器中测试
直接在浏览器中打开 `test_memento_mock.html`

## 📋 常用代码片段

### 获取系统信息
```javascript
// 当前时间
const time = await Memento.system.getCurrentTime();

// 设备信息
const device = await Memento.system.getDeviceInfo();

// 时间戳
const timestamp = await Memento.system.getTimestamp();
```

### UI 交互
```javascript
// 短消息
Memento.ui.toast('操作成功！');

// 警告
Memento.ui.alert('确认删除吗？');

// 对话框
const result = await Memento.ui.dialog({
  title: '确认',
  message: '是否继续？',
  showCancel: true
});
```

### 数据存储
```javascript
// 保存（使用 localStorage，持久化存储）
await Memento.storage.write('user', { name: '张三' });

// 读取
const user = await Memento.storage.read('user');

// 删除
await Memento.storage.delete('user');

// 清空所有数据
await Memento.storage.clear();
```

### 调用插件
```javascript
// 日记插件
await Memento.plugins.diary.createEntry({
  title: '新日记',
  content: '内容...'
});

// 笔记插件
await Memento.plugins.notes.createNote({
  title: '新笔记',
  content: '内容...'
});

// 自定义插件
await Memento.plugins.myPlugin.myMethod({
  data: 'value'
});
```

## 🔧 调试工具

```javascript
// 查看所有存储
Memento.utils.getStorageState();

// 清空存储
Memento.utils.resetStorage();

// 日志记录
Memento.utils.log('调试信息');
Memento.utils.error('错误信息');
Memento.utils.warn('警告信息');
```

## ⚠️ 注意事项

1. **Mock 环境**：这是模拟环境，不是真实的 Flutter 插件调用
2. **localStorage 存储**：数据持久化保存在浏览器中，刷新页面不会丢失
3. **键前缀**：`MementoMock_` 前缀避免与其他脚本冲突
4. **异步操作**：所有 API 都是异步的，需要使用 `await` 或 `.then()`

## 📁 文件位置

- `memento_mock.js` - 核心 Mock 库
- `test_memento_mock.html` - 测试页面
- `README.md` - 完整文档
- `QUICK_REFERENCE.md` - 本文件

## 💡 提示

- 按 `F12` 打开浏览器控制台查看详细日志
- 在测试页面中查看实时 API 测试和存储状态
- 所有 API 返回的都是模拟数据，仅供开发测试使用

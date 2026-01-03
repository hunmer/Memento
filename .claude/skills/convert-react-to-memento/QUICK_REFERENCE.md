# React to Memento WebView - 快速参考

## 一键转换命令

```bash
# 基础转换
/convert-react-to-memento

# 指定应用名称
/convert-react-to-memento --name "我的应用"

# 指定权限
/convert-react-to-memento --permissions storage,diary,notes
```

## 核心 API 速查表

| 分类 | API | 说明 |
|------|-----|------|
| 系统 | `Memento.system.getCurrentTime()` | 获取当前时间 |
| 系统 | `Memento.system.getDeviceInfo()` | 获取设备信息 |
| 系统 | `Memento.system.getTimestamp()` | 获取时间戳 |
| UI | `Memento.ui.toast(msg)` | 显示提示消息 |
| UI | `Memento.ui.alert(msg)` | 显示警告对话框 |
| UI | `Memento.ui.dialog(options)` | 显示确认对话框 |
| 存储 | `Memento.storage.write(key, val)` | 写入数据 |
| 存储 | `Memento.storage.read(key)` | 读取数据 |
| 存储 | `Memento.storage.delete(key)` | 删除数据 |
| 存储 | `Memento.storage.clear()` | 清空存储 |
| 插件 | `Memento.plugins.xxx.yyy()` | 调用插件方法 |

## React 集成模板

### 1. 基础模板

```tsx
useEffect(() => {
  Memento.ready(async () => {
    const time = await Memento.system.getCurrentTime();
    console.log(time);
  });
}, []);
```

### 2. 自定义 Hook

```tsx
export function useMementoStorage<T>(key: string, initial: T) {
  const [data, setData] = useState<T>(initial);

  useEffect(() => {
    Memento.ready(async () => {
      const stored = await Memento.storage.read(key);
      if (stored) setData(stored);
    });
  }, [key]);

  const save = async (value: T) => {
    setData(value);
    await Memento.storage.write(key, value);
  };

  return [data, save] as const;
}
```

### 3. Toast 提示

```tsx
const handleSuccess = async () => {
  await Memento.ui.toast('操作成功！');
};
```

### 4. 确认对话框

```tsx
const handleDelete = async () => {
  const { confirmed } = await Memento.ui.dialog({
    title: '确认删除',
    message: '删除后无法恢复',
    showCancel: true
  });

  if (confirmed) {
    // 执行删除
  }
};
```

### 5. 存储操作

```tsx
// 保存
await Memento.storage.write('user', { name: '张三', age: 30 });

// 读取
const user = await Memento.storage.read('user');

// 删除
await Memento.storage.delete('user');
```

## 项目文件结构

```
my-app/
├── index.html          # 添加 memento_mock.js 引用
├── metadata.json       # Memento 应用元数据
├── memento.d.ts        # TypeScript 类型定义
├── src/
│   ├── App.tsx
│   └── hooks/
│       └── useMemento.ts  # 自定义 Memento Hooks
└── package.json
```

## metadata.json 示例

```json
{
  "name": "我的应用",
  "description": "应用描述",
  "requestFramePermissions": [
    "storage",
    "diary"
  ]
}
```

## 常用权限列表

| 权限 | 说明 |
|------|------|
| `storage` | 本地存储 |
| `diary` | 日记插件 |
| `notes` | 笔记插件 |
| `notification` | 通知 |
| `location` | 位置 |
| `camera` | 相机 |

## 调试命令

```javascript
// 控制台中执行
Memento.utils.getStorageState()  // 查看所有存储
Memento.utils.resetStorage()     // 清空存储
await Memento.system.getDeviceInfo()  // 查看设备信息
```

## 常见问题

**Q: API 调用报错？**
A: 确保在 `Memento.ready()` 回调中调用

**Q: TypeScript 报错？**
A: 确保 `memento.d.ts` 文件存在

**Q: 存储数据丢失？**
A: 检查数据是否可 JSON 序列化

**Q: Mock 不工作？**
A: 确认 `memento_mock.js` 已在 index.html 中引入

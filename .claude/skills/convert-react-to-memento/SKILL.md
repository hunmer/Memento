---
skill_name: convert-react-to-memento
description: 将 React 应用快速转换为适用于 Memento 加载的 WebView 应用。支持 Vite、Webpack 等构建工具，自动配置 Memento Mock 环境、类型定义和元数据。
details: |
  此 skill 将自动为 React 应用添加 Memento WebView 集成所需的配置。

  功能特性：
  - 配置 Memento Mock 开发环境（使用 npm 包）
  - 创建/更新 metadata.json 元数据配置
  - 添加 Memento TypeScript 类型定义
  - 配置 Tailwind CSS v4（npm 包，非 CDN）
  - 配置本地字体（@fontsource）
  - 提供 Memento API 使用模板
  - 集成 Memento storage、ui、plugins 等 API
  - 支持开发环境的 Mock 测试

  使用场景：
  - 将现有 React 应用改造为 Memento WebView 应用
  - 创建新的 Memento WebView React 应用
  - 添加 Memento 原生功能集成（存储、UI、插件）
---

# React to Memento WebView 转换 Skill

## 工作流程

1. **分析现有项目**
   - 检测项目类型（Vite/Webpack/CRA）
   - 识别 index.html 入口文件
   - 检查是否已有 Memento 配置
   - 分析 package.json 依赖
   - 检查 Tailwind CSS 使用方式（CDD 还是 npm）
   - 检查字体配置方式

2. **询问用户需求**
   - 应用名称和描述
   - 需要哪些 Memento API 功能？
   - 是否需要权限申请？
   - 是否需要插件集成？
   - 是否使用 Tailwind CSS？
   - 需要使用哪些字体？

3. **配置 Memento Mock**
   - 安装 `memento-mock` npm 包
   - 在 index.tsx 中动态加载 Mock（开发环境）

4. **配置 Tailwind CSS（可选）**
   - 从 CDN 迁移到 npm 包
   - 配置 Tailwind CSS v4
   - 创建 PostCSS 配置

5. **配置本地字体（可选）**
   - 安装 @fontsource 字体包
   - 移除 Google Fonts 外部链接
   - 配置 CSS 导入本地字体

6. **创建/更新 metadata.json**
   配置应用元数据和权限

7. **添加类型定义**
   创建 memento.d.ts TypeScript 定义文件

8. **提供集成代码模板**
   根据用户需求提供相应的代码示例

## Memento API 快速参考

### 系统 API

```typescript
// 获取当前时间
const time = await Memento.system.getCurrentTime();

// 获取设备信息
const device = await Memento.system.getDeviceInfo();

// 获取应用信息
const appInfo = await Memento.system.getAppInfo();

// 格式化日期
const formatted = await Memento.system.formatDate({
  date: '2024-01-01',
  format: 'YYYY-MM-DD HH:mm:ss'
});

// 获取时间戳
const timestamp = await Memento.system.getTimestamp();

// 获取自定义日期（相对天数）
const customDate = await Memento.system.getCustomDate({ days: 7 });
```

### UI API

```typescript
// 显示 Toast 消息
await Memento.ui.toast('操作成功！', { duration: 3000 });

// 显示 Alert 警告
await Memento.ui.alert('确认删除吗？');

// 显示对话框
const result = await Memento.ui.dialog({
  title: '确认',
  message: '是否继续？',
  showCancel: true
});
// result.confirmed: boolean
```

### 存储 API

```typescript
// 写入数据（支持任意类型，JSON 序列化）
await Memento.storage.write('user', { name: '张三', age: 30 });

// 读取数据
const user = await Memento.storage.read('user');

// 删除数据
await Memento.storage.delete('user');

// 清空所有存储
await Memento.storage.clear();

// 获取所有键
const keys = await Memento.storage.keys();
```

### 插件 API

```typescript
// 日记插件
await Memento.plugins.diary.createEntry({
  title: '新日记',
  content: '日记内容...',
  tags: ['JavaScript', 'Memento']
});

// 笔记插件
await Memento.plugins.notes.createNote({
  title: '新笔记',
  content: '笔记内容...'
});

// 自定义插件
await Memento.plugins.myPlugin.myMethod({
  param1: 'value1',
  param2: 'value2'
});
```

### 工具函数

```typescript
// 获取存储状态
const state = Memento.utils.getStorageState();

// 重置存储
await Memento.utils.resetStorage();

// 日志记录
Memento.utils.log('调试信息');
Memento.utils.error('错误信息');
Memento.utils.warn('警告信息');
```

## 项目配置步骤

### 1. 配置 Memento Mock

**安装依赖：**
```bash
pnpm add -D memento-mock
```

**在 index.tsx 中动态加载 Mock（推荐）：**

```tsx
import React from 'react';
import ReactDOM from 'react-dom/client';
import App from './App';

// 仅在开发环境加载 Memento Mock
if (import.meta.env.DEV && typeof window.Memento === 'undefined') {
  import('memento-mock').then((module) => {
    module.default(); // 手动初始化
    console.log('Memento Mock loaded');

    const rootElement = document.getElementById('root');
    if (!rootElement) {
      throw new Error("Could not find root element to mount to");
    }
    const root = ReactDOM.createRoot(rootElement);
    root.render(
      <React.StrictMode>
        <App />
      </React.StrictMode>
    );
  });
} else {
  // 生产环境或 Memento 已存在
  const rootElement = document.getElementById('root');
  if (!rootElement) {
    throw new Error("Could not find root element to mount to");
  }
  const root = ReactDOM.createRoot(rootElement);
  root.render(
    <React.StrictMode>
      <App />
    </React.StrictMode>
  );
}
```

**配置环境变量（.env.local）：**
```env
VITE_GEMINI_API_KEY=your_api_key_here
```

### 2. 配置 Tailwind CSS v4（从 CDN 迁移到 npm）

**安装依赖：**
```bash
pnpm add -D tailwindcss @tailwindcss/postcss postcss autoprefixer
```

**创建 postcss.config.js：**
```javascript
export default {
  plugins: {
    '@tailwindcss/postcss': {},
  },
}
```

**创建 index.css（使用 Tailwind v4 语法）：**
```css
@import "tailwindcss";

@theme {
  --font-family-roboto: 'Roboto', sans-serif;
  --color-surface: #fdfcff;
}

/* 自定义样式 */
body {
  font-family: var(--font-family-roboto);
  background-color: var(--color-surface);
}
```

**在 index.tsx 中引入 CSS：**
```tsx
import './index.css';
```

**从 index.html 移除 CDN 引用：**
```html
<!-- 移除这一行 -->
<script src="https://cdn.tailwindcss.com"></script>
```

### 3. 配置本地字体（使用 @fontsource）

**安装字体包：**
```bash
pnpm add @fontsource/roboto
```

**在 index.css 中导入字体：**
```css
@import "tailwindcss";
/* 导入本地 Roboto 字体 */
@import "@fontsource/roboto/400.css";
@import "@fontsource/roboto/500.css";
@import "@fontsource/roboto/700.css";

@theme {
  --font-family-roboto: 'Roboto', sans-serif;
}
```

**从 index.html 移除 Google Fonts 引用：**
```html
<!-- 移除这一行 -->
<link href="https://fonts.googleapis.com/css2?family=Roboto:wght@400;500;700&display=swap" rel="stylesheet">
```

**常用字体包：**
- `@fontsource/roboto` - Roboto 字体
- `@fontsource/inter` - Inter 字体
- `@fontsource/noto-sans-sc` - 思源黑体（中文）
- `@fontsource/material-icons` - Material Icons

### 4. 更新 index.html（Vite 项目）

```html
<!DOCTYPE html>
<html lang="zh-CN">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=0" />
    <title>应用名称</title>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/index.tsx"></script>
  </body>
</html>
```

**注意：** Memento Mock 现在通过 index.tsx 动态加载，不需要在 index.html 中引用。

### 5. 创建 metadata.json

```json
{
  "name": "应用名称",
  "description": "应用描述",
  "requestFramePermissions": []
}
```

### 6. 创建 memento.d.ts

```typescript
declare global {
  interface Window {
    Memento: {
      ready: (callback: () => void) => void;
      _ready: boolean;

      system: {
        getCurrentTime: () => Promise<string>;
        getDeviceInfo: () => Promise<Record<string, any>>;
        getAppInfo: () => Promise<Record<string, any>>;
        formatDate: (params: { date: string; format: string }) => Promise<string>;
        getTimestamp: () => Promise<number>;
        getCustomDate: (params: { days: number }) => Promise<string>;
      };

      ui: {
        toast: (message: string, options?: { duration?: number }) => Promise<void>;
        alert: (message: string) => Promise<void>;
        dialog: (options: {
          title: string;
          message: string;
          showCancel?: boolean;
        }) => Promise<{ confirmed: boolean }>;
      };

      storage: {
        write: (key: string, value: any) => Promise<void>;
        read: (key: string) => Promise<any>;
        delete: (key: string) => Promise<void>;
        clear: () => Promise<void>;
        keys: () => Promise<string[]>;
      };

      plugins: Record<string, Record<string, (...args: any[]) => Promise<any>>>;

      utils: {
        getStorageState: () => Record<string, any>;
        resetStorage: () => Promise<void>;
        log: (message: string) => void;
        error: (message: string) => void;
        warn: (message: string) => void;
      };
    };
  }
}

export {};
```

## 代码模板

### 模板 1: React 组件中使用 Memento

```tsx
import { useEffect, useState } from 'react';

function App() {
  const [deviceInfo, setDeviceInfo] = useState<any>(null);
  const [currentTime, setCurrentTime] = useState<string>('');

  useEffect(() => {
    // 等待 Memento 准备就绪
    Memento.ready(async () => {
      // 获取设备信息
      const device = await Memento.system.getDeviceInfo();
      setDeviceInfo(device);

      // 获取当前时间
      const time = await Memento.system.getCurrentTime();
      setCurrentTime(time);

      // 显示欢迎消息
      await Memento.ui.toast('欢迎使用 Memento！');
    });
  }, []);

  const handleSave = async () => {
    // 保存数据
    await Memento.storage.write('userSettings', {
      theme: 'dark',
      language: 'zh-CN'
    });
    await Memento.ui.toast('设置已保存！');
  };

  const handleLoad = async () => {
    // 读取数据
    const settings = await Memento.storage.read('userSettings');
    console.log('用户设置:', settings);
  };

  return (
    <div className="p-4">
      <h1>Memento React 应用</h1>
      {deviceInfo && (
        <div>
          <p>设备: {deviceInfo.model}</p>
          <p>系统: {deviceInfo.platform}</p>
        </div>
      )}
      <p>当前时间: {currentTime}</p>
      <button onClick={handleSave}>保存设置</button>
      <button onClick={handleLoad}>加载设置</button>
    </div>
  );
}

export default App;
```

### 模板 2: 使用自定义 Hook

```tsx
// hooks/useMemento.ts
import { useEffect, useState } from 'react';

export function useMemento() {
  const [isReady, setIsReady] = useState(false);

  useEffect(() => {
    Memento.ready(() => {
      setIsReady(true);
    });
  }, []);

  return { isReady };
}

export function useMementoStorage<T>(key: string, initialValue: T) {
  const [data, setData] = useState<T>(initialValue);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    Memento.ready(async () => {
      const stored = await Memento.storage.read(key);
      if (stored !== undefined) {
        setData(stored);
      }
      setIsLoading(false);
    });
  }, [key]);

  const setStoredData = async (newValue: T) => {
    setData(newValue);
    await Memento.storage.write(key, newValue);
  };

  return { data, setData: setStoredData, isLoading };
}
```

使用 Hook：

```tsx
import { useMemento, useMementoStorage } from './hooks/useMemento';

function Settings() {
  const { isReady } = useMemento();
  const { data: settings, setData: setSettings } = useMementoStorage('settings', {
    theme: 'light'
  });

  if (!isReady) return <div>加载中...</div>;

  return (
    <div>
      <button onClick={() => setSettings({ theme: 'dark' })}>
        切换到深色模式
      </button>
      <p>当前主题: {settings.theme}</p>
    </div>
  );
}
```

### 模板 3: 调用日记插件

```tsx
import { useState } from 'react';

function DiaryEntry() {
  const [title, setTitle] = useState('');
  const [content, setContent] = useState('');

  const handleSubmit = async () => {
    try {
      await Memento.plugins.diary.createEntry({
        title,
        content,
        tags: ['React', 'WebView']
      });
      await Memento.ui.toast('日记创建成功！');
      setTitle('');
      setContent('');
    } catch (error) {
      await Memento.ui.alert('创建失败: ' + error);
    }
  };

  return (
    <div className="p-4">
      <input
        type="text"
        value={title}
        onChange={(e) => setTitle(e.target.value)}
        placeholder="标题"
        className="w-full p-2 border rounded"
      />
      <textarea
        value={content}
        onChange={(e) => setContent(e.target.value)}
        placeholder="内容"
        className="w-full p-2 border rounded mt-2"
        rows={5}
      />
      <button
        onClick={handleSubmit}
        className="mt-2 px-4 py-2 bg-blue-500 text-white rounded"
      >
        保存日记
      </button>
    </div>
  );
}
```

### 模板 4: 对话框确认

```tsx
function DeleteButton({ onDelete }: { onDelete: () => void }) {
  const handleDelete = async () => {
    const result = await Memento.ui.dialog({
      title: '确认删除',
      message: '删除后无法恢复，是否继续？',
      showCancel: true
    });

    if (result.confirmed) {
      onDelete();
      await Memento.ui.toast('已删除');
    }
  };

  return (
    <button onClick={handleDelete} className="text-red-500">
      删除
    </button>
  );
}
```

### 模板 5: 完整的应用结构

```tsx
import { useEffect, useState } from 'react';
import { useMementoStorage } from './hooks/useMemento';

interface TodoItem {
  id: number;
  text: string;
  completed: boolean;
}

function TodoApp() {
  const { isReady } = useMemento();
  const { data: todos, setData: setTodos } = useMementoStorage<TodoItem[]>('todos', []);
  const [inputValue, setInputValue] = useState('');

  const addTodo = async () => {
    if (!inputValue.trim()) return;
    const newTodos = [...todos, {
      id: Date.now(),
      text: inputValue,
      completed: false
    }];
    setTodos(newTodos);
    setInputValue();
    await Memento.ui.toast('已添加');
  };

  const toggleTodo = async (id: number) => {
    const newTodos = todos.map(todo =>
      todo.id === id ? { ...todo, completed: !todo.completed } : todo
    );
    setTodos(newTodos);
  };

  const deleteTodo = async (id: number) => {
    const result = await Memento.ui.dialog({
      title: '确认',
      message: '删除此待办？',
      showCancel: true
    });

    if (result.confirmed) {
      const newTodos = todos.filter(todo => todo.id !== id);
      setTodos(newTodos);
      await Memento.ui.toast('已删除');
    }
  };

  if (!isReady) return <div className="p-4">正在初始化...</div>;

  return (
    <div className="p-4 max-w-md mx-auto">
      <h1 className="text-2xl font-bold mb-4">待办事项</h1>

      <div className="flex gap-2 mb-4">
        <input
          type="text"
          value={inputValue}
          onChange={(e) => setInputValue(e.target.value)}
          onKeyPress={(e) => e.key === 'Enter' && addTodo()}
          placeholder="添加待办..."
          className="flex-1 p-2 border rounded"
        />
        <button
          onClick={addTodo}
          className="px-4 py-2 bg-blue-500 text-white rounded"
        >
          添加
        </button>
      </div>

      <ul className="space-y-2">
        {todos.map(todo => (
          <li
            key={todo.id}
            className={`p-3 border rounded flex items-center gap-2 ${
              todo.completed ? 'bg-gray-100' : 'bg-white'
            }`}
          >
            <input
              type="checkbox"
              checked={todo.completed}
              onChange={() => toggleTodo(todo.id)}
              className="w-4 h-4"
            />
            <span className={todo.completed ? 'line-through text-gray-500' : ''}>
              {todo.text}
            </span>
            <button
              onClick={() => deleteTodo(todo.id)}
              className="ml-auto text-red-500"
            >
              删除
            </button>
          </li>
        ))}
      </ul>

      {todos.length === 0 && (
        <p className="text-center text-gray-500 mt-8">
          暂无待办事项
        </p>
      )}
    </div>
  );
}

export default TodoApp;
```

## 权限配置

在 `metadata.json` 中配置所需权限：

```json
{
  "name": "我的应用",
  "description": "应用描述",
  "requestFramePermissions": [
    "storage",
    "diary",
    "notes",
    "notification"
  ]
}
```

常用权限：
- `storage` - 本地存储
- `diary` - 日记插件
- `notes` - 笔记插件
- `notification` - 通知
- `location` - 位置信息
- `camera` - 相机
- `microphone` - 麦克风

## 调试技巧

1. **使用 Mock 环境测试**
   ```html
   <script src="/memento_mock.js"></script>
   ```
   在浏览器中直接测试，无需启动 Memento 应用

2. **控制台调试**
   ```javascript
   // 查看所有存储
   Memento.utils.getStorageState()

   // 清空存储
   await Memento.utils.resetStorage()

   // 查看设备信息
   await Memento.system.getDeviceInfo()
   ```

3. **React DevTools**
   配合 React DevTools 查看组件状态和 Memento 数据

4. **日志输出**
   ```typescript
   Memento.utils.log('调试信息');
   Memento.utils.error('错误信息');
   ```

## 注意事项

1. **Memento Mock 配置**
   - 使用 `memento-mock` npm 包，而非外部脚本文件
   - 在 index.tsx 中通过 `import.meta.env.DEV` 条件加载
   - 生产环境不会加载 Mock 代码

2. **Memento.ready()**
   - 所有 Memento API 调用前必须等待 `Memento.ready()`
   - 可以多次调用，回调只执行一次

3. **Tailwind CSS 配置**
   - 优先使用 npm 包而非 CDN
   - Tailwind v4 使用 `@import "tailwindcss"` 语法
   - 使用 `@theme` 定义主题变量
   - 需要 PostCSS 配置 `@tailwindcss/postcss` 插件

4. **字体配置**
   - 优先使用 `@fontsource` 包，避免外部字体请求
   - 移除 Google Fonts 的 `<link>` 引用
   - 在 CSS 中通过 `@import` 导入字体文件

5. **异步操作**
   - 所有 Memento API 都是异步的，需要使用 `await` 或 `.then()`

6. **存储限制**
   - 存储数据会被 JSON 序列化
   - 不支持存储函数、Symbol 等特殊类型
   - 注意存储空间限制

7. **类型安全**
   - 使用 TypeScript 定义确保类型安全
   - 调用插件时注意参数和返回值类型

8. **Mock 与生产环境**
   - Mock 环境使用 localStorage
   - 生产环境使用原生存储
   - 通过环境变量控制 Mock 加载

## 执行步骤

当用户请求转换 React 应用时：

1. 读取并分析项目结构
2. 询问用户应用信息和需求
3. 配置 Memento Mock（安装 npm 包，更新 index.tsx）
4. 如需要，配置 Tailwind CSS（安装依赖，创建配置文件）
5. 如需要，配置本地字体（安装 @fontsource，更新 CSS）
6. 创建/更新 metadata.json
7. 创建 memento.d.ts 类型定义文件
8. 提供 Memento API 集成代码示例
9. 说明测试和部署注意事项

## 检查清单

转换完成后验证：

**Memento 配置：**
- [ ] package.json 包含 memento-mock 依赖
- [ ] index.tsx 包含条件加载 Mock 的代码
- [ ] metadata.json 配置正确
- [ ] memento.d.ts 类型定义存在
- [ ] Memento.ready() 在 API 调用前执行
- [ ] 开发环境能正常使用 Mock API

**Tailwind CSS 配置（如使用）：**
- [ ] package.json 包含 tailwindcss、@tailwindcss/postcss、postcss、autoprefixer
- [ ] postcss.config.js 配置正确
- [ ] index.css 使用 @import "tailwindcss" 语法
- [ ] index.html 移除了 CDN 引用

**字体配置（如使用本地字体）：**
- [ ] package.json 包含 @fontsource/* 字体包
- [ ] index.css 导入了本地字体
- [ ] index.html 移除了 Google Fonts 引用

**通用检查：**
- [ ] TypeScript 类型检查通过
- [ ] 开发构建正常
- [ ] 生产构建正常
- [ ] 生产环境不包含 Mock 代码

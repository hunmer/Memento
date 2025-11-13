# Notes 插件 JS API 文档

## 概述

Notes 插件已集成 JS Bridge 功能,支持通过 JavaScript 调用笔记和文件夹管理的核心功能。

## API 列表

### 测试 API

#### `notes.testSync()`

测试 JS API 是否正常工作（同步方法）。

**返回值**:
```json
{
  "status": "ok",
  "message": "笔记插件 JS API 测试成功！",
  "timestamp": "2025-01-15T10:30:00.000Z",
  "plugin": "notes"
}
```

---

## 笔记相关 API

### `notes.getNotes([folderId])`

获取笔记列表。

**参数**:
- `folderId` (可选): 文件夹 ID,不传则返回所有笔记

**返回值**: 笔记对象数组的 JSON 字符串
```json
[
  {
    "id": "1234567890123",
    "title": "项目计划",
    "content": "# 项目计划\n\n本周目标:\n- 完成设计稿",
    "folderId": "1234567890",
    "createdAt": "2025-01-15T08:30:00.000Z",
    "updatedAt": "2025-01-15T20:15:00.000Z",
    "tags": ["工作", "计划"]
  }
]
```

**示例**:
```javascript
// 获取所有笔记
const allNotes = await notes.getNotes();

// 获取指定文件夹的笔记
const folderNotes = await notes.getNotes('1234567890');
```

---

### `notes.getNote(noteId)`

获取单个笔记详情。

**参数**:
- `noteId`: 笔记 ID

**返回值**: 笔记对象的 JSON 字符串

**示例**:
```javascript
const note = await notes.getNote('1234567890123');
console.log(JSON.parse(note).title); // "项目计划"
```

---

### `notes.createNote(title, content, [folderId], [tags])`

创建新笔记。

**参数**:
- `title`: 笔记标题
- `content`: 笔记内容（支持 Markdown）
- `folderId` (可选): 文件夹 ID,默认为 'root'
- `tags` (可选): 标签数组

**返回值**: 创建的笔记对象的 JSON 字符串

**示例**:
```javascript
// 创建基础笔记
const note1 = await notes.createNote(
  '每日总结',
  '# 今日完成\n\n- 任务1\n- 任务2'
);

// 创建带标签的笔记
const note2 = await notes.createNote(
  '会议记录',
  '# 产品会议\n\n讨论内容...',
  'work_folder_id',
  ['会议', '产品']
);
```

---

### `notes.updateNote(noteId, title, content, [tags])`

更新笔记。

**参数**:
- `noteId`: 笔记 ID
- `title`: 新标题
- `content`: 新内容
- `tags` (可选): 新标签数组

**返回值**: 更新后的笔记对象的 JSON 字符串

**示例**:
```javascript
const updatedNote = await notes.updateNote(
  '1234567890123',
  '项目计划 (已更新)',
  '# 项目计划\n\n本周目标:\n- 完成设计稿\n- 开发核心功能',
  ['工作', '计划', '重要']
);
```

---

### `notes.deleteNote(noteId)`

删除笔记。

**参数**:
- `noteId`: 笔记 ID

**返回值**: `true` 表示成功,`false` 表示失败

**示例**:
```javascript
const success = await notes.deleteNote('1234567890123');
if (success) {
  console.log('笔记删除成功');
}
```

---

### `notes.searchNotes(keyword, [tags], [startDate], [endDate])`

搜索笔记。

**参数**:
- `keyword`: 搜索关键词（标题或内容匹配）
- `tags` (可选): 标签数组（任一标签匹配即可）
- `startDate` (可选): 开始日期（ISO 8601 格式字符串）
- `endDate` (可选): 结束日期（ISO 8601 格式字符串）

**返回值**: 匹配的笔记对象数组的 JSON 字符串

**示例**:
```javascript
// 搜索标题或内容包含"项目"的笔记
const results1 = await notes.searchNotes('项目');

// 搜索带"工作"标签的笔记
const results2 = await notes.searchNotes('', ['工作']);

// 搜索本周创建的笔记
const results3 = await notes.searchNotes(
  '',
  null,
  '2025-01-13T00:00:00Z',
  '2025-01-20T23:59:59Z'
);

// 组合搜索：关键词 + 标签 + 日期范围
const results4 = await notes.searchNotes(
  '会议',
  ['工作', '产品'],
  '2025-01-01T00:00:00Z',
  '2025-01-31T23:59:59Z'
);
```

---

## 文件夹相关 API

### `notes.getFolders()`

获取所有文件夹。

**返回值**: 文件夹对象数组的 JSON 字符串
```json
[
  {
    "id": "root",
    "name": "Root",
    "parentId": null,
    "createdAt": "2025-01-15T10:30:00.000Z",
    "updatedAt": "2025-01-15T10:30:00.000Z",
    "color": 4280391411,
    "icon": 57415
  },
  {
    "id": "1234567890",
    "name": "工作笔记",
    "parentId": "root",
    "createdAt": "2025-01-16T09:00:00.000Z",
    "updatedAt": "2025-01-16T09:00:00.000Z",
    "color": 4280391411,
    "icon": 57415
  }
]
```

**示例**:
```javascript
const folders = await notes.getFolders();
const folderList = JSON.parse(folders);
console.log(`共有 ${folderList.length} 个文件夹`);
```

---

### `notes.getFolder(folderId)`

获取单个文件夹详情。

**参数**:
- `folderId`: 文件夹 ID

**返回值**: 文件夹对象的 JSON 字符串

**示例**:
```javascript
const folder = await notes.getFolder('1234567890');
console.log(JSON.parse(folder).name); // "工作笔记"
```

---

### `notes.createFolder(name, [parentId])`

创建新文件夹。

**参数**:
- `name`: 文件夹名称
- `parentId` (可选): 父文件夹 ID,不传则在根目录下创建

**返回值**: 创建的文件夹对象的 JSON 字符串

**示例**:
```javascript
// 在根目录下创建文件夹
const folder1 = await notes.createFolder('个人笔记');

// 创建子文件夹
const folder2 = await notes.createFolder('项目A', 'work_folder_id');
```

---

### `notes.renameFolder(folderId, newName)`

重命名文件夹。

**参数**:
- `folderId`: 文件夹 ID
- `newName`: 新名称

**返回值**: `true` 表示成功,`false` 表示失败

**示例**:
```javascript
const success = await notes.renameFolder('1234567890', '工作笔记 2025');
```

---

### `notes.deleteFolder(folderId)`

删除文件夹（递归删除子文件夹和笔记）。

**参数**:
- `folderId`: 文件夹 ID

**返回值**: `true` 表示成功,`false` 表示失败

**警告**: 此操作会递归删除文件夹下的所有子文件夹和笔记,无法撤销!

**示例**:
```javascript
const success = await notes.deleteFolder('old_folder_id');
```

---

### `notes.getFolderNotes(folderId)`

获取文件夹中的笔记（不包括子文件夹的笔记）。

**参数**:
- `folderId`: 文件夹 ID

**返回值**: 笔记对象数组的 JSON 字符串

**示例**:
```javascript
const notes = await notes.getFolderNotes('work_folder_id');
const noteList = JSON.parse(notes);
console.log(`该文件夹有 ${noteList.length} 条笔记`);
```

---

### `notes.moveNote(noteId, targetFolderId)`

移动笔记到其他文件夹。

**参数**:
- `noteId`: 笔记 ID
- `targetFolderId`: 目标文件夹 ID

**返回值**: `true` 表示成功,`false` 表示失败

**示例**:
```javascript
const success = await notes.moveNote('note123', 'new_folder_id');
```

---

## 使用场景示例

### 场景 1: 每日自动创建笔记

```javascript
// 自动生成今日日期的笔记
const today = new Date().toISOString().split('T')[0];
const note = await notes.createNote(
  `每日总结 - ${today}`,
  `# ${today}\n\n## 今日完成\n\n- \n\n## 明日计划\n\n- `,
  'daily_folder_id',
  ['每日总结']
);
console.log('今日笔记已创建:', JSON.parse(note).id);
```

---

### 场景 2: 批量标记笔记

```javascript
// 搜索所有包含"重要"的笔记,并添加"高优先级"标签
const importantNotes = await notes.searchNotes('重要');
const noteList = JSON.parse(importantNotes);

for (const note of noteList) {
  const tags = note.tags || [];
  if (!tags.includes('高优先级')) {
    tags.push('高优先级');
    await notes.updateNote(note.id, note.title, note.content, tags);
  }
}
console.log(`已为 ${noteList.length} 条笔记添加标签`);
```

---

### 场景 3: 文件夹统计

```javascript
// 统计每个文件夹的笔记数量
const folders = JSON.parse(await notes.getFolders());
const stats = {};

for (const folder of folders) {
  const folderNotes = JSON.parse(await notes.getFolderNotes(folder.id));
  stats[folder.name] = folderNotes.length;
}

console.log('文件夹笔记统计:', stats);
// 输出: { "工作笔记": 23, "个人笔记": 15, ... }
```

---

### 场景 4: 笔记归档

```javascript
// 将 30 天前的笔记移动到归档文件夹
const thirtyDaysAgo = new Date();
thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

// 创建归档文件夹（如果不存在）
const archiveFolder = await notes.createFolder('归档');
const archiveFolderId = JSON.parse(archiveFolder).id;

// 搜索旧笔记
const oldNotes = await notes.searchNotes(
  '',
  null,
  null,
  thirtyDaysAgo.toISOString()
);

const noteList = JSON.parse(oldNotes);
for (const note of noteList) {
  await notes.moveNote(note.id, archiveFolderId);
}

console.log(`已归档 ${noteList.length} 条笔记`);
```

---

## 错误处理

所有 API 在插件未初始化时会返回错误对象:

```json
{
  "error": "插件未初始化"
}
```

部分 API（如 `getNote`, `getFolder`）在资源不存在时会抛出异常,建议使用 try-catch:

```javascript
try {
  const note = await notes.getNote('invalid_id');
  console.log(JSON.parse(note));
} catch (error) {
  console.error('获取笔记失败:', error.message);
}
```

---

## 注意事项

1. **异步操作**: 所有 API 方法都是异步的（除了 `testSync`）,需要使用 `await` 或 Promise
2. **JSON 序列化**: 所有返回值都是 JSON 字符串,需要使用 `JSON.parse()` 解析
3. **日期格式**: 日期参数使用 ISO 8601 格式（如 `2025-01-15T10:30:00.000Z`）
4. **文件夹层级**: 支持无限层级嵌套,通过 `parentId` 建立关系
5. **标签匹配**: `searchNotes` 中的标签过滤是"或"逻辑,任一标签匹配即可
6. **删除警告**: `deleteFolder` 会递归删除所有子内容,操作不可逆

---

## 调试建议

### 测试连接

```javascript
// 先测试 JS API 是否可用
const result = notes.testSync();
console.log('测试结果:', JSON.parse(result));
```

### 查看所有数据

```javascript
// 查看所有文件夹
const folders = JSON.parse(await notes.getFolders());
console.log('文件夹列表:', folders);

// 查看所有笔记
const allNotes = JSON.parse(await notes.getNotes());
console.log('笔记列表:', allNotes);
```

---

**最后更新**: 2025-01-15
**插件版本**: notes v1.0
**API 数量**: 13 个方法

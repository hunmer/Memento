# JavaScript Bridge API 文档

## 概述

Memento 提供了一套 JavaScript Bridge API，允许 JavaScript 代码与 Flutter 原生 UI 进行交互。

## 安装与设置

### 1. 在 Flutter 端注册 UI 处理器

```dart
import 'package:memento/core/js_bridge/js_bridge.dart';
import 'package:memento/core/js_bridge/js_ui_handlers.dart';

// 在你的 Widget 中
class MyWidget extends StatefulWidget {
  @override
  _MyWidgetState createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  late JSBridge _jsBridge;

  @override
  void initState() {
    super.initState();
    _initJSBridge();
  }

  Future<void> _initJSBridge() async {
    _jsBridge = JSBridge();
    await _jsBridge.initialize();

    // 注册 UI 处理器（在 build 之后注册，确保有 context）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uiHandlers = JSUIHandlers(context);
      if (_jsBridge.engine is MobileJSEngine) {
        uiHandlers.register(_jsBridge.engine as MobileJSEngine);
      }
    });
  }

  // ... 其他代码
}
```

### 2. 在 JavaScript 中使用

注册完成后，JavaScript 代码中会自动提供 `flutter` 全局对象。

---

## API 参考

### 1. Toast - 轻量级提示

#### 基本用法

```javascript
// 显示简单提示
flutter.toast('操作成功')
```

#### 带选项

```javascript
flutter.toast('已保存', {
  duration: 'long',   // 'short' | 'long' | 数字(毫秒)
  gravity: 'top'      // 'top' | 'center' | 'bottom'
})
```

#### 参数说明

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `message` | string | *必填* | 提示内容 |
| `options.duration` | string \| number | `'short'` | 显示时长<br>- `'short'`: 2秒<br>- `'long'`: 4秒<br>- 数字: 自定义毫秒数 |
| `options.gravity` | string | `'bottom'` | 显示位置<br>- `'top'`: 顶部<br>- `'center'`: 中间<br>- `'bottom'`: 底部 |

#### 返回值

返回一个立即 resolve 的 Promise（为了 API 一致性）。

#### 示例

```javascript
// 短暂显示在底部
flutter.toast('加载中...')

// 长时间显示在顶部
flutter.toast('网络连接失败', {
  duration: 'long',
  gravity: 'top'
})

// 自定义显示时长（3秒）
flutter.toast('自定义消息', {
  duration: 3000
})
```

---

### 2. Alert - 确认对话框

#### 基本用法

```javascript
// 仅显示确认按钮
await flutter.alert('操作完成')
```

#### 带取消按钮

```javascript
const result = await flutter.alert('确认删除这个项目？', {
  title: '警告',
  confirmText: '删除',
  cancelText: '取消',
  showCancel: true
})

if (result.confirmed) {
  console.log('用户点击了确认')
} else {
  console.log('用户点击了取消')
}
```

#### 参数说明

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `message` | string | *必填* | 对话框内容 |
| `options.title` | string | `null` | 对话框标题 |
| `options.confirmText` | string | `'确定'` | 确认按钮文字 |
| `options.cancelText` | string | `'取消'` | 取消按钮文字 |
| `options.showCancel` | boolean | `false` | 是否显示取消按钮 |

#### 返回值

返回 Promise，resolve 值为：

```javascript
{
  confirmed: boolean  // true: 点击确认, false: 点击取消或关闭
}
```

#### 示例

```javascript
// 简单提示
await flutter.alert('保存成功')

// 确认操作
const result = await flutter.alert('确定要退出吗？', {
  title: '提示',
  showCancel: true
})

if (result.confirmed) {
  // 执行退出操作
}

// 自定义按钮文字
const result = await flutter.alert('检测到新版本，是否更新？', {
  title: '版本更新',
  confirmText: '立即更新',
  cancelText: '稍后再说',
  showCancel: true
})
```

---

### 3. Dialog - 自定义对话框

#### 基本用法

```javascript
const result = await flutter.dialog({
  title: '选择操作',
  content: '请选择要执行的操作',
  actions: [
    { text: '取消', value: 'cancel' },
    { text: '保存', value: 'save' },
    { text: '删除', value: 'delete', isDestructive: true }
  ]
})

console.log('用户选择:', result)  // 'cancel' | 'save' | 'delete' | null
```

#### 参数说明

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `options.title` | string | `null` | 对话框标题 |
| `options.content` | string | `null` | 对话框内容 |
| `options.actions` | array | `[]` | 按钮配置数组 |

**actions 数组元素：**

| 字段 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `text` | string | *必填* | 按钮文字 |
| `value` | string | `null` | 按钮返回值 |
| `isDestructive` | boolean | `false` | 是否为危险操作（红色文字） |

#### 返回值

返回 Promise，resolve 值为用户点击的按钮的 `value` 值，如果关闭对话框则为 `null`。

#### 示例

```javascript
// 简单选择
const result = await flutter.dialog({
  title: '选择颜色',
  actions: [
    { text: '红色', value: 'red' },
    { text: '蓝色', value: 'blue' },
    { text: '绿色', value: 'green' }
  ]
})

if (result) {
  console.log('选择的颜色:', result)
}

// 带危险操作
const action = await flutter.dialog({
  title: '文件操作',
  content: '选择对文件的操作',
  actions: [
    { text: '取消', value: null },
    { text: '重命名', value: 'rename' },
    { text: '删除', value: 'delete', isDestructive: true }
  ]
})

switch (action) {
  case 'rename':
    // 执行重命名
    break
  case 'delete':
    // 执行删除
    break
}

// 确认对话框（类似 alert 但更灵活）
const confirmed = await flutter.dialog({
  title: '确认操作',
  content: '此操作不可撤销，确定继续？',
  actions: [
    { text: '取消', value: false },
    { text: '确定', value: true }
  ]
})

if (confirmed) {
  // 执行操作
}
```

---

## 完整示例

### 场景 1: 表单提交

```javascript
async function submitForm(data) {
  // 显示加载提示
  flutter.toast('正在提交...')

  try {
    const response = await fetch('/api/submit', {
      method: 'POST',
      body: JSON.stringify(data)
    })

    if (response.ok) {
      // 成功提示
      await flutter.alert('提交成功')
    } else {
      throw new Error('提交失败')
    }
  } catch (error) {
    // 错误提示
    const retry = await flutter.alert('提交失败，是否重试？', {
      title: '错误',
      showCancel: true
    })

    if (retry.confirmed) {
      submitForm(data)  // 重试
    }
  }
}
```

### 场景 2: 文件管理

```javascript
async function manageFile(file) {
  const action = await flutter.dialog({
    title: file.name,
    content: '选择操作',
    actions: [
      { text: '取消', value: null },
      { text: '查看', value: 'view' },
      { text: '分享', value: 'share' },
      { text: '删除', value: 'delete', isDestructive: true }
    ]
  })

  switch (action) {
    case 'view':
      viewFile(file)
      break

    case 'share':
      shareFile(file)
      flutter.toast('分享成功', { gravity: 'top' })
      break

    case 'delete':
      const confirmed = await flutter.alert('确定删除此文件？', {
        title: '警告',
        confirmText: '删除',
        showCancel: true
      })

      if (confirmed.confirmed) {
        deleteFile(file)
        flutter.toast('已删除', { duration: 'short' })
      }
      break
  }
}
```

### 场景 3: 多步骤操作

```javascript
async function setupAccount() {
  // 步骤 1: 选择账户类型
  const accountType = await flutter.dialog({
    title: '创建账户',
    content: '请选择账户类型',
    actions: [
      { text: '个人', value: 'personal' },
      { text: '企业', value: 'business' }
    ]
  })

  if (!accountType) return  // 用户取消

  flutter.toast('正在创建账户...')

  // 步骤 2: 创建账户
  try {
    await createAccount(accountType)

    // 步骤 3: 成功提示
    await flutter.alert('账户创建成功！', {
      title: '完成'
    })

    // 步骤 4: 询问是否立即设置
    const setup = await flutter.alert('是否立即设置账户信息？', {
      showCancel: true
    })

    if (setup.confirmed) {
      openSettings()
    }
  } catch (error) {
    await flutter.alert('创建失败: ' + error.message, {
      title: '错误'
    })
  }
}
```

---

## 自定义 UI 处理器

如果默认的 UI 样式不满足需求，可以自定义处理器：

```dart
import 'package:memento/core/js_bridge/platform/mobile_js_engine.dart';

void customRegisterHandlers(MobileJSEngine engine, BuildContext context) {
  // 自定义 Toast
  engine.setToastHandler((message, duration, gravity) {
    // 使用你自己的 Toast 实现
    showMyCustomToast(context, message);
  });

  // 自定义 Alert
  engine.setAlertHandler((
    message, {
    title,
    confirmText,
    cancelText,
    showCancel,
  }) async {
    // 使用你自己的 Dialog 实现
    return await showMyCustomAlert(
      context,
      message,
      title: title,
      showCancel: showCancel,
    );
  });

  // 自定义 Dialog
  engine.setDialogHandler((title, content, actions) async {
    // 使用你自己的 Dialog 实现
    return await showMyCustomDialog(context, title, content, actions);
  });
}
```

---

## 注意事项

1. **异步操作**: `alert` 和 `dialog` 返回 Promise，需要使用 `await` 或 `.then()`
2. **错误处理**: 如果 UI 处理器未注册，会在控制台输出警告但不会抛出错误
3. **线程安全**: 所有 UI 操作都会在 Flutter 主线程执行
4. **返回值**: `toast` 不需要等待返回值，但 `alert` 和 `dialog` 需要等待用户操作

---

## 故障排除

### 问题: `flutter is not defined`

**原因**: JS Bridge 未初始化或 UI 处理器未注册

**解决方案**:
```dart
// 确保初始化了 JS Bridge
await _jsBridge.initialize();

// 确保注册了 UI 处理器
final uiHandlers = JSUIHandlers(context);
uiHandlers.register(_jsBridge.engine as MobileJSEngine);
```

### 问题: 点击按钮后没有响应

**原因**: Promise 未正确轮询或 Dart 端未返回结果

**解决方案**: 检查控制台日志，查看是否有 `[JS Bridge]` 相关的错误信息

### 问题: Toast 显示位置不正确

**原因**: `gravity` 参数拼写错误

**解决方案**: 确保使用正确的值：`'top'`、`'center'`、`'bottom'`

---

## 更新日志

- **v1.0.0** (2025-11-14): 初始版本，支持 toast/alert/dialog 三个基础 API

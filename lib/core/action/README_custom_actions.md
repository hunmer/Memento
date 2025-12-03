# 自定义JavaScript动作使用指南

## 🎯 概述

系统**不包含任何预设的JavaScript代码**。您可以输入自己的JavaScript代码来创建自定义动作，就像输入文本一样简单！

## 📝 默认JavaScript执行动作

✅ **【自定义执行JavaScript代码】** - 系统提供一个默认动作
- 用户点击这个动作会弹出输入框
- 可以输入自己的JavaScript代码
- 可以输入JSON格式的输入数据
- 支持即时执行和测试

## 🚀 使用方法

### 方法 1：直接执行JavaScript（推荐）

```dart
// 直接输入您的JavaScript代码并执行
final result = await ActionManager().executeJavaScript(
  context,
  '''
  // 在这里编写您的JavaScript代码
  const a = inputData.a || 0;
  const b = inputData.b || 0;

  return {
    success: true,
    sum: a + b,
    timestamp: Date.now()
  };
  ''',
  data: {'a': 10, 'b': 20},
);
```

### 方法 2：注册用户输入的JavaScript为动作

```dart
// 假设用户从一个文本框输入了JavaScript代码
final userCode = '''
  const text = inputData.text || '';
  return {
    success: true,
    uppercase: text.toUpperCase(),
    length: text.length
  };
''';

// 将用户代码注册为动作
ActionManager().registerJavaScriptAction(
  id: 'user_text_processor',
  title: '用户文本处理器',
  description: '用户自定义的文本处理动作',
  script: userCode, // 直接使用用户输入的代码
  icon: Icons.text_fields,
);

// 以后可以通过ID执行
await ActionManager().execute('user_text_processor', context, data: {'text': 'Hello'});
```

### 方法 3：创建JavaScript代码输入界面

```dart
// 构建一个让用户输入JavaScript代码的表单
AlertDialog(
  title: const Text('输入JavaScript代码'),
  content: Column(
    children: [
      TextField(
        controller: titleController,
        decoration: const InputDecoration(labelText: '动作标题'),
      ),
      TextField(
        controller: scriptController,
        decoration: const InputDecoration(
          labelText: 'JavaScript代码',
          hintText: '在这里输入您的JavaScript代码',
        ),
        maxLines: 10,
      ),
    ],
  ),
  actions: [
    TextButton(
      onPressed: () => Navigator.pop(context),
      child: const Text('取消'),
    ),
    ElevatedButton(
      onPressed: () {
        // 直接使用用户输入的代码
        ActionManager().registerJavaScriptAction(
          id: 'user_action_${DateTime.now().millisecondsSinceEpoch}',
          title: titleController.text,
          script: scriptController.text, // 用户输入的原始代码
          icon: Icons.code,
        );
        Navigator.pop(context);
      },
      child: const Text('保存'),
    ),
  ],
);
```

### 方法 4：快速测试用户输入的代码

```dart
// 不保存，直接测试用户输入的JavaScript代码
Future<void> testUserCode(
  BuildContext context,
  String userCode,
  Map<String, dynamic> inputData,
) async {
  final result = await ActionManager().executeJavaScript(
    context,
    userCode, // 用户输入的代码
    data: inputData,
  );

  // 显示执行结果
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(result.success ? '执行成功' : '执行失败'),
      content: Text(result.success ? '结果: ${result.data}' : '错误: ${result.error}'),
    ),
  );
}
```

## 📋 实际使用场景

### 场景 1：文本编辑器中执行JavaScript

```dart
// 假设用户选中了代码并想要执行
final selectedCode = '''
  const numbers = inputData.numbers || [];
  const sum = numbers.reduce((a, b) => a + b, 0);
  return { sum: sum, count: numbers.length };
''';

await ActionManager().executeJavaScript(
  context,
  selectedCode,
  data: {'numbers': [1, 2, 3, 4, 5]},
);
```

### 场景 2：动态创建动作

```dart
// 用户在表单中输入JavaScript代码
final userInputCode = '''
  const data = inputData.data || [];
  const filter = inputData.filter || 'all';

  let filtered;
  switch(filter) {
    case 'even':
      filtered = data.filter(x => x % 2 === 0);
      break;
    case 'odd':
      filtered = data.filter(x => x % 2 !== 0);
      break;
    default:
      filtered = data;
  }

  return {
    success: true,
    original: data,
    filtered: filtered,
    filter: filter
  };
''';

// 动态注册为动作
ActionManager().registerJavaScriptAction(
  id: 'dynamic_filter_${DateTime.now().millisecondsSinceEpoch}',
  title: '动态过滤器',
  script: userInputCode,
);
```

### 场景 3：悬浮球中的自定义代码

```dart
// 让用户为悬浮球输入自定义JavaScript
showDialog(
  context: context,
  builder: (context) => AlertDialog(
    title: const Text('悬浮球JavaScript代码'),
    content: const TextField(
      decoration: InputDecoration(
        labelText: 'JavaScript代码',
        hintText: '输入要在悬浮球中执行的JavaScript代码',
      ),
      maxLines: 8,
    ),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
      ElevatedButton(
        onPressed: () {
          // final userCode = ...; // 获取用户输入
          // ActionManager().registerJavaScriptAction(..., script: userCode);
          Navigator.pop(context);
        },
        child: const Text('保存'),
      ),
    ],
  ),
);
```

## 🔍 查看当前自定义动作

```dart
// 查看所有自定义动作（初始为空）
final customActions = ActionManager().getCustomActions();
print('当前自定义动作数量: ${customActions.length}'); // 初始为 0

for (final action in customActions) {
  print('动作: ${action.title}');
  print('代码: ${action.executor}'); // 显示用户的代码
}
```

## 📝 JavaScript代码编写指南

### 基本格式

```javascript
// 1. 访问输入数据
const input = inputData || {};

// 2. 编写您的逻辑
const result = yourLogicHere(input);

// 3. 返回结果（必须包含 success 字段）
return {
  success: true,
  data: result,
  timestamp: Date.now()
};
```

### 输入数据格式

```javascript
// 通过 inputData 访问输入
const value1 = inputData.value1;     // 数字
const value2 = inputData.value2;     // 字符串
const array = inputData.array || []; // 数组（提供默认值）
```

### 返回数据格式

```javascript
// 成功执行
return {
  success: true,
  result: yourResult,
  message: '处理完成',
  data: additionalData
};

// 执行失败
return {
  success: false,
  error: '错误信息'
};
```

### 常用操作示例

```javascript
// 数学计算
const a = inputData.a || 0;
const b = inputData.b || 0;
return {
  success: true,
  sum: a + b,
  product: a * b
};

// 字符串处理
const text = inputData.text || '';
return {
  success: true,
  uppercase: text.toUpperCase(),
  lowercase: text.toLowerCase(),
  length: text.length
};

// 数组处理
const items = inputData.items || [];
return {
  success: true,
  count: items.length,
  first: items[0],
  last: items[items.length - 1],
  sorted: items.sort()
};

// 数据过滤
const data = inputData.data || [];
const filter = inputData.filter || 'all';
const filtered = data.filter(item => item % 2 === 0);
return {
  success: true,
  original: data,
  filtered: filtered
};
```

## ⚠️ 重要提示

1. **无预设代码**：
   - 系统不包含任何预设的JavaScript代码
   - 所有代码都需要用户自己输入

2. **代码格式**：
   - 必须使用 `return` 语句返回结果
   - 返回对象必须包含 `success` 字段

3. **数据访问**：
   - 使用 `inputData` 访问输入的数据
   - 使用 `||` 提供默认值避免错误

4. **安全考虑**：
   - 用户输入的代码可能有安全风险
   - 建议在生产环境中添加沙箱机制

5. **调试方法**：
   - 使用 `quickExecute` 方法测试代码
   - 查看执行结果的 `data` 和 `error` 字段

## 📚 获取帮助

### 空模板代码

```dart
// 获取一个空模板作为起点
final template = CustomActionExamples.getEmptyTemplate();
print(template);
```

### 带注释的模板

```dart
// 获取带详细注释的模板
final template = CustomActionExamples.getCommentedTemplate();
print(template);
```

### 代码验证

```dart
// 在保存前验证用户输入的代码
final errors = CustomActionExamples.validateJavaScript(userCode);
if (errors.isNotEmpty) {
  print('代码错误: $errors');
}
```

## 📚 更多资源

- 查看 `examples/custom_action_examples.dart` 获取完整示例
- 查看 `action_executor.dart` 了解执行引擎
- 查看 `action_manager.dart` 了解注册机制

---

## ✅ 核心特性

| 特性 | 状态 | 说明 |
|------|------|------|
| 无预设代码 | ✅ | 系统不包含任何预设JavaScript代码 |
| 用户输入代码 | ✅ | 完全支持用户自己输入JavaScript代码 |
| 直接执行 | ✅ | 支持即时执行用户输入的代码 |
| 动作注册 | ✅ | 支持将用户代码注册为命名动作 |
| 代码验证 | ✅ | 提供代码格式验证功能 |
| 模板生成 | ✅ | 提供空模板和注释模板 |

现在您可以**完全自由地输入自己的JavaScript代码**，没有任何预设限制！🎉

// 示例 module 类型脚本
// 演示如何使用输入参数

// 获取用户输入的参数
const username = args.username || '访客';
const age = args.age || 0;
const gender = args.gender || '未知';
const enableNotification = args.enableNotification || false;

// 构建问候消息
let greeting = `你好，${username}！\n\n`;

if (age > 0) {
  greeting += `年龄：${age}岁\n`;
}

greeting += `性别：${gender}\n`;
greeting += `通知状态：${enableNotification ? '已开启' : '已关闭'}\n\n`;

// 根据年龄给出不同的建议
if (age > 0) {
  if (age < 18) {
    greeting += '建议：好好学习，天天向上！';
  } else if (age < 30) {
    greeting += '建议：珍惜青春，努力奋斗！';
  } else if (age < 60) {
    greeting += '建议：保持健康，享受生活！';
  } else {
    greeting += '建议：颐养天年，享受晚年！';
  }
}

// 显示问候消息
await flutter.alert(greeting, {
  title: '欢迎使用 Memento',
  confirmText: '确定'
});

// 可选：显示Toast提示
if (enableNotification) {
  flutter.toast(`欢迎回来，${username}！`, {
    duration: 'short',
    gravity: 'bottom'
  });
}

// 返回执行结果
return {
  success: true,
  message: '脚本执行成功',
  user: {
    username,
    age,
    gender,
    enableNotification
  },
  timestamp: new Date().toISOString()
};

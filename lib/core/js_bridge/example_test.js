/**
 * JavaScript Bridge API 测试示例
 *
 * 这个文件展示了如何使用 flutter.toast、flutter.alert 和 flutter.dialog API
 */

// ==================== 测试 1: Toast ====================

console.log('=== 测试 Toast ===');

// 基本用法
flutter.toast('这是一条简单的提示');

// 短时间显示在顶部
flutter.toast('顶部提示', {
  duration: 'short',
  gravity: 'top'
});

// 长时间显示在中间
flutter.toast('中间提示', {
  duration: 'long',
  gravity: 'center'
});

// 自定义时长（3秒）
flutter.toast('自定义时长', {
  duration: 3000,
  gravity: 'bottom'
});

// ==================== 测试 2: Alert ====================

console.log('=== 测试 Alert ===');

// 测试简单提示（异步函数）
async function testAlert() {
  // 仅显示确认按钮
  await flutter.alert('这是一条提示信息');
  console.log('用户点击了确认');

  // 带标题的提示
  await flutter.alert('操作已完成', {
    title: '成功'
  });

  // 带取消按钮的确认
  const result1 = await flutter.alert('确定要删除吗？', {
    title: '警告',
    confirmText: '删除',
    cancelText: '取消',
    showCancel: true
  });

  console.log('Alert 结果:', result1);
  if (result1.confirmed) {
    console.log('用户确认删除');
  } else {
    console.log('用户取消删除');
  }

  // 自定义按钮文字
  const result2 = await flutter.alert('检测到新版本，是否更新？', {
    title: '版本更新',
    confirmText: '立即更新',
    cancelText: '稍后再说',
    showCancel: true
  });

  console.log('更新选择:', result2.confirmed ? '立即更新' : '稍后再说');
}

// ==================== 测试 3: Dialog ====================

console.log('=== 测试 Dialog ===');

// 测试自定义对话框（异步函数）
async function testDialog() {
  // 简单选择
  const color = await flutter.dialog({
    title: '选择颜色',
    content: '请选择你喜欢的颜色',
    actions: [
      { text: '取消', value: null },
      { text: '红色', value: 'red' },
      { text: '蓝色', value: 'blue' },
      { text: '绿色', value: 'green' }
    ]
  });

  console.log('选择的颜色:', color);

  // 文件操作
  const action = await flutter.dialog({
    title: '文件操作',
    content: '请选择要执行的操作',
    actions: [
      { text: '取消', value: null },
      { text: '查看', value: 'view' },
      { text: '分享', value: 'share' },
      { text: '删除', value: 'delete', isDestructive: true }
    ]
  });

  console.log('选择的操作:', action);

  switch (action) {
    case 'view':
      flutter.toast('正在查看文件');
      break;
    case 'share':
      flutter.toast('正在分享文件');
      break;
    case 'delete':
      const confirmed = await flutter.alert('确定删除？', {
        title: '二次确认',
        showCancel: true
      });
      if (confirmed.confirmed) {
        flutter.toast('文件已删除', { duration: 'long' });
      }
      break;
  }

  // 多个操作
  const priority = await flutter.dialog({
    title: '设置优先级',
    actions: [
      { text: '低', value: 'low' },
      { text: '中', value: 'medium' },
      { text: '高', value: 'high' }
    ]
  });

  console.log('选择的优先级:', priority);
}

// ==================== 测试 4: 组合使用 ====================

console.log('=== 测试组合使用 ===');

// 模拟表单提交流程
async function testFormSubmit() {
  flutter.toast('准备提交表单...');

  // 等待一秒
  await new Promise(resolve => setTimeout(resolve, 1000));

  // 确认提交
  const confirmSubmit = await flutter.alert('确定提交表单？', {
    title: '确认',
    showCancel: true
  });

  if (!confirmSubmit.confirmed) {
    flutter.toast('已取消提交');
    return;
  }

  flutter.toast('正在提交...', { duration: 'long' });

  // 模拟网络请求
  await new Promise(resolve => setTimeout(resolve, 2000));

  // 模拟成功/失败（50%概率）
  const success = Math.random() > 0.5;

  if (success) {
    await flutter.alert('表单提交成功！', {
      title: '成功'
    });
    flutter.toast('操作完成', { gravity: 'top' });
  } else {
    const retry = await flutter.alert('提交失败，是否重试？', {
      title: '错误',
      confirmText: '重试',
      cancelText: '取消',
      showCancel: true
    });

    if (retry.confirmed) {
      flutter.toast('正在重试...', { duration: 'long' });
      // 这里可以递归调用 testFormSubmit()
    }
  }
}

// ==================== 测试 5: 复杂场景 ====================

console.log('=== 测试复杂场景 ===');

// 多步骤向导
async function testWizard() {
  // 步骤 1: 选择类型
  const type = await flutter.dialog({
    title: '步骤 1/3',
    content: '选择账户类型',
    actions: [
      { text: '个人', value: 'personal' },
      { text: '企业', value: 'business' }
    ]
  });

  if (!type) {
    flutter.toast('已取消');
    return;
  }

  flutter.toast(`选择了${type === 'personal' ? '个人' : '企业'}账户`);

  // 步骤 2: 选择计划
  const plan = await flutter.dialog({
    title: '步骤 2/3',
    content: '选择套餐',
    actions: [
      { text: '返回', value: null },
      { text: '免费版', value: 'free' },
      { text: '专业版', value: 'pro' },
      { text: '企业版', value: 'enterprise' }
    ]
  });

  if (!plan) {
    flutter.toast('已返回');
    return;
  }

  // 步骤 3: 确认
  const confirm = await flutter.alert(
    `账户类型: ${type}\n套餐: ${plan}\n\n确认创建？`,
    {
      title: '步骤 3/3 - 确认',
      confirmText: '创建',
      cancelText: '取消',
      showCancel: true
    }
  );

  if (confirm.confirmed) {
    flutter.toast('正在创建账户...', { duration: 'long' });
    await new Promise(resolve => setTimeout(resolve, 2000));
    await flutter.alert('账户创建成功！', { title: '完成' });
  } else {
    flutter.toast('已取消创建');
  }
}

// ==================== 运行所有测试 ====================

// 注意：在实际使用中，这些测试应该通过用户交互触发，
// 而不是一次性全部运行

async function runAllTests() {
  console.log('开始运行所有测试...');

  // 测试 Toast（立即执行）
  flutter.toast('测试开始', { gravity: 'top' });

  // 等待一下再测试 Alert
  await new Promise(resolve => setTimeout(resolve, 1000));
  await testAlert();

  // 测试 Dialog
  await testDialog();

  // 测试组合使用
  await testFormSubmit();

  // 测试复杂场景
  await testWizard();

  console.log('所有测试完成！');
  flutter.toast('所有测试完成！', {
    duration: 'long',
    gravity: 'center'
  });
}

// 导出测试函数（可在 Flutter 端调用）
globalThis.testJSAPI = {
  runAll: runAllTests,
  testAlert: testAlert,
  testDialog: testDialog,
  testFormSubmit: testFormSubmit,
  testWizard: testWizard
};

console.log('测试函数已注册到 globalThis.testJSAPI');
console.log('使用示例: await testJSAPI.runAll()');

// 返回测试对象
testJSAPI;

// 插件系统 API 测试脚本 (Node.js)
// 使用方法: node test-upload-plugin.mjs

const BASE_URL = 'http://localhost:8874';
const USERNAME = 'admin';
const PASSWORD = 'admin123';

async function request(endpoint, options = {}) {
  const url = `${BASE_URL}${endpoint}`;
  const response = await fetch(url, {
    ...options,
    headers: {
      'Content-Type': 'application/json',
      ...options.headers,
    },
  });
  return response.json();
}

async function uploadPlugin(token, zipBuffer) {
  const formData = new FormData();
  const blob = new Blob([zipBuffer], { type: 'application/zip' });
  formData.append('plugin', blob, 'test-plugin.zip');

  const response = await fetch(`${BASE_URL}/api/v1/system/plugins/upload`, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${token}`,
    },
    body: formData,
  });
  return response.json();
}

async function main() {
  console.log('========================================');
  console.log('  插件系统 API 测试');
  console.log('========================================\n');

  // 1. 登录
  console.log('1. 登录获取 Token...');
  const loginResult = await request('/api/v1/auth/login', {
    method: 'POST',
    body: JSON.stringify({
      username: USERNAME,
      password: PASSWORD,
      device_id: 'test-script',
      device_name: 'Test Script',
    }),
  });

  if (!loginResult.success) {
    console.error('登录失败:', loginResult.error);
    process.exit(1);
  }

  const token = loginResult.token;
  console.log('✅ 登录成功\n');

  // 2. 获取已安装插件列表
  console.log('2. 获取已安装插件列表...');
  const pluginsResult = await request('/api/v1/system/plugins', {
    headers: { 'Authorization': `Bearer ${token}` },
  });
  console.log(`✅ 已安装插件: ${pluginsResult.total} 个\n`);

  // 3. 获取商店配置
  console.log('3. 获取商店配置...');
  const configResult = await request('/api/v1/system/plugins/config', {
    headers: { 'Authorization': `Bearer ${token}` },
  });
  console.log('✅ 商店配置:', JSON.stringify(configResult.config), '\n');

  // 4. 创建测试插件 ZIP
  console.log('4. 创建测试插件...');
  const metadata = {
    uuid: 'test-hello',
    title: '测试插件 Hello',
    author: 'Test',
    description: '一个简单的测试插件',
    version: '1.0.0',
    permissions: {
      dataAccess: [],
      operations: ['read'],
      networkAccess: false,
    },
  };

  const mainJs = `
module.exports.metadata = ${JSON.stringify(metadata)};
module.exports.onLoad = async function() {
  console.log('Test plugin loaded');
};
module.exports.handlers = {};
`;

  // 创建 ZIP 文件 (使用简单的 base64 编码)
  const AdmZip = (await import('adm-zip')).default;
  const zip = new AdmZip();
  zip.addFile('metadata.json', Buffer.from(JSON.stringify(metadata, null, 2)));
  zip.addFile('main.js', Buffer.from(mainJs));
  const zipBuffer = zip.toBuffer();
  console.log('✅ 测试插件创建完成\n');

  // 5. 上传插件
  console.log('5. 上传插件...');
  const uploadResult = await uploadPlugin(token, zipBuffer);
  if (uploadResult.success) {
    console.log('✅ 上传成功:', uploadResult.plugin.title, '\n');
  } else {
    console.log('❌ 上传失败:', uploadResult.error, '\n');
  }

  // 6. 验证已安装
  console.log('6. 验证已安装...');
  const pluginsAfterUpload = await request('/api/v1/system/plugins', {
    headers: { 'Authorization': `Bearer ${token}` },
  });
  const installedPlugin = pluginsAfterUpload.plugins.find(p => p.uuid === 'test-hello');
  if (installedPlugin) {
    console.log('✅ 插件已安装:', installedPlugin.title, `- 状态: ${installedPlugin.status}\n`);
  } else {
    console.log('❌ 未找到安装的插件\n');
  }

  // 7. 启用插件
  console.log('7. 启用插件...');
  const enableResult = await request('/api/v1/system/plugins/test-hello/enable', {
    method: 'POST',
    headers: { 'Authorization': `Bearer ${token}` },
  });
  console.log(enableResult.success ? '✅ 插件已启用\n' : `❌ ${enableResult.error}\n`);

  // 8. 验证状态
  console.log('8. 验证状态...');
  const pluginsAfterEnable = await request('/api/v1/system/plugins', {
    headers: { 'Authorization': `Bearer ${token}` },
  });
  const enabledPlugin = pluginsAfterEnable.plugins.find(p => p.uuid === 'test-hello');
  if (enabledPlugin) {
    console.log(`✅ 插件状态: ${enabledPlugin.status}\n`);
  }

  // 9. 禁用插件
  console.log('9. 禁用插件...');
  const disableResult = await request('/api/v1/system/plugins/test-hello/disable', {
    method: 'POST',
    headers: { 'Authorization': `Bearer ${token}` },
  });
  console.log(disableResult.success ? '✅ 插件已禁用\n' : `❌ ${disableResult.error}\n`);

  // 10. 卸载插件
  console.log('10. 卸载插件...');
  const uninstallResult = await fetch(`${BASE_URL}/api/v1/system/plugins/test-hello`, {
    method: 'DELETE',
    headers: { 'Authorization': `Bearer ${token}` },
  }).then(r => r.json());
  console.log(uninstallResult.success ? '✅ 插件已卸载\n' : `❌ ${uninstallResult.error}\n`);

  // 11. 验证已卸载
  console.log('11. 验证已卸载...');
  const pluginsAfterUninstall = await request('/api/v1/system/plugins', {
    headers: { 'Authorization': `Bearer ${token}` },
  });
  const uninstalledPlugin = pluginsAfterUninstall.plugins.find(p => p.uuid === 'test-hello');
  console.log(uninstalledPlugin ? '❌ 插件仍然存在' : '✅ 插件已成功卸载');

  console.log('\n========================================');
  console.log('  测试完成');
  console.log('========================================');
}

main().catch(console.error);

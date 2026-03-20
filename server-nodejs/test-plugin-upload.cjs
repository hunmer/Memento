/**
 * 插件上传测试脚本
 */

const http = require('http');
const fs = require('fs');
const path = require('path');
const FormData = require('form-data');

const BASE_URL = 'http://localhost:8874';
const USERNAME = 'admin';
const PASSWORD = 'admin123';

async function login() {
  const response = await fetch(`${BASE_URL}/api/v1/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      username: USERNAME,
      password: PASSWORD,
      device_id: 'test-script',
      device_name: 'Test Script',
    }),
  });
  return response.json();
}

async function testPluginSystem() {
  console.log('========================================');
  console.log('  插件系统 API 测试');
  console.log('========================================\n');

  // 1. 登录
  console.log('1. 登录获取 Token...');
  const loginResult = await login();
  if (!loginResult.success) {
    console.error('登录失败:', loginResult.error);
    process.exit(1);
  }
  const token = loginResult.token;
  console.log('✅ 登录成功\n');

  // 2. 获取已安装插件列表
  console.log('2. 获取已安装插件列表...');
  const pluginsResponse = await fetch(`${BASE_URL}/api/v1/system/plugins`, {
    headers: { 'Authorization': `Bearer ${token}` },
  });
  const pluginsData = pluginsResponse.json();
  console.log(`✅ 已安装插件: ${pluginsData.total} 个\n`);

  // 3. 获取商店配置
  console.log('3. 获取商店配置...');
  const configResponse = await fetch(`${BASE_URL}/api/v1/system/plugins/config`, {
    headers: { 'Authorization': `Bearer ${token}` },
  });
  const configData = configResponse.json();
  console.log('✅ 商店配置:', JSON.stringify(configData.config || configData), '\n');

  // 4. 更新商店配置
  console.log('4. 更新商店配置...');
  const updateResponse = await fetch(`${BASE_URL}/api/v1/system/plugins/config`, {
    method: 'PUT',
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      storeURL: `${BASE_URL}/plugins/plugin-store.json`,
    }),
  });
  const updateData = updateResponse.json();
  console.log('✅ 商店 URL 已更新\n');

  // 5. 获取商店插件列表
  console.log('5. 获取商店插件列表...');
  const storeResponse = await fetch(`${BASE_URL}/api/v1/system/plugins/store`, {
    headers: { 'Authorization': `Bearer ${token}` },
  });
  const storeData = storeResponse.json();
  if (storeData.success) {
    console.log(`✅ 商店插件: ${storeData.total} 个`);
    storeData.plugins.forEach(p => console.log(`   - ${p.title} (${p.uuid})`));
  } else {
    console.log('⚠️ 获取商店失败:', storeData.error);
  }

  // 6. 创建测试插件
  console.log('6. 创建测试插件...');
  const testPluginDir = path.join(__dirname, 'test-plugin-temp');
  fs.mkdirSync(testPluginDir, { recursive: true });

  const metadata = {
    uuid: 'test-hello',
    title: '测试插件',
    author: 'Test',
    description: '用于测试的插件',
    version: '1.0.0',
    permissions: {
      dataAccess: [],
      operations: ['read'],
      networkAccess: false,
    },
  };

  fs.writeFileSync(path.join(testPluginDir, 'metadata.json'), JSON.stringify(metadata, null, 2));
  fs.writeFileSync(path.join(testPluginDir, 'main.js'), `
module.exports.metadata = require('./metadata.json');
module.exports.onLoad = async function() {
  console.log('Test plugin loaded');
};
module.exports.handlers = {};
`);

  // 创建 ZIP
  const zipPath = path.join(__dirname, 'test-plugin.zip');
  const admZip = require('adm-zip');
  const zip = new admZip();
  zip.addFileFromString('metadata.json', JSON.stringify(metadata, null, 2));
  zip.addFileFromString('main.js', fs.readFileSync(path.join(testPluginDir, 'main.js'), 'utf8');
  fs.writeFileSync(zipPath, zip.toBuffer());

  // 7. 上传插件
  console.log('7. 上传插件...');
  const form = new FormData();
  form.append('plugin', fs.createReadStream(zipPath), path.basename(zipPath));

  const uploadResponse = await fetch(`${BASE_URL}/api/v1/system/plugins/upload`, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${token}`,
    },
    body: form,
  });
  const uploadData = uploadResponse.json();
  if (uploadData.success) {
    console.log(`✅ 插件上传成功: ${uploadData.plugin.title}`);
  } else {
    console.log('❌ 上传失败:', uploadData.error);
  }

  // 8. 获取已安装插件
  console.log('8. 获取已安装插件列表...');
  const pluginsResponse2 = await fetch(`${BASE_URL}/api/v1/system/plugins`, {
    headers: { 'Authorization': `Bearer ${token}` },
  });
  const pluginsData2 = pluginsResponse2.json();
  console.log(`✅ 已安装插件: ${pluginsData2.total} 个`);
  pluginsData2.plugins.forEach(p => console.log(`   - ${p.title} (${p.status})`));

  // 9. 启用插件
  console.log('9. 启用插件...');
  const enableResponse = await fetch(`${BASE_URL}/api/v1/system/plugins/${metadata.uuid}/enable`, {
    method: 'POST',
    headers: { 'Authorization': `Bearer ${token}` },
  });
  const enableData = enableResponse.json();
  console.log(`✅ ${enableData.message}`);

  // 10. 禁用插件
  console.log('10. 禁用插件...');
  const disableResponse = await fetch(`${BASE_URL}/api/v1/system/plugins/${metadata.uuid}/disable`, {
    method: 'POST',
    headers: { 'Authorization': `Bearer ${token}` },
  });
  const disableData = disableResponse.json();
  console.log(`✅ ${disableData.message}`);

  // 11. 卸载插件
  console.log('11. 卸载插件...');
  const uninstallResponse = await fetch(`${BASE_URL}/api/v1/system/plugins/${metadata.uuid}`, {
    method: 'DELETE',
    headers: { 'Authorization': `Bearer ${token}` },
  });
  const uninstallData = uninstallResponse.json();
  console.log(`✅ ${uninstallData.message}`);

  // 12. 验证已卸载
  console.log('12. 验证已卸载...');
  const pluginsResponse3 = await fetch(`${BASE_URL}/api/v1/system/plugins`, {
    headers: { 'Authorization': `Bearer ${token}` },
  });
  const pluginsData3 = pluginsResponse3.json();
  console.log(`✅ 已安装插件: ${pluginsData3.total} 个`);

  // 清理
  fs.rmSync(testPluginDir, { recursive: true });
  fs.unlinkSync(zipPath);

  console.log('\n========================================');
  console.log('  所有测试完成!');
  console.log('========================================');
}

testPluginSystem().catch(console.error);

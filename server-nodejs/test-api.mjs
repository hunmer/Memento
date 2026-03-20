/**
 * 插件系统 API 测试脚本
 */

import https from 'https';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import AdmZip from 'adm-zip';

const BASE_URL = 'http://localhost:8874';
const USERNAME = 'admin';
const PASSWORD = 'admin123';

async function request(url, options = {}) {
  const response = await fetch(url, options);
  const text = await response.text();
  try {
    return JSON.parse(text);
  } catch {
    return { error: text, status: response.status };
  }
}

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
  const pluginsData = await pluginsResponse.json();
  console.log(`✅ 已安装插件: ${pluginsData.total} 个\n`);

  // 3. 获取商店配置
  console.log('3. 获取商店配置...');
  const configResponse = await fetch(`${BASE_URL}/api/v1/system/plugins/config`, {
    headers: { 'Authorization': `Bearer ${token}` },
  });
  const configData = await configResponse.json();
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
  const updateData = await updateResponse.json();
  console.log('✅ 商店 URL 已更新\n');

  // 5. 获取商店插件列表
  console.log('5. 获取商店插件列表...');
  const storeResponse = await fetch(`${BASE_URL}/api/v1/system/plugins/store`, {
    headers: { 'Authorization': `Bearer ${token}` },
  });
  const storeData = await storeResponse.json();
  if (storeData.success) {
    console.log(`✅ 商店插件: ${storeData.total} 个`);
    storeData.plugins.forEach(p => console.log(`   - ${p.title} (${p.uuid})`));
  } else {
    console.log('⚠️ 获取商店失败:', storeData.error);
  }
  console.log('');

  // 6. 创建测试插件 ZIP
  console.log('6. 创建测试插件 ZIP...');
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

  const mainJs = `
module.exports.metadata = ${JSON.stringify(metadata)};
module.exports.onLoad = async function() {
  console.log('Test plugin loaded');
};
module.exports.handlers = {};
`;

  const zip = new AdmZip();
  zip.addFile('metadata.json', Buffer.from(JSON.stringify(metadata, null, 2)));
  zip.addFile('main.js', Buffer.from(mainJs));
  const zipBuffer = zip.toBuffer();
  console.log('✅ 测试插件创建完成\n');

  // 7. 上传插件
  console.log('7. 上传插件...');
  const formData = new FormData();
  const blob = new Blob([zipBuffer], { type: 'application/zip' });
  formData.append('plugin', blob, 'test-plugin.zip');

  const uploadResponse = await fetch(`${BASE_URL}/api/v1/system/plugins/upload`, {
    method: 'POST',
    headers: { 'Authorization': `Bearer ${token}` },
    body: formData,
  });
  const uploadData = await uploadResponse.json();
  if (uploadData.success) {
    console.log(`✅ 上传成功: ${uploadData.plugin.title}\n`);
  } else {
    console.log(`❌ 上传失败: ${uploadData.error}\n`);
  }

  // 8. 获取已安装插件
  console.log('8. 获取已安装插件列表...');
  const pluginsResponse2 = await fetch(`${BASE_URL}/api/v1/system/plugins`, {
    headers: { 'Authorization': `Bearer ${token}` },
  });
  const pluginsData2 = await pluginsResponse2.json();
  console.log(`✅ 已安装插件: ${pluginsData2.total} 个`);
  pluginsData2.plugins.forEach(p => console.log(`   - ${p.title} (${p.status})`));
  console.log('');

  // 9. 启用插件
  console.log('9. 启用插件...');
  const enableResponse = await fetch(`${BASE_URL}/api/v1/system/plugins/test-hello/enable`, {
    method: 'POST',
    headers: { 'Authorization': `Bearer ${token}` },
  });
  const enableData = await enableResponse.json();
  console.log(`${enableData.success ? '✅' : '❌'} ${enableData.message || enableData.error}\n`);

  // 10. 禁用插件
  console.log('10. 禁用插件...');
  const disableResponse = await fetch(`${BASE_URL}/api/v1/system/plugins/test-hello/disable`, {
    method: 'POST',
    headers: { 'Authorization': `Bearer ${token}` },
  });
  const disableData = await disableResponse.json();
  console.log(`${disableData.success ? '✅' : '❌'} ${disableData.message || disableData.error}\n`);

  // 11. 卸载插件
  console.log('11. 卸载插件...');
  const uninstallResponse = await fetch(`${BASE_URL}/api/v1/system/plugins/test-hello`, {
    method: 'DELETE',
    headers: { 'Authorization': `Bearer ${token}` },
  });
  const uninstallData = await uninstallResponse.json();
  console.log(`${uninstallData.success ? '✅' : '❌'} ${uninstallData.message || uninstallData.error}\n`);

  // 12. 验证已卸载
  console.log('12. 验证已卸载...');
  const pluginsResponse3 = await fetch(`${BASE_URL}/api/v1/system/plugins`, {
    headers: { 'Authorization': `Bearer ${token}` },
  });
  const pluginsData3 = await pluginsResponse3.json();
  console.log(`✅ 已安装插件: ${pluginsData3.total} 个\n`);

  console.log('========================================');
  console.log('  所有测试完成!');
  console.log('========================================');
}

testPluginSystem().catch(console.error);

#!/usr/bin/env node

/**
 * MCP Inspector 启动脚本
 * 自动加载 .env 环境变量并启动 Inspector
 */

import { spawn } from 'child_process';
import { fileURLToPath } from 'url';
import { dirname, resolve } from 'path';
import dotenv from 'dotenv';
import fs from 'fs';

// 获取项目根目录
const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const projectRoot = resolve(__dirname, '..');

// 加载 .env 文件
const envPath = resolve(projectRoot, '.env');
if (fs.existsSync(envPath)) {
  dotenv.config({ path: envPath });
  console.log('✅ 已加载环境变量文件:', envPath);
  console.log('📝 环境变量:');
  console.log('   MEMENTO_SERVER_URL:', process.env.MEMENTO_SERVER_URL || '(未设置)');
  console.log('   MEMENTO_AUTH_TOKEN:', process.env.MEMENTO_AUTH_TOKEN ? '(已设置)' : '(未设置)');
} else {
  console.warn('⚠️  未找到 .env 文件:', envPath);
  console.warn('   Inspector 将在没有环境变量的情况下启动');
}

console.log('\n🚀 启动 MCP Inspector...\n');

// 启动 Inspector，传递所有环境变量
const inspector = spawn('npx', ['@modelcontextprotocol/inspector', 'node', 'dist/index.js'], {
  cwd: projectRoot,
  stdio: 'inherit',
  env: {
    ...process.env,
    // 确保关键环境变量被传递
    MEMENTO_SERVER_URL: process.env.MEMENTO_SERVER_URL,
    MEMENTO_AUTH_TOKEN: process.env.MEMENTO_AUTH_TOKEN,
  },
  shell: true,
});

inspector.on('error', (err) => {
  console.error('❌ 启动失败:', err.message);
  process.exit(1);
});

inspector.on('close', (code) => {
  if (code !== 0) {
    console.log(`\n⚠️  Inspector 退出，代码: ${code}`);
  }
  process.exit(code);
});

// 处理 Ctrl+C
process.on('SIGINT', () => {
  console.log('\n👋 正在关闭 Inspector...');
  inspector.kill('SIGINT');
});

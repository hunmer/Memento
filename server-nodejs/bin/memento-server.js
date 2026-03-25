#!/usr/bin/env node

/**
 * Memento Sync Server CLI 入口
 * 全局安装后可通过 `memento-server` 命令启动
 */

const { spawn } = require('child_process');
const path = require('path');

// 获取 dist 目录下的入口文件路径
const entryFile = path.join(__dirname, '..', 'dist', 'index.js');

// 将命令行参数传递给主程序
const args = process.argv.slice(2);

// 启动服务器
const server = spawn('node', [entryFile, ...args], {
  stdio: 'inherit',
  env: process.env,
});

server.on('error', (err) => {
  console.error('启动服务器失败:', err.message);
  process.exit(1);
});

server.on('exit', (code) => {
  process.exit(code || 0);
});

/**
 * Memento API 转发服务器入口
 *
 * 用于在 memento-mock 前端和 Memento 客户端之间转发 API 请求
 */

import { WebSocketServer } from './server';

const PORT = parseInt(process.env.PORT as string) || 8654;

const server = new WebSocketServer(PORT);

server.start().then(() => {
  console.log(`[转发服务器] 运行在端口 ${PORT}`);
  console.log('[转发服务器] 等待客户端连接...');
}).catch((error) => {
  console.error('[转发服务器] 启动失败:', error);
  process.exit(1);
});

// 优雅关闭
process.on('SIGINT', () => {
  console.log('\n[转发服务器] 正在关闭...');
  server.stop();
  process.exit(0);
});

process.on('SIGTERM', () => {
  console.log('\n[转发服务器] 收到终止信号，正在关闭...');
  server.stop();
  process.exit(0);
});

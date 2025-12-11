/**
 * Memento MCP Server 配置管理
 */

import type { MementoConfig } from './types/index.js';

/**
 * 从环境变量加载配置
 */
export function loadConfig(): MementoConfig {
  let serverUrl = process.env.MEMENTO_SERVER_URL;
  const serverHost = process.env.MEMENTO_SERVER_HOST;
  const serverPort = process.env.MEMENTO_SERVER_PORT;
  const authToken = process.env.MEMENTO_AUTH_TOKEN;

  // 支持分开配置 host 和 port
  if (serverHost) {
    const protocol = serverUrl?.startsWith('https') ? 'https' : 'http';
    const port = serverPort || '8080';
    serverUrl = `${protocol}://${serverHost}:${port}`;
  } else if (serverPort && serverUrl) {
    // 如果只设置了 port，替换 URL 中的端口
    try {
      const url = new URL(serverUrl);
      url.port = serverPort;
      serverUrl = url.toString();
    } catch {
      // 忽略 URL 解析错误
    }
  }

  if (!serverUrl) {
    throw new Error('环境变量 MEMENTO_SERVER_URL 或 MEMENTO_SERVER_HOST 未设置');
  }

  if (!authToken) {
    throw new Error('环境变量 MEMENTO_AUTH_TOKEN 未设置');
  }

  return {
    serverUrl: serverUrl.replace(/\/$/, ''), // 移除末尾斜杠
    authToken,
  };
}

/**
 * 验证配置
 */
export function validateConfig(config: MementoConfig): void {
  try {
    new URL(config.serverUrl);
  } catch {
    throw new Error(`无效的服务器 URL: ${config.serverUrl}`);
  }

  if (!config.authToken || config.authToken.length < 10) {
    throw new Error('无效的认证令牌');
  }
}

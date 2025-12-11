"use strict";
/**
 * Memento MCP Server 配置管理
 */
Object.defineProperty(exports, "__esModule", { value: true });
exports.loadConfig = loadConfig;
exports.validateConfig = validateConfig;
/**
 * 从环境变量加载配置
 */
function loadConfig() {
    const serverUrl = process.env.MEMENTO_SERVER_URL;
    const authToken = process.env.MEMENTO_AUTH_TOKEN;
    if (!serverUrl) {
        throw new Error('环境变量 MEMENTO_SERVER_URL 未设置');
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
function validateConfig(config) {
    try {
        new URL(config.serverUrl);
    }
    catch {
        throw new Error(`无效的服务器 URL: ${config.serverUrl}`);
    }
    if (!config.authToken || config.authToken.length < 10) {
        throw new Error('无效的认证令牌');
    }
}
//# sourceMappingURL=config.js.map
/**
 * Memento MCP Server 配置管理
 */
/**
 * 从环境变量加载配置
 *
 * 使用 API Key 认证：设置 MEMENTO_API_KEY 和 MEMENTO_ENCRYPTION_KEY
 */
export function loadConfig() {
    let serverUrl = process.env.MEMENTO_SERVER_URL;
    const serverHost = process.env.MEMENTO_SERVER_HOST;
    const serverPort = process.env.MEMENTO_SERVER_PORT;
    // API Key 认证
    const apiKey = process.env.MEMENTO_API_KEY;
    const encryptionKey = process.env.MEMENTO_ENCRYPTION_KEY;
    // 支持分开配置 host 和 port
    if (serverHost) {
        const protocol = serverUrl?.startsWith('https') ? 'https' : 'http';
        const port = serverPort || '8080';
        serverUrl = `${protocol}://${serverHost}:${port}`;
    }
    else if (serverPort && serverUrl) {
        // 如果只设置了 port，替换 URL 中的端口
        try {
            const url = new URL(serverUrl);
            url.port = serverPort;
            serverUrl = url.toString();
        }
        catch {
            // 忽略 URL 解析错误
        }
    }
    if (!serverUrl) {
        throw new Error('环境变量 MEMENTO_SERVER_URL 或 MEMENTO_SERVER_HOST 未设置');
    }
    // 检查 API Key 认证
    if (!apiKey) {
        throw new Error('环境变量 MEMENTO_API_KEY 未设置');
    }
    if (!encryptionKey) {
        throw new Error('环境变量 MEMENTO_ENCRYPTION_KEY 未设置');
    }
    return {
        serverUrl: serverUrl.replace(/\/$/, ''),
        apiKey,
        encryptionKey,
    };
}
/**
 * 验证配置
 */
export function validateConfig(config) {
    try {
        new URL(config.serverUrl);
    }
    catch {
        throw new Error(`无效的服务器 URL: ${config.serverUrl}`);
    }
    if (!config.apiKey || config.apiKey.length === 0) {
        throw new Error('缺少 API Key 配置');
    }
    if (!config.encryptionKey || config.encryptionKey.length === 0) {
        throw new Error('缺少加密密钥配置');
    }
    // 检查 API Key 格式
    if (!config.apiKey.startsWith('mk_')) {
        console.warn('⚠️ 警告: API Key 格式可能不正确，应以 "mk_" 开头');
    }
}
//# sourceMappingURL=config.js.map
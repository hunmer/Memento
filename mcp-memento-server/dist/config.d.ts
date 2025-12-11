/**
 * Memento MCP Server 配置管理
 */
import type { MementoConfig } from './types/index.js';
/**
 * 从环境变量加载配置
 */
export declare function loadConfig(): MementoConfig;
/**
 * 验证配置
 */
export declare function validateConfig(config: MementoConfig): void;
//# sourceMappingURL=config.d.ts.map
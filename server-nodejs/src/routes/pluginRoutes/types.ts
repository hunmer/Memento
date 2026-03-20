/**
 * 插件处理器类型定义
 */

/**
 * 插件处理器类型
 */
export interface PluginHandlers {
  [key: string]: (
    userId: string,
    encryptionKey: string,
    params: Record<string, unknown>,
    req?: unknown
  ) => Promise<PluginResult>;
}

/**
 * 插件结果类型
 */
export interface PluginResult {
  isSuccess: boolean;
  data?: unknown;
  message?: string;
  code?: string;
}

/**
 * 分页参数
 */
export interface PaginationParams {
  offset?: number;
  count?: number;
}

/**
 * 分页结果
 */
export interface PaginatedResult<T> {
  data: T[];
  total: number;
  offset: number;
  count: number;
  hasMore: boolean;
}

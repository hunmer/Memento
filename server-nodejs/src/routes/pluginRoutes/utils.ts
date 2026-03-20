import { Response } from 'express';
import { PluginResult } from './types';

/**
 * 错误码到 HTTP 状态码的映射
 */
export function errorCodeToStatus(code?: string): number {
  switch (code) {
    case 'NOT_FOUND':
      return 404;
    case 'INVALID_PARAMS':
      return 400;
    case 'UNAUTHORIZED':
      return 401;
    case 'FORBIDDEN':
      return 403;
    case 'CONFLICT':
      return 409;
    default:
      return 500;
  }
}

/**
 * 错误响应
 */
export function errorResponse(res: Response, statusCode: number, message: string): void {
  res.status(statusCode).json({
    success: false,
    error: message,
    timestamp: new Date().toISOString(),
  });
}

/**
 * 结果转换为 HTTP 响应
 */
export function resultToResponse<T>(
  res: Response,
  result: {
    isSuccess: boolean;
    data?: T;
    message?: string;
    code?: string;
  },
  successStatus: number = 200
): void {
  if (result.isSuccess) {
    res.status(successStatus).json({
      success: true,
      data: result.data,
      timestamp: new Date().toISOString(),
    });
  } else {
    const statusCode = errorCodeToStatus(result.code);
    res.status(statusCode).json({
      success: false,
      error: result.message,
      code: result.code,
      timestamp: new Date().toISOString(),
    });
  }
}

/**
 * 生成 UUID
 */
export function generateUUID(): string {
  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, (c) => {
    const r = (Math.random() * 16) | 0;
    const v = c === 'x' ? r : (r & 0x3) | 0x8;
    return v.toString(16);
  });
}

/**
 * 格式化日期为文件名格式 (YYYY-MM-DD)
 */
export function formatDate(date: Date): string {
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const day = String(date.getDate()).padStart(2, '0');
  return `${year}-${month}-${day}`;
}

/**
 * 创建分页结果
 */
export function createPaginatedResult<T>(
  items: T[],
  params: { offset?: number; count?: number }
): { data: T[]; total: number; offset: number; count: number; hasMore: boolean } {
  const offset = params.offset || 0;
  const count = params.count || 100;
  const total = items.length;
  const paginatedItems = items.slice(offset, offset + count);

  return {
    data: paginatedItems,
    total,
    offset,
    count: paginatedItems.length,
    hasMore: offset + paginatedItems.length < total,
  };
}

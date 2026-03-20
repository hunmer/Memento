// ==================== 用户相关类型 ====================

export interface DeviceInfo {
  deviceId: string;
  deviceName: string;
  createdAt: Date;
  lastSyncAt?: Date;
}

export interface UserInfo {
  id: string;
  username: string;
  passwordHash: string;
  salt: string;
  createdAt: Date;
  lastLoginAt?: Date;
  devices: DeviceInfo[];
}

// ==================== 认证相关类型 ====================

export interface RegisterRequest {
  username: string;
  password: string;
  deviceId: string;
  deviceName: string;
}

export interface LoginRequest {
  username: string;
  password: string;
  deviceId: string;
  deviceName?: string;
}

export interface RefreshTokenRequest {
  token: string;
  deviceId: string;
}

export interface AuthResponse {
  success: boolean;
  userId?: string;
  token?: string;
  expiresAt?: Date;
  userSalt?: string;
  error?: string;
}

export interface JWTPayload {
  sub: string;
  iat: number;
  exp: number;
}

// ==================== API Key 类型 ====================

export type ApiKeyExpiry = '7days' | '30days' | '90days' | '1year' | 'never';

export interface ApiKey {
  id: string;
  userId: string;
  name: string;
  key: string;
  keyHash: string;
  createdAt: Date;
  lastUsedAt?: Date;
  expiresAt?: Date;
  isRevoked: boolean;
}

export interface ApiKeyValidationResult {
  userId: string;
  keyId: string;
  keyName: string;
}

export interface ApiKeySafe {
  id: string;
  name: string;
  createdAt: Date;
  lastUsedAt?: Date;
  expiresAt?: Date;
  isRevoked: boolean;
  isExpired: boolean;
}

// ==================== 文件相关类型 ====================

export interface FileInfo {
  path: string;
  size?: number;
  md5?: string;
  updatedAt: Date;
  isFolder: boolean;
}

export interface FolderNode {
  name: string;
  path: string;
  isFolder: boolean;
  children?: FolderNode[];
  size?: number;
  updatedAt?: Date;
}

export interface FileIndex {
  version: number;
  updatedAt: string;
  files: Record<string, {
    md5: string;
    size: number;
    updatedAt: string;
  }>;
}

// ==================== 加密相关类型 ====================

export interface EncryptedFile {
  encrypted_data: string;
  md5: string;
  updated_at: string;
  is_binary?: boolean;
}

// ==================== 结果类型 ====================

export type Result<T> = Success<T> | Failure<T>;

export interface Success<T> {
  isSuccess: true;
  data: T;
  dataOrNull: T;
}

export interface Failure<T> {
  isSuccess: false;
  message: string;
  code?: string;
  dataOrNull: null;
}

export const ErrorCodes = {
  notFound: 'NOT_FOUND',
  invalidParams: 'INVALID_PARAMS',
  unauthorized: 'UNAUTHORIZED',
  forbidden: 'FORBIDDEN',
  internal: 'INTERNAL_ERROR',
} as const;

// ==================== 插件数据类型 ====================

export interface PaginatedResult<T> {
  data: T[];
  total: number;
  offset: number;
  count: number;
  hasMore: boolean;
}

// ==================== WebSocket 类型 ====================

export interface WSAuthMessage {
  type: 'auth';
  token: string;
  device_id: string;
}

export interface WSAuthSuccess {
  type: 'auth_success';
  user_id: string;
}

export interface WSAuthError {
  type: 'auth_error';
  error: string;
}

export interface WSPong {
  type: 'pong';
}

export interface WSFileUpdate {
  type: 'file_updated';
  data: {
    file_path: string;
    md5: string;
    modified_at: string;
    source_device_id: string;
  };
}

export type WSMessage = WSAuthMessage | WSAuthSuccess | WSAuthError | WSPong | WSFileUpdate;

// ==================== 请求上下文类型 ====================

export interface AuthContext {
  userId: string;
  keyId?: string;
  keyName?: string;
  isApiKey: boolean;
}

export interface RequestWithAuth extends Express.Request {
  context?: {
    userId?: string;
    authContext?: AuthContext;
  };
}

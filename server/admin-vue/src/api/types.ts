// ==================== 通用响应 ====================
export interface ApiResponse<T = unknown> {
  success: boolean
  data?: T
  error?: string
  timestamp?: string
}

// ==================== 认证相关 ====================
export interface LoginRequest {
  username: string
  password: string
  device_id: string
  device_name: string
}

export interface LoginResponse {
  success: boolean
  token: string
  user_id: string
  expires_at: string
  user_salt?: string
  error?: string
}

export interface ApiKey {
  id: string
  name: string
  key_prefix: string
  expires_at?: string
  last_used_at?: string
  is_expired: boolean
  created_at: string
}

export interface CreateApiKeyRequest {
  name: string
  expiry: 'never' | '7days' | '30days' | '90days' | '1year'
}

export interface CreateApiKeyResponse {
  success: boolean
  api_key?: {
    id: string
    name: string
    key: string
    key_prefix: string
    expires_at?: string
  }
  error?: string
}

export interface EncryptionKeyStatus {
  success: boolean
  has_key: boolean
  user_id: string
}

// ==================== 文件同步相关 ====================
export interface SyncFile {
  path: string
  size: number
  updated_at: string
  is_binary?: boolean
  md5?: string
}

export interface FileListResponse {
  success: boolean
  files: SyncFile[]
  timestamp: string
}

export interface TreeNode {
  name: string
  path: string
  is_folder: boolean
  size?: number
  updated_at?: string
  children?: TreeNode[]
}

export interface TreeResponse {
  success: boolean
  tree: TreeNode
}

export interface ExportResponse {
  success: boolean
  file_name?: string
  metadata?: {
    file_count: number
    total_size: number
    total_size_mb: string
  }
  error?: string
}

// ==================== 状态相关 ====================
export interface ServerStatus {
  success: boolean
  user_id: string
  file_count: number
  total_size_bytes: number
  total_size_mb: string
  timestamp: string
}

export interface ReEncryptResponse {
  success: boolean
  files_re_encrypted?: number
  errors?: string[]
  error?: string
}

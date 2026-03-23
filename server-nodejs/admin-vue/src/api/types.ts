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

export interface UserInfo {
  username: string
  created_at: string
  sync_folder_count: number
  sync_file_count: number
  sync_total_size: number
  sync_total_size_mb: string
}

export interface UserInfoResponse {
  success: boolean
  user_info?: UserInfo
  error?: string
  timestamp?: string
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
  is_folder?: boolean
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

// ==================== 插件系统相关 ====================

/** 插件权限 */
export interface PluginPermissions {
  dataAccess: string[]
  operations: ('create' | 'read' | 'update' | 'delete')[]
  networkAccess: boolean
}

/** 已安装的插件 */
export interface InstalledPlugin {
  uuid: string
  title: string
  author: string
  description: string
  version: string
  website?: string
  permissions: PluginPermissions
  updateURL?: string
  priority?: number
  events?: string[]
  status: 'installed' | 'enabled' | 'disabled'
  pluginPath: string
  installedAt: string
  updatedAt: string
}

/** 商店插件 */
export interface StorePlugin {
  uuid: string
  title: string
  author: string
  description: string
  version: string
  website?: string
  permissions: PluginPermissions
  updateURL?: string
  priority?: number
  events?: string[]
  downloadURL: string
  sourceURL: string
}

/** 商店配置 */
export interface StoreConfig {
  storeURL: string
  lastSyncAt?: string
  syncInterval: number
}

/** 插件列表响应 */
export interface PluginListResponse {
  success: boolean
  plugins: InstalledPlugin[]
  total: number
  timestamp: string
}

/** 商店列表响应 */
export interface StoreListResponse {
  success: boolean
  plugins: StorePlugin[]
  sourceURL: string
  lastSyncAt?: string
  total: number
  timestamp: string
}

/** 插件操作响应 */
export interface PluginOperationResponse {
  success: boolean
  message?: string
  uuid?: string
  error?: string
  timestamp: string
}

/** 商店配置响应 */
export interface StoreConfigResponse {
  success: boolean
  config: StoreConfig
  timestamp: string
}

// ==================== 设备管理相关 ====================

/** 设备信息 */
export interface Device {
  device_id: string
  device_name: string
  created_at: string
  last_sync_at?: string
  fcm_token?: string
  platform?: string
}

/** 设备列表响应 */
export interface DevicesListResponse {
  success: boolean
  devices: Device[]
  count: number
  timestamp?: string
}

/** 注册设备请求 */
export interface RegisterDeviceRequest {
  device_id: string
  device_name: string
  fcm_token?: string
  platform?: string
}

/** 注册设备响应 */
export interface RegisterDeviceResponse {
  success: boolean
  message?: string
  device?: Device
  error?: string
}

/** 推送消息请求 */
export interface PushMessageRequest {
  device_id?: string
  title: string
  body: string
  data?: Record<string, string>
}

/** 推送消息响应 */
export interface PushMessageResponse {
  success: boolean
  message?: string
  sent_count?: number
  error?: string
}

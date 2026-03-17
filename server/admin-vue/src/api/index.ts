import type { ApiResponse, LoginRequest, LoginResponse } from './types'

const DEFAULT_SERVER = 'http://localhost:8874'

// API 客户端类
class ApiClient {
  private _baseUrl: string = ''
  private _token: string | null = null

  constructor() {
    this._baseUrl = localStorage.getItem('serverUrl') || DEFAULT_SERVER
    this._token = localStorage.getItem('token')
  }

  setBaseUrl(url: string): void {
    this._baseUrl = url
    localStorage.setItem('serverUrl', url)
  }

  getBaseUrl(): string {
    return this._baseUrl
  }

  setToken(token: string | null): void {
    this._token = token
    if (token) {
      localStorage.setItem('token', token)
    } else {
      localStorage.removeItem('token')
    }
  }

  getToken(): string | null {
    return this._token
  }

  async request<T>(
    endpoint: string,
    options: RequestInit = {},
    extraHeaders: Record<string, string> = {}
  ): Promise<T> {
    const url = `${this._baseUrl}${endpoint}`

    const headers: Record<string, string> = {
      'Content-Type': 'application/json',
      ...extraHeaders
    }

    if (this._token) {
      headers['Authorization'] = `Bearer ${this._token}`
    }

    const response = await fetch(url, {
      ...options,
      headers
    })

    // 处理 401/403 认证错误
    if (response.status === 401 || response.status === 403) {
      this.setToken(null)
      localStorage.removeItem('username')
      throw new Error('登录已过期，请重新登录')
    }

    if (!response.ok) {
      const errorData = await response.json().catch(() => ({}))
      throw new Error(errorData.error || `HTTP Error: ${response.status}`)
    }

    return response.json()
  }

  async healthCheck(): Promise<boolean> {
    try {
      const response = await fetch(`${this._baseUrl}/health`)
      return response.ok
    } catch {
      return false
    }
  }

  async downloadFile(url: string): Promise<Blob> {
    const headers: Record<string, string> = {}
    if (this._token) {
      headers['Authorization'] = `Bearer ${this._token}`
    }

    const response = await fetch(url, { headers })

    if (!response.ok) {
      throw new Error('下载失败')
    }

    return response.blob()
  }
}

// 单例实例
export const apiClient = new ApiClient()

// 类型定义
interface ApiKeyInfo {
  id: string
  name: string
  key_prefix: string
  expires_at?: string
  last_used_at?: string
  is_expired: boolean
  created_at: string
}

interface CreatedApiKeyInfo {
  id: string
  name: string
  key: string
  key_prefix: string
  expires_at?: string
}

interface SyncFileInfo {
  path: string
  size: number
  updated_at: string
  is_binary?: boolean
  md5?: string
}

// 认证 API
export const authApi = {
  login: (data: LoginRequest): Promise<LoginResponse> =>
    apiClient.request('/api/v1/auth/login', {
      method: 'POST',
      body: JSON.stringify(data)
    }),

  hasEncryptionKey: (): Promise<{ success: boolean; has_key: boolean }> =>
    apiClient.request('/api/v1/auth/has-encryption-key'),

  setEncryptionKey: (key: string): Promise<ApiResponse> =>
    apiClient.request('/api/v1/auth/set-encryption-key', {
      method: 'POST',
      body: JSON.stringify({ encryption_key: key })
    }),

  clearEncryptionKey: (): Promise<ApiResponse> =>
    apiClient.request('/api/v1/auth/clear-encryption-key', {
      method: 'POST'
    }),

  getApiKeys: (): Promise<{ success: boolean; api_keys?: ApiKeyInfo[] }> =>
    apiClient.request('/api/v1/auth/api-keys'),

  createApiKey: (data: {
    name: string
    expiry: 'never' | '7days' | '30days' | '90days' | '1year'
  }): Promise<{ success: boolean; api_key?: CreatedApiKeyInfo; error?: string }> =>
    apiClient.request('/api/v1/auth/api-keys', {
      method: 'POST',
      body: JSON.stringify(data)
    }),

  revokeApiKey: (keyId: string): Promise<ApiResponse> =>
    apiClient.request(`/api/v1/auth/api-keys/${keyId}`, {
      method: 'DELETE'
    })
}

// 同步 API
export const syncApi = {
  getFiles: (): Promise<{ success: boolean; files: SyncFileInfo[] }> =>
    apiClient.request('/api/v1/sync/list'),

  getStatus: (): Promise<{
    success: boolean
    user_id: string
    file_count: number
    total_size_bytes: number
    total_size_mb: string
    timestamp: string
  }> => apiClient.request('/api/v1/sync/status'),

  deleteFile: (filePath: string): Promise<ApiResponse> =>
    apiClient.request(`/api/v1/sync/delete/${encodeURIComponent(filePath)}`, {
      method: 'DELETE'
    }),

  downloadDecrypted: (
    filePath: string,
    encryptionKey: string
  ): Promise<{ success: boolean; data: unknown }> =>
    apiClient.request(
      `/api/v1/sync/pull-decrypted/${encodeURIComponent(filePath)}`,
      {},
      { 'X-Encryption-Key': encryptionKey }
    ),

  exportData: (): Promise<{
    success: boolean
    file_name?: string
    metadata?: { file_count: number; total_size_mb: string }
    error?: string
  }> =>
    apiClient.request('/api/v1/sync/export', {
      method: 'POST'
    }),

  getDownloadUrl: (fileName: string): string =>
    `${apiClient.getBaseUrl()}/api/v1/sync/download/${encodeURIComponent(fileName)}`,

  downloadExportFile: (fileName: string): Promise<Blob> =>
    apiClient.downloadFile(syncApi.getDownloadUrl(fileName))
}

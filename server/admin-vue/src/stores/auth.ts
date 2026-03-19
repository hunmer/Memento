import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { apiClient, authApi } from '@/api'

interface ApiKey {
  id: string
  name: string
  key_prefix: string
  expires_at?: string
  last_used_at?: string
  is_expired: boolean
  created_at: string
}

export const useAuthStore = defineStore('auth', () => {
  // 状态
  const isLoggedIn = ref(false)
  const username = ref(localStorage.getItem('username') || '')
  const encryptionKey = ref(localStorage.getItem('encryptionKey') || '')
  const serverUrl = ref(localStorage.getItem('serverUrl') || 'http://localhost:8874')
  const loading = ref(false)
  const error = ref<string | null>(null)

  // 后端加密密钥状态
  const serverHasKey = ref<boolean | null>(null)

  // API Keys
  const apiKeys = ref<ApiKey[]>([])
  const createdKey = ref<{ name: string; key: string } | null>(null)

  // 计算属性
  const hasEncryptionKey = computed(() => !!encryptionKey.value || serverHasKey.value === true)

  // 登录方法
  async function login(
    usernameInput: string,
    password: string,
    serverUrlInput?: string
  ): Promise<void> {
    loading.value = true
    error.value = null

    try {
      // 设置服务器地址
      if (serverUrlInput) {
        serverUrl.value = serverUrlInput
        apiClient.setBaseUrl(serverUrlInput)
      }

      // 调用登录 API
      const response = await authApi.login({
        username: usernameInput,
        password,
        device_id: 'admin_panel',
        device_name: 'Admin Panel'
      })

      if (!response.success) {
        throw new Error(response.error || '登录失败')
      }

      // 保存状态
      username.value = usernameInput
      isLoggedIn.value = true
      apiClient.setToken(response.token)
      localStorage.setItem('username', usernameInput)

      // 从后端检查加密密钥状态
      try {
        const keyStatus = await authApi.hasEncryptionKey()
        serverHasKey.value = keyStatus.has_key
        if (!keyStatus.has_key) {
          // 后端没有密钥，清除本地的
          clearEncryptionKey()
        }
      } catch (e) {
        console.warn('Failed to check encryption key status:', e)
        serverHasKey.value = null
      }
    } catch (err) {
      error.value = err instanceof Error ? err.message : '登录失败'
      throw err
    } finally {
      loading.value = false
    }
  }

  function logout(): void {
    isLoggedIn.value = false
    username.value = ''
    encryptionKey.value = ''
    serverHasKey.value = null
    apiClient.setToken(null)
    localStorage.removeItem('token')
    localStorage.removeItem('username')
    localStorage.removeItem('encryptionKey')
  }

  function setEncryptionKey(key: string): void {
    encryptionKey.value = key
    localStorage.setItem('encryptionKey', key)
  }

  function clearEncryptionKey(): void {
    encryptionKey.value = ''
    localStorage.removeItem('encryptionKey')
  }

  async function loadApiKeys(): Promise<void> {
    try {
      const response = await authApi.getApiKeys()
      apiKeys.value = response.api_keys || []
    } catch (err) {
      console.error('Failed to load API keys:', err)
      apiKeys.value = []
    }
  }

  async function createApiKey(data: {
    name: string
    expiry: 'never' | '7days' | '30days' | '90days' | '1year'
  }): Promise<void> {
    const response = await authApi.createApiKey(data)
    if (!response.success || !response.api_key) {
      throw new Error(response.error || '创建失败')
    }
    createdKey.value = {
      name: response.api_key.name,
      key: response.api_key.key
    }
    await loadApiKeys()
  }

  async function revokeApiKey(keyId: string): Promise<void> {
    const response = await authApi.revokeApiKey(keyId)
    if (!response.success) {
      throw new Error(response.error || '撤销失败')
    }
    await loadApiKeys()
  }

  function clearCreatedKey(): void {
    createdKey.value = null
  }

  // 初始化检查
  function init(): void {
    const token = localStorage.getItem('token')
    if (token && username.value) {
      apiClient.setToken(token)
      isLoggedIn.value = true
    }
    if (serverUrl.value) {
      apiClient.setBaseUrl(serverUrl.value)
    }
  }

  return {
    // 状态
    isLoggedIn,
    username,
    encryptionKey,
    serverUrl,
    serverHasKey,
    apiKeys,
    createdKey,
    loading,
    error,

    // 计算属性
    hasEncryptionKey,

    // 方法
    login,
    logout,
    setEncryptionKey,
    clearEncryptionKey,
    loadApiKeys,
    createApiKey,
    revokeApiKey,
    clearCreatedKey,
    init
  }
})

import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { apiClient } from '../api'
import type {
  InstalledPlugin,
  StorePlugin,
  StoreConfig,
  PluginListResponse,
  StoreListResponse,
  StoreConfigResponse,
  PluginOperationResponse
} from '../api/types'

export const usePluginsStore = defineStore('plugins', () => {
  // 状态
  const installedPlugins = ref<InstalledPlugin[]>([])
  const storePlugins = ref<StorePlugin[]>([])
  const storeConfig = ref<StoreConfig>({
    storeURL: '',
    syncInterval: 0
  })
  const loading = ref(false)
  const error = ref<string | null>(null)

  // 计算属性
  const enabledPlugins = computed(() =>
    installedPlugins.value.filter(p => p.status === 'enabled')
  )

  const disabledPlugins = computed(() =>
    installedPlugins.value.filter(p => p.status === 'disabled')
  )

  // 已安装插件的 UUID 集合
  const installedUuids = computed(() =>
    new Set(installedPlugins.value.map(p => p.uuid))
  )

  // 商店中可安装的插件（未安装的）
  const availablePlugins = computed(() =>
    storePlugins.value.filter(p => !installedUuids.value.has(p.uuid))
  )

  // 商店中有更新的插件
  const updatablePlugins = computed(() =>
    storePlugins.value.filter(storePlugin => {
      const installed = installedPlugins.value.find(p => p.uuid === storePlugin.uuid)
      if (!installed) return false
      return storePlugin.version !== installed.version
    })
  )

  // 操作

  /** 获取已安装插件列表 */
  async function fetchInstalledPlugins() {
    loading.value = true
    error.value = null
    try {
      const response = await apiClient.request<PluginListResponse>('/api/v1/system/plugins')
      if (response.success) {
        installedPlugins.value = response.plugins
      }
    } catch (e) {
      error.value = e instanceof Error ? e.message : String(e)
    } finally {
      loading.value = false
    }
  }

  /** 获取商店插件列表 */
  async function fetchStorePlugins() {
    loading.value = true
    error.value = null
    try {
      const response = await apiClient.request<StoreListResponse>('/api/v1/system/plugins/store')
      if (response.success) {
        storePlugins.value = response.plugins
        storeConfig.value.storeURL = response.sourceURL
        if (response.lastSyncAt) {
          storeConfig.value.lastSyncAt = response.lastSyncAt
        }
      }
    } catch (e) {
      error.value = e instanceof Error ? e.message : String(e)
    } finally {
      loading.value = false
    }
  }

  /** 获取商店配置 */
  async function fetchStoreConfig() {
    try {
      const response = await apiClient.request<StoreConfigResponse>('/api/v1/system/plugins/config')
      if (response.success) {
        storeConfig.value = response.config
      }
    } catch (e) {
      error.value = e instanceof Error ? e.message : String(e)
    }
  }

  /** 更新商店配置 */
  async function updateStoreConfig(config: Partial<StoreConfig>) {
    try {
      const response = await apiClient.request<StoreConfigResponse>('/api/v1/system/plugins/config', {
        method: 'PUT',
        body: JSON.stringify(config)
      })
      if (response.success) {
        storeConfig.value = response.config
        return true
      }
      return false
    } catch (e) {
      error.value = e instanceof Error ? e.message : String(e)
      return false
    }
  }

  /** 上传并安装插件 */
  async function uploadPlugin(file: File) {
    loading.value = true
    error.value = null
    try {
      const formData = new FormData()
      formData.append('plugin', file)

      const response = await fetch(`${apiClient.getBaseUrl()}/api/v1/system/plugins/upload`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${apiClient.getToken()}`
        },
        body: formData
      })

      const data = await response.json()
      if (response.ok && data.success) {
        await fetchInstalledPlugins()
        return data.plugin
      } else {
        throw new Error(data.error || '上传失败')
      }
    } catch (e) {
      error.value = e instanceof Error ? e.message : String(e)
      throw e
    } finally {
      loading.value = false
    }
  }

  /** 从商店安装插件 */
  async function installFromStore(downloadURL: string) {
    loading.value = true
    error.value = null
    try {
      const response = await apiClient.request<{ success: boolean; plugin?: InstalledPlugin; error?: string }>('/api/v1/system/plugins/store/install', {
        method: 'POST',
        body: JSON.stringify({ downloadURL })
      })
      if (response.success) {
        await fetchInstalledPlugins()
        return response.plugin
      } else {
        throw new Error(response.error || '安装失败')
      }
    } catch (e) {
      error.value = e instanceof Error ? e.message : String(e)
      throw e
    } finally {
      loading.value = false
    }
  }

  /** 启用插件 */
  async function enablePlugin(uuid: string) {
    try {
      const response = await apiClient.request<PluginOperationResponse>(`/api/v1/system/plugins/${uuid}/enable`, {
        method: 'POST'
      })
      if (response.success) {
        const plugin = installedPlugins.value.find(p => p.uuid === uuid)
        if (plugin) {
          plugin.status = 'enabled'
        }
        return true
      }
      return false
    } catch (e) {
      error.value = e instanceof Error ? e.message : String(e)
      return false
    }
  }

  /** 禁用插件 */
  async function disablePlugin(uuid: string) {
    try {
      const response = await apiClient.request<PluginOperationResponse>(`/api/v1/system/plugins/${uuid}/disable`, {
        method: 'POST'
      })
      if (response.success) {
        const plugin = installedPlugins.value.find(p => p.uuid === uuid)
        if (plugin) {
          plugin.status = 'disabled'
        }
        return true
      }
      return false
    } catch (e) {
      error.value = e instanceof Error ? e.message : String(e)
      return false
    }
  }

  /** 卸载插件 */
  async function uninstallPlugin(uuid: string) {
    try {
      const response = await apiClient.request<PluginOperationResponse>(`/api/v1/system/plugins/${uuid}`, {
        method: 'DELETE'
      })
      if (response.success) {
        installedPlugins.value = installedPlugins.value.filter(p => p.uuid !== uuid)
        return true
      }
      return false
    } catch (e) {
      error.value = e instanceof Error ? e.message : String(e)
      return false
    }
  }

  /** 检查插件是否已安装 */
  function isInstalled(uuid: string): boolean {
    return installedUuids.value.has(uuid)
  }

  return {
    // 状态
    installedPlugins,
    storePlugins,
    storeConfig,
    loading,
    error,

    // 计算属性
    enabledPlugins,
    disabledPlugins,
    installedUuids,
    availablePlugins,
    updatablePlugins,

    // 操作
    fetchInstalledPlugins,
    fetchStorePlugins,
    fetchStoreConfig,
    updateStoreConfig,
    uploadPlugin,
    installFromStore,
    enablePlugin,
    disablePlugin,
    uninstallPlugin,
    isInstalled
  }
})

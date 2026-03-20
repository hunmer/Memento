import { defineStore } from 'pinia'
import { ref } from 'vue'

export type TabId = 'overview' | 'files' | 'apikeys' | 'plugins' | 'settings'
export type ServerStatus = 'online' | 'offline'

export interface Activity {
  id: number
  type: string
  message: string
  time: string
}

export const useUIStore = defineStore('ui', () => {
  // 状态
  const activeTab = ref<TabId>('overview')
  const loading = ref(false)
  const loadingMessage = ref('')
  const serverStatus = ref<ServerStatus>('offline')

  // 活动记录
  const recentActivities = ref<Activity[]>([])

  // 加载状态
  function setLoading(isLoading: boolean, message = ''): void {
    loading.value = isLoading
    loadingMessage.value = message
  }

  // 添加活动记录
  function addActivity(type: string, message: string): void {
    recentActivities.value.unshift({
      id: Date.now(),
      type,
      message,
      time: new Date().toISOString()
    })
    if (recentActivities.value.length > 10) {
      recentActivities.value.pop()
    }
  }

  // 切换 Tab
  function setTab(tab: TabId): void {
    activeTab.value = tab
  }

  // 设置服务器状态
  function setServerStatus(status: ServerStatus): void {
    serverStatus.value = status
  }

  return {
    // 状态
    activeTab,
    loading,
    loadingMessage,
    serverStatus,
    recentActivities,

    // 方法
    setLoading,
    addActivity,
    setTab,
    setServerStatus
  }
})

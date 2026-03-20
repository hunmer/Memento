<script setup lang="ts">
import { onMounted } from 'vue'
import { useMessage, useDialog } from 'naive-ui'
import { useAuthStore } from '@/stores/auth'
import { useUIStore } from '@/stores/ui'
import { useFilesStore } from '@/stores/files'
import { apiClient } from '@/api'

// 全局类型声明 - 使用 ReturnType 避免导入不存在的类型
declare global {
  interface Window {
    $message?: ReturnType<typeof useMessage>
    $dialog?: ReturnType<typeof useDialog>
  }
}

const authStore = useAuthStore()
const uiStore = useUIStore()
const filesStore = useFilesStore()

// 初始化全局 Naive UI 实例（必须在 Provider 内部调用）
window.$message = useMessage()
window.$dialog = useDialog()

onMounted(async () => {
  authStore.init()

  if (authStore.isLoggedIn) {
    try {
      await loadDashboardData()
    } catch (error) {
      console.log('Initial load failed:', error)
    }
  }

  // 定期检查服务器状态
  setInterval(checkServerHealth, 30000)
})

async function loadDashboardData(): Promise<void> {
  await Promise.all([
    checkServerHealth(),
    filesStore.loadFiles(),
    authStore.loadApiKeys()
  ])
}

async function checkServerHealth(): Promise<void> {
  const isOnline = await apiClient.healthCheck()
  uiStore.setServerStatus(isOnline ? 'online' : 'offline')
}
</script>

<template>
  <slot></slot>
</template>

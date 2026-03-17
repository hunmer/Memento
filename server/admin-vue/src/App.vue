<script setup lang="ts">
import { onMounted } from 'vue'
import {
  NConfigProvider,
  NMessageProvider,
  NDialogProvider,
  NLayout,
  NLayoutContent,
  NNotificationProvider
} from 'naive-ui'
import { useAuthStore } from '@/stores/auth'
import { useUIStore } from '@/stores/ui'
import { useFilesStore } from '@/stores/files'
import { apiClient } from '@/api'

import AppHeader from '@/components/layout/AppHeader.vue'
import TabNavigation from '@/components/layout/TabNavigation.vue'
import LoginForm from '@/components/login/LoginForm.vue'
import OverviewTab from '@/components/overview/OverviewTab.vue'
import FilesTab from '@/components/files/FilesTab.vue'
import ApiKeysTab from '@/components/api-keys/ApiKeysTab.vue'
import SettingsTab from '@/components/settings/SettingsTab.vue'
import LoadingOverlay from '@/components/common/LoadingOverlay.vue'

const authStore = useAuthStore()
const uiStore = useUIStore()
const filesStore = useFilesStore()

// 全局 message 实例
declare global {
  interface Window {
    $message?: {
      success: (msg: string) => void
      error: (msg: string) => void
      warning: (msg: string) => void
      info: (msg: string) => void
    }
    $dialog?: {
      warning: (options: {
        title: string
        content: string
        positiveText: string
        negativeText: string
        onPositiveClick?: () => void
      }) => boolean
    }
  }
}

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
  <NConfigProvider>
    <NMessageProvider>
      <NDialogProvider>
        <NNotificationProvider>
          <NLayout class="app-layout">
            <!-- Header -->
            <AppHeader v-if="authStore.isLoggedIn" />

            <!-- Main Content -->
            <NLayoutContent class="main-content">
              <!-- Login Form -->
              <LoginForm v-if="!authStore.isLoggedIn" />

              <!-- Dashboard -->
              <template v-else>
                <TabNavigation />

                <div class="tab-content">
                  <OverviewTab v-show="uiStore.activeTab === 'overview'" />
                  <FilesTab v-show="uiStore.activeTab === 'files'" />
                  <ApiKeysTab v-show="uiStore.activeTab === 'apikeys'" />
                  <SettingsTab v-show="uiStore.activeTab === 'settings'" />
                </div>
              </template>
            </NLayoutContent>

            <!-- Loading Overlay -->
            <LoadingOverlay />
          </NLayout>
        </NNotificationProvider>
      </NDialogProvider>
    </NMessageProvider>
  </NConfigProvider>
</template>

<style>
* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

body {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto,
    'Helvetica Neue', Arial, sans-serif;
  background-color: #f5f5f5;
}

.app-layout {
  min-height: 100vh;
}

.main-content {
  max-width: 1200px;
  margin: 0 auto;
  padding: 24px;
}

.tab-content {
  margin-top: 16px;
}
</style>

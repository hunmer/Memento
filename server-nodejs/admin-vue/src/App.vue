<script setup lang="ts">
import { onMounted, ref } from 'vue'
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

import NaiveProviderContent from '@/components/common/NaiveProviderContent.vue'
import AppHeader from '@/components/layout/AppHeader.vue'
import TabNavigation from '@/components/layout/TabNavigation.vue'
import LoginForm from '@/components/login/LoginForm.vue'
import RegisterForm from '@/components/login/RegisterForm.vue'
import OverviewTab from '@/components/overview/OverviewTab.vue'
import FilesTab from '@/components/files/FilesTab.vue'
import ApiKeysTab from '@/components/api-keys/ApiKeysTab.vue'
import PluginsTab from '@/components/plugins/PluginsTab.vue'
import DevicesTab from '@/components/devices/DevicesTab.vue'
import SettingsTab from '@/components/settings/SettingsTab.vue'
import LoadingOverlay from '@/components/common/LoadingOverlay.vue'

const authStore = useAuthStore()
const uiStore = useUIStore()
const filesStore = useFilesStore()

// 登录/注册模式切换
const authMode = ref<'login' | 'register'>('login')
const prefillCredentials = ref<{ username: string; password: string } | null>(null)

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

// 注册成功后切换到登录页并预填充凭据
function handleRegistered(username: string, password: string): void {
  prefillCredentials.value = { username, password }
  authMode.value = 'login'
}
</script>

<template>
  <NConfigProvider>
    <NMessageProvider>
      <NDialogProvider>
        <NNotificationProvider>
          <NaiveProviderContent>
            <NLayout class="app-layout">
              <!-- Header -->
              <AppHeader v-if="authStore.isLoggedIn" />

              <!-- Main Content -->
              <NLayoutContent class="main-content">
                <!-- Auth Forms -->
                <template v-if="!authStore.isLoggedIn">
                  <LoginForm
                    v-if="authMode === 'login'"
                    :prefill-username="prefillCredentials?.username"
                    :prefill-password="prefillCredentials?.password"
                    @switch-to-register="authMode = 'register'"
                  />
                  <RegisterForm
                    v-else
                    @switch-to-login="authMode = 'login'"
                    @registered="handleRegistered"
                  />
                </template>

                <!-- Dashboard -->
                <template v-else>
                  <TabNavigation />

                  <div class="tab-content">
                    <OverviewTab v-show="uiStore.activeTab === 'overview'" />
                    <FilesTab v-show="uiStore.activeTab === 'files'" />
                    <ApiKeysTab v-show="uiStore.activeTab === 'apikeys'" />
                    <PluginsTab v-show="uiStore.activeTab === 'plugins'" />
                    <DevicesTab v-show="uiStore.activeTab === 'devices'" />
                    <SettingsTab v-show="uiStore.activeTab === 'settings'" />
                  </div>
                </template>
              </NLayoutContent>

              <!-- Loading Overlay -->
              <LoadingOverlay />
            </NLayout>
          </NaiveProviderContent>
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

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { NCard, NSpace } from 'naive-ui'
import { useUIStore } from '@/stores/ui'
import { useFilesStore } from '@/stores/files'
import { useAuthStore } from '@/stores/auth'
import { authApi } from '@/api'
import type { UserInfo } from '@/api/types'
import StatsGrid from './StatsGrid.vue'
import ActivityList from './ActivityList.vue'

const uiStore = useUIStore()
const filesStore = useFilesStore()
const authStore = useAuthStore()

const userInfo = ref<UserInfo | null>(null)

// 加载用户信息
async function loadUserInfo(): Promise<void> {
  try {
    const response = await authApi.getUserInfo()
    if (response.success && response.user_info) {
      userInfo.value = response.user_info
    }
  } catch (err) {
    console.error('Failed to load user info:', err)
  }
}

function handleApiClick(): void {
  uiStore.setTab('settings')
}

onMounted(() => {
  loadUserInfo()
})
</script>

<template>
  <NSpace vertical :size="16">
    <StatsGrid
      :total-files="filesStore.stats.totalFiles"
      :total-size="filesStore.formattedTotalSize"
      :server-status="uiStore.serverStatus"
      :api-enabled="authStore.hasEncryptionKey"
      :user-info="userInfo"
      @click-api="handleApiClick"
    />

    <NCard title="最近活动">
      <ActivityList :activities="uiStore.recentActivities" />
    </NCard>
  </NSpace>
</template>

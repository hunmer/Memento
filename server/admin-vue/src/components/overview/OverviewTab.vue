<script setup lang="ts">
import { NCard, NSpace } from 'naive-ui'
import { useUIStore } from '@/stores/ui'
import { useFilesStore } from '@/stores/files'
import { useAuthStore } from '@/stores/auth'
import StatsGrid from './StatsGrid.vue'
import ActivityList from './ActivityList.vue'

const uiStore = useUIStore()
const filesStore = useFilesStore()
const authStore = useAuthStore()

function handleApiClick(): void {
  uiStore.setTab('settings')
}
</script>

<template>
  <NSpace vertical :size="16">
    <StatsGrid
      :total-files="filesStore.stats.totalFiles"
      :total-size="filesStore.formattedTotalSize"
      :server-status="uiStore.serverStatus"
      :api-enabled="authStore.hasEncryptionKey"
      @click-api="handleApiClick"
    />

    <NCard title="最近活动">
      <ActivityList :activities="uiStore.recentActivities" />
    </NCard>
  </NSpace>
</template>

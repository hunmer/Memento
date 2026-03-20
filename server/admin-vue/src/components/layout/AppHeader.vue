<script setup lang="ts">
import { NLayoutHeader, NButton, NSpace, NText, NTag, useDialog, useMessage } from 'naive-ui'
import { useAuthStore } from '@/stores/auth'
import { useUIStore } from '@/stores/ui'

const authStore = useAuthStore()
const uiStore = useUIStore()
const dialog = useDialog()
const message = useMessage()

function handleLogout(): void {
  dialog.warning({
    title: '确认退出',
    content: '确定要退出登录吗？',
    positiveText: '退出',
    negativeText: '取消',
    onPositiveClick: () => {
      authStore.logout()
      message.success('已退出登录')
    }
  })
}
</script>

<template>
  <NLayoutHeader
    bordered
    style="
      height: 60px;
      padding: 0 24px;
      display: flex;
      align-items: center;
      justify-content: space-between;
      background: linear-gradient(135deg, #4f46e5, #7c3aed);
    "
  >
    <NSpace align="center" :size="16">
      <NText tag="h1" style="color: white; font-size: 1.25rem; font-weight: 600; margin: 0">
        Memento Sync Server
      </NText>
      <NTag
        :type="uiStore.serverStatus === 'online' ? 'success' : 'error'"
        size="small"
      >
        {{ uiStore.serverStatus === 'online' ? '在线' : '离线' }}
      </NTag>
    </NSpace>

    <NSpace align="center" :size="16">
      <NText style="color: rgba(255, 255, 255, 0.9)">
        {{ authStore.username }}
      </NText>
      <NButton ghost size="small" style="color: white" @click="handleLogout">
        退出登录
      </NButton>
    </NSpace>
  </NLayoutHeader>
</template>

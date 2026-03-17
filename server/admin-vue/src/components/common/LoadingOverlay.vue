<script setup lang="ts">
import { NSpin, NSpace } from 'naive-ui'
import { useUIStore } from '@/stores/ui'

const uiStore = useUIStore()
</script>

<template>
  <div v-if="uiStore.loading" class="loading-overlay">
    <NSpace vertical align="center" :size="16">
      <NSpin size="large" />
      <span style="color: white; font-size: 0.95rem">
        {{ uiStore.loadingMessage || '加载中...' }}
      </span>
    </NSpace>
  </div>
</template>

<style scoped>
.loading-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background-color: rgba(0, 0, 0, 0.5);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 9999;
}
</style>

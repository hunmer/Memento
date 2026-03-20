<script setup lang="ts">
import {
  NCard,
  NButton,
  NSpace,
  NPopconfirm,
  NAlert,
  useMessage
} from 'naive-ui'
import { useFilesStore } from '@/stores/files'
import { useUIStore } from '@/stores/ui'
import { syncApi } from '@/api'

const filesStore = useFilesStore()
const uiStore = useUIStore()
const message = useMessage()

async function handleExport(): Promise<void> {
  uiStore.setLoading(true, '导出 ZIP 文件...')
  try {
    const data = await syncApi.exportData()

    if (data.success && data.file_name) {
      // 下载 ZIP 文件
      const blob = await syncApi.downloadExportFile(data.file_name)
      const url = URL.createObjectURL(blob)
      const a = document.createElement('a')
      a.href = url
      a.download = data.file_name
      a.click()
      URL.revokeObjectURL(url)

      message.success(
        `数据导出成功 (${data.metadata?.file_count} 个文件, ${data.metadata?.total_size_mb} MB)`
      )
      uiStore.addActivity('export', `导出了 ${data.metadata?.file_count} 个文件`)
    } else {
      throw new Error(data.error || '导出失败')
    }
  } catch (err) {
    message.error(err instanceof Error ? err.message : '导出失败')
  } finally {
    uiStore.setLoading(false)
  }
}

async function handleClearData(): Promise<void> {
  uiStore.setLoading(true, '清空服务器数据...')
  try {
    // 删除所有文件
    for (const file of filesStore.files) {
      await syncApi.deleteFile(file.path)
    }
    await filesStore.loadFiles()
    message.success('服务器数据已清空')
    uiStore.addActivity('delete', '清空了服务器数据')
  } catch (err) {
    message.error(err instanceof Error ? err.message : '清空失败')
  } finally {
    uiStore.setLoading(false)
  }
}
</script>

<template>
  <NCard title="数据操作">
    <NSpace vertical :size="16">
      <NAlert type="warning">
        ⚠️ <strong>警告：</strong>以下操作具有破坏性，请谨慎使用！
      </NAlert>

      <NSpace :size="16">
        <NButton type="primary" @click="handleExport">📤 导出数据</NButton>

        <NPopconfirm @positive-click="handleClearData">
          <template #trigger>
            <NButton type="error">🗑️ 清空服务器数据</NButton>
          </template>
          <div style="max-width: 300px">
            <strong>⚠️ 警告</strong><br />
            此操作将删除服务器上的所有同步数据！<br />
            <strong>此操作不可恢复！</strong>
          </div>
        </NPopconfirm>
      </NSpace>
    </NSpace>
  </NCard>
</template>

<script setup lang="ts">
import { NCard, NButton, NEmpty } from 'naive-ui'
import { useFilesStore } from '@/stores/files'
import { useAuthStore } from '@/stores/auth'
import { useUIStore } from '@/stores/ui'
import { syncApi } from '@/api'
import FileTree from './FileTree.vue'

const filesStore = useFilesStore()
const authStore = useAuthStore()
const uiStore = useUIStore()

async function handleRefresh(): Promise<void> {
  uiStore.setLoading(true, '刷新文件列表...')
  try {
    await filesStore.loadFiles()
    window.$message?.success('文件列表已刷新')
  } catch (err) {
    window.$message?.error(err instanceof Error ? err.message : '刷新失败')
  } finally {
    uiStore.setLoading(false)
  }
}

async function handleDownload(filePath: string): Promise<void> {
  if (!authStore.encryptionKey) {
    window.$message?.error('请先设置加密密钥')
    return
  }

  uiStore.setLoading(true, '下载文件...')
  try {
    const result = await syncApi.downloadDecrypted(filePath, authStore.encryptionKey)

    // 下载解密后的数据
    const blob = new Blob([JSON.stringify((result as { data: unknown }).data, null, 2)], {
      type: 'application/json'
    })
    const url = URL.createObjectURL(blob)
    const a = document.createElement('a')
    a.href = url
    a.download = filePath.split('/').pop() || 'file.json'
    a.click()
    URL.revokeObjectURL(url)

    window.$message?.success('下载成功（已解密）')
    uiStore.addActivity('download', `下载了文件 ${filePath}`)
  } catch (err) {
    window.$message?.error(err instanceof Error ? err.message : '下载失败')
  } finally {
    uiStore.setLoading(false)
  }
}

async function handleDelete(filePath: string): Promise<void> {
  uiStore.setLoading(true, '删除文件...')
  try {
    await filesStore.deleteFile(filePath)
    window.$message?.success('文件已删除')
    uiStore.addActivity('delete', `删除了文件 ${filePath}`)
  } catch (err) {
    window.$message?.error(err instanceof Error ? err.message : '删除失败')
  } finally {
    uiStore.setLoading(false)
  }
}

function handleToggle(path: string): void {
  filesStore.toggleFolder(path)
}
</script>

<template>
  <NCard title="文件管理">
    <template #header-extra>
      <NButton @click="handleRefresh">🔄 刷新</NButton>
    </template>

    <div v-if="!filesStore.directoryTree?.children?.length">
      <NEmpty description="暂无同步文件" />
    </div>

    <FileTree
      v-else
      :node="filesStore.directoryTree!"
      :expanded-folders="filesStore.expandedFolders"
      @toggle="handleToggle"
      @download="handleDownload"
      @delete="handleDelete"
    />
  </NCard>
</template>

<style scoped>
.file-tree-container {
  max-height: 600px;
  overflow-y: auto;
  border: 1px solid #e5e7eb;
  border-radius: 8px;
}
</style>

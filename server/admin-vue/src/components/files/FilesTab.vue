<script setup lang="ts">
import { computed, h, ref } from 'vue'
import {
  NCard,
  NButton,
  NEmpty,
  NTree,
  NIcon,
  NSpace,
  NPopconfirm,
  type TreeOption
} from 'naive-ui'
import {
  FolderOutline,
  FolderOpenOutline,
  DocumentOutline
} from '@vicons/ionicons5'
import { useFilesStore } from '@/stores/files'
import { useAuthStore } from '@/stores/auth'
import { useUIStore } from '@/stores/ui'
import { syncApi } from '@/api'
import type { TreeNode } from '@/stores/files'
import { formatSize, formatTime } from '@/utils/format'

const filesStore = useFilesStore()
const authStore = useAuthStore()
const uiStore = useUIStore()

// 选中的键（用于文件操作）
const checkedKeys = ref<string[]>([])

// 将 TreeNode 转换为 TreeOption（使用 prefix 显示图标）
function convertToTreeOption(node: TreeNode): TreeOption {
  const option: TreeOption = {
    key: node.path,
    label: node.name,
    // 使用 prefix 显示图标
    prefix: () => h(NIcon, { size: 18 }, {
      default: () => h(node.is_folder ? FolderOutline : DocumentOutline)
    }),
    // 自定义属性
    isFolder: node.is_folder,
    size: node.size,
    updatedAt: node.updated_at
  }

  // 文件夹始终设置 children 属性（即使为空数组），这样才能展开
  if (node.is_folder) {
    option.children = node.children?.length
      ? node.children.map(convertToTreeOption)
      : []
  }

  return option
}

// 树形数据
const treeData = computed<TreeOption[]>(() => {
  if (!filesStore.directoryTree?.children?.length) return []
  return filesStore.directoryTree.children.map(convertToTreeOption)
})

// 默认展开的键
const defaultExpandedKeys = computed<string[]>(() => {
  return Array.from(filesStore.expandedFolders)
})

// 更新展开状态时切换文件夹图标
function handleUpdateExpandedKeys(
  keys: Array<string | number>,
  _option: Array<TreeOption | null>,
  meta: {
    node: TreeOption | null
    action: 'expand' | 'collapse' | 'filter'
  }
) {
  // 更新 store 中的展开状态
  filesStore.expandedFolders = new Set(keys as string[])

  // 切换文件夹图标
  if (!meta.node) return
  const node = meta.node as TreeOption & { isFolder?: boolean }
  if (!node.isFolder) return

  switch (meta.action) {
    case 'expand':
      node.prefix = () => h(NIcon, { size: 18 }, {
        default: () => h(FolderOpenOutline)
      })
      break
    case 'collapse':
      node.prefix = () => h(NIcon, { size: 18 }, {
        default: () => h(FolderOutline)
      })
      break
  }
}

// 渲染后缀（操作按钮）
function renderSuffix({ option }: { option: TreeOption }) {
  const node = option as TreeOption & { isFolder?: boolean; size?: number; updatedAt?: string }

  if (node.isFolder) {
    return h('span', { class: 'tree-info' }, `${option.children?.length || 0} 项`)
  }

  return h(NSpace, { size: 8, align: 'center' }, {
    default: () => [
      h('span', { class: 'tree-info' }, formatSize(node.size)),
      h('span', { class: 'tree-info' }, formatTime(node.updatedAt)),
      h(NSpace, { size: 4 }, {
        default: () => [
          h(NButton, {
            size: 'tiny',
            onClick: (e: Event) => {
              e.stopPropagation()
              handleDownload(node.key as string)
            }
          }, { default: () => '下载' }),
          h(NPopconfirm, {
            onPositiveClick: () => handleDelete(node.key as string)
          }, {
            default: () => `确定要删除 ${node.key} 吗？此操作不可恢复。`,
            trigger: () => h(NButton, {
              size: 'tiny',
              type: 'error',
              onClick: (e: Event) => e.stopPropagation()
            }, { default: () => '删除' })
          })
        ]
      })
    ]
  })
}

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
</script>

<template>
  <NCard title="文件管理">
    <template #header-extra>
      <NButton size="small" @click="handleRefresh">
        刷新
      </NButton>
    </template>

    <div v-if="!filesStore.directoryTree?.children?.length">
      <NEmpty description="暂无同步文件" />
    </div>

    <NTree
      v-else
      block-line
      show-line
      :data="treeData"
      :default-expanded-keys="defaultExpandedKeys"
      expand-on-click
      checkable
      selectable
      :checked-keys="checkedKeys"
      :on-update:checked-keys="(keys: Array<string | number>) => checkedKeys = keys as string[]"
      :on-update:expanded-keys="handleUpdateExpandedKeys"
      :render-suffix="renderSuffix"
    />
  </NCard>
</template>

<style scoped>
.tree-info {
  color: #6b7280;
  font-size: 0.875rem;
  white-space: nowrap;
}
</style>

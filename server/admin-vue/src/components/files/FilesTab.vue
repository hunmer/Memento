<script setup lang="ts">
import { h, ref, onMounted } from 'vue'
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
import { formatSize, formatTime } from '@/utils/format'

const filesStore = useFilesStore()
const authStore = useAuthStore()
const uiStore = useUIStore()

// 选中的键（用于文件操作）
const checkedKeys = ref<string[]>([])

// 展开的键
const expandedKeysRef = ref<string[]>([])

// 树形数据（响应式）
const treeDataRef = ref<TreeOption[]>([])

// 已加载的目录缓存
const loadedDirectories = new Set<string>()

// 将 API 返回的文件数据转换为 TreeOption
function convertFileToTreeOption(file: {
  path: string
  size?: number | null
  updated_at?: string
  is_folder?: boolean
}): TreeOption {
  const parts = file.path.split('/').filter(p => p)
  const name = parts[parts.length - 1] || file.path
  const isFolder = file.is_folder ?? false

  const option: TreeOption = {
    key: file.path,
    label: name,
    // 使用 prefix 显示图标
    prefix: () => h(NIcon, { size: 18 }, {
      default: () => h(isFolder ? FolderOutline : DocumentOutline)
    }),
    // 自定义属性
    isFolder,
    size: file.size ?? undefined,
    updatedAt: file.updated_at
  }

  // 文件夹设置为非叶子节点，支持异步加载
  if (isFolder) {
    option.isLeaf = false
  }

  return option
}

// 加载根目录文件
async function loadRootFiles(): Promise<void> {
  try {
    const response = await syncApi.getFiles()
    const files = response.files || []

    // 只保留顶层文件/文件夹（路径中不含 / 的）
    const rootFiles = files.filter(f => {
      const parts = f.path.split('/').filter(p => p)
      return parts.length === 1
    })

    treeDataRef.value = rootFiles.map(convertFileToTreeOption)

    // 标记根目录已加载
    loadedDirectories.add('')
  } catch (err) {
    console.error('Failed to load root files:', err)
  }
}

// 异步加载子节点
async function handleLoad(node: TreeOption): Promise<void> {
  const path = node.key as string

  // 如果已经加载过，直接返回
  if (loadedDirectories.has(path)) {
    return
  }

  try {
    const response = await syncApi.getFiles(path)
    const files = response.files || []

    // 转换为 TreeOption
    node.children = files.map(convertFileToTreeOption)

    // 标记已加载
    loadedDirectories.add(path)
  } catch (err) {
    console.error('Failed to load children:', err)
    node.children = []
  }
}

// 更新展开状态时切换文件夹图标
function handleUpdateExpandedKeys(
  keys: Array<string | number>,
  _option: Array<TreeOption | null>,
  meta: {
    node: TreeOption | null
    action: 'expand' | 'collapse' | 'filter'
  }
) {
  expandedKeysRef.value = keys as string[]

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
    // 清空缓存
    loadedDirectories.clear()
    expandedKeysRef.value = []
    await loadRootFiles()
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
    await handleRefresh()
    window.$message?.success('文件已删除')
    uiStore.addActivity('delete', `删除了文件 ${filePath}`)
  } catch (err) {
    window.$message?.error(err instanceof Error ? err.message : '删除失败')
  } finally {
    uiStore.setLoading(false)
  }
}

// 初始加载
onMounted(() => {
  loadRootFiles()
})
</script>

<template>
  <NCard title="文件管理">
    <template #header-extra>
      <NButton size="small" @click="handleRefresh">
        刷新
      </NButton>
    </template>

    <div v-if="!treeDataRef.length">
      <NEmpty description="暂无同步文件" />
    </div>

    <NTree
      v-else
      block-line
      show-line
      :data="treeDataRef"
      :expanded-keys="expandedKeysRef"
      :checked-keys="checkedKeys"
      :on-load="handleLoad"
      expand-on-click
      checkable
      selectable
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

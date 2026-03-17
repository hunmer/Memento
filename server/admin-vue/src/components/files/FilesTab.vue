<script setup lang="ts">
import { h, ref, computed, onMounted } from 'vue'
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
import JSZip from 'jszip'
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

// 从节点中递归提取所有文件路径
function extractAllFilePaths(nodes: TreeOption[]): string[] {
  const filePaths: string[] = []
  for (const node of nodes) {
    const nodeWithType = node as TreeOption & { isFolder?: boolean }
    if (nodeWithType.isFolder) {
      if (node.children) {
        filePaths.push(...extractAllFilePaths(node.children))
      }
    } else {
      filePaths.push(node.key as string)
    }
  }
  return filePaths
}

// 递归加载目录下的所有文件
async function loadAllFilesRecursively(dirPath: string): Promise<string[]> {
  const filePaths: string[] = []

  async function loadDir(path: string): Promise<void> {
    try {
      const response = await syncApi.getFiles(path)
      const files = response.files || []

      for (const file of files) {
        if (file.is_folder) {
          await loadDir(file.path)
        } else {
          filePaths.push(file.path)
        }
      }
    } catch (err) {
      console.error(`Failed to load directory ${path}:`, err)
    }
  }

  await loadDir(dirPath)
  return filePaths
}

// 计算选中的文件（包含文件夹内的所有文件）
const selectedFiles = computed(() => {
  const filePaths: string[] = []

  for (const key of checkedKeys.value) {
    const findNode = (nodes: TreeOption[], targetKey: string): TreeOption | null => {
      for (const node of nodes) {
        if (node.key === targetKey) return node
        if (node.children) {
          const found = findNode(node.children, targetKey)
          if (found) return found
        }
      }
      return null
    }
    const node = findNode(treeDataRef.value, key)
    if (!node) continue

    const nodeWithType = node as TreeOption & { isFolder?: boolean }
    if (nodeWithType.isFolder) {
      // 文件夹：提取已加载的子文件
      if (node.children) {
        filePaths.push(...extractAllFilePaths(node.children))
      }
    } else {
      filePaths.push(key)
    }
  }

  return filePaths
})

const hasSelectedFiles = computed(() => selectedFiles.value.length > 0)

// 将 API 返回的文件数据转换为 TreeOption
function convertFileToTreeOption(file: {
  path: string
  size?: number | null
  updated_at?: string
  is_folder?: boolean
  is_binary?: boolean
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
    isBinary: file.is_binary ?? false,
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

// 检查文件是否为二进制（根据扩展名）
function isBinaryFile(filePath: string): boolean {
  const binaryExtensions = [
    '.png', '.jpg', '.jpeg', '.gif', '.webp', '.bmp', '.ico', '.svg',
    '.mp3', '.wav', '.ogg', '.m4a', '.flac',
    '.mp4', '.webm', '.mov', '.avi', '.mkv',
    '.pdf', '.doc', '.docx', '.xls', '.xlsx', '.ppt', '.pptx',
    '.zip', '.rar', '.7z', '.tar', '.gz'
  ]
  const ext = filePath.toLowerCase().slice(filePath.lastIndexOf('.'))
  return binaryExtensions.includes(ext)
}

async function handleDownload(filePath: string): Promise<void> {
  if (!authStore.encryptionKey) {
    window.$message?.error('请先设置加密密钥')
    return
  }

  uiStore.setLoading(true, '下载文件...')
  try {
    const fileName = filePath.split('/').pop() || 'file'

    if (isBinaryFile(filePath)) {
      // 二进制文件：直接下载 Blob
      const blob = await syncApi.downloadDecryptedBinary(filePath, authStore.encryptionKey)
      const url = URL.createObjectURL(blob)
      const a = document.createElement('a')
      a.href = url
      a.download = fileName
      a.click()
      URL.revokeObjectURL(url)
    } else {
      // 文本文件：下载 JSON
      const result = await syncApi.downloadDecrypted(filePath, authStore.encryptionKey)
      const blob = new Blob([JSON.stringify((result as { data: unknown }).data, null, 2)], {
        type: 'application/json'
      })
      const url = URL.createObjectURL(blob)
      const a = document.createElement('a')
      a.href = url
      a.download = fileName.endsWith('.json') ? fileName : `${fileName}.json`
      a.click()
      URL.revokeObjectURL(url)
    }

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

// 处理选中更新 - 选中文件夹时递归加载子文件
async function handleUpdateCheckedKeys(
  keys: Array<string | number>,
  _options: Array<TreeOption | null>,
  meta: { action: 'check' | 'uncheck'; node: TreeOption | null }
): Promise<void> {
  const newKeys = keys as string[]

  // 检测新选中的文件夹
  if (meta.action === 'check' && meta.node) {
    const node = meta.node as TreeOption & { isFolder?: boolean }
    if (node.isFolder) {
      // 递归加载该文件夹下的所有文件
      const filePaths = await loadAllFilesRecursively(node.key as string)

      // 将文件路径添加到选中列表（去重）
      const existingKeys = new Set(newKeys)
      for (const path of filePaths) {
        if (!existingKeys.has(path)) {
          newKeys.push(path)
        }
      }
    }
  }

  checkedKeys.value = newKeys
}

// 批量下载选中的文件（打包成 ZIP）
async function handleBatchDownload(): Promise<void> {
  if (!authStore.encryptionKey) {
    window.$message?.error('请先设置加密密钥')
    return
  }

  if (selectedFiles.value.length === 0) {
    window.$message?.warning('请先选择要下载的文件')
    return
  }

  const files = selectedFiles.value

  // 单个文件直接下载
  if (files.length === 1) {
    await handleDownload(files[0])
    return
  }

  uiStore.setLoading(true, `正在下载 ${files.length} 个文件并打包...`)

  const zip = new JSZip()
  let successCount = 0
  let failCount = 0

  for (const filePath of files) {
    try {
      if (isBinaryFile(filePath)) {
        // 二进制文件：直接使用 Blob
        const blob = await syncApi.downloadDecryptedBinary(filePath, authStore.encryptionKey)
        zip.file(filePath, blob)
      } else {
        // 文本文件：使用 JSON 格式
        const result = await syncApi.downloadDecrypted(filePath, authStore.encryptionKey)
        const content = JSON.stringify((result as { data: unknown }).data, null, 2)
        zip.file(filePath, content)
      }
      successCount++
    } catch {
      failCount++
    }
  }

  if (successCount === 0) {
    uiStore.setLoading(false)
    window.$message?.error('所有文件下载失败')
    return
  }

  try {
    // 生成 ZIP 文件
    const zipBlob = await zip.generateAsync({ type: 'blob' })
    const url = URL.createObjectURL(zipBlob)
    const a = document.createElement('a')
    a.href = url
    const timestamp = new Date().toISOString().replace(/[:.]/g, '-').slice(0, 19)
    a.download = `files_${timestamp}.zip`
    a.click()
    URL.revokeObjectURL(url)

    uiStore.setLoading(false)

    if (failCount === 0) {
      window.$message?.success(`成功下载 ${successCount} 个文件（已打包）`)
    } else {
      window.$message?.warning(`下载完成：${successCount} 个成功，${failCount} 个失败（已打包）`)
    }
    uiStore.addActivity('download', `批量下载了 ${successCount} 个文件`)
  } catch (err) {
    uiStore.setLoading(false)
    window.$message?.error('打包失败')
  }

  checkedKeys.value = []
}

// 批量删除选中的文件
async function handleBatchDelete(): Promise<void> {
  if (selectedFiles.value.length === 0) {
    window.$message?.warning('请先选择要删除的文件')
    return
  }

  uiStore.setLoading(true, `正在删除 ${selectedFiles.value.length} 个文件...`)

  let successCount = 0
  let failCount = 0

  for (const filePath of selectedFiles.value) {
    try {
      await filesStore.deleteFile(filePath)
      successCount++
    } catch {
      failCount++
    }
  }

  uiStore.setLoading(false)

  if (successCount > 0 && failCount === 0) {
    window.$message?.success(`成功删除 ${successCount} 个文件`)
  } else if (successCount > 0 && failCount > 0) {
    window.$message?.warning(`删除完成：${successCount} 个成功，${failCount} 个失败`)
  } else {
    window.$message?.error('所有文件删除失败')
  }

  checkedKeys.value = []
  await handleRefresh()
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

    <!-- 批量操作栏 -->
    <div class="batch-actions">
      <span class="selection-info">
        {{ hasSelectedFiles ? `已选择 ${selectedFiles.length} 个文件` : '选择文件进行批量操作' }}
      </span>
      <NSpace>
        <NButton
          size="small"
          :disabled="!hasSelectedFiles"
          @click="handleBatchDownload"
        >
          下载选中
        </NButton>
        <NPopconfirm
          :disabled="!hasSelectedFiles"
          @positive-click="handleBatchDelete"
        >
          <template #trigger>
            <NButton
              size="small"
              type="error"
              :disabled="!hasSelectedFiles"
            >
              删除选中
            </NButton>
          </template>
          确定要删除选中的 {{ selectedFiles.length }} 个文件吗？此操作不可恢复。
        </NPopconfirm>
      </NSpace>
    </div>

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
      :on-update:checked-keys="handleUpdateCheckedKeys"
      :on-update:expanded-keys="handleUpdateExpandedKeys"
      :render-suffix="renderSuffix"
    />
  </NCard>
</template>

<style scoped>
.batch-actions {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 12px 16px;
  margin-bottom: 12px;
  background: #f9fafb;
  border-radius: 6px;
}

.selection-info {
  color: #6b7280;
  font-size: 0.875rem;
}

.tree-info {
  color: #6b7280;
  font-size: 0.875rem;
  white-space: nowrap;
}
</style>

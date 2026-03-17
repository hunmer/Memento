import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { syncApi } from '@/api'

interface SyncFile {
  path: string
  size: number
  updated_at: string
  is_binary?: boolean
  md5?: string
}

export interface TreeNode {
  name: string
  path: string
  is_folder: boolean
  size?: number
  updated_at?: string
  children?: TreeNode[]
}

interface FileStats {
  totalFiles: number
  totalSize: number
  totalSizeMB: string
  lastSync: string | null
}

export const useFilesStore = defineStore('files', () => {
  // 状态
  const files = ref<SyncFile[]>([])
  const directoryTree = ref<TreeNode | null>(null)
  const expandedFolders = ref<Set<string>>(new Set())
  const loading = ref(false)
  const error = ref<string | null>(null)

  // 计算属性
  const stats = computed<FileStats>(() => ({
    totalFiles: files.value.length,
    totalSize: files.value.reduce((sum, f) => sum + (f.size || 0), 0),
    totalSizeMB: (files.value.reduce((sum, f) => sum + (f.size || 0), 0) / 1024 / 1024).toFixed(2),
    lastSync: files.value.length > 0
      ? files.value.reduce((latest, f) =>
          f.updated_at > latest ? f.updated_at : latest, '')
      : null
  }))

  const formattedTotalSize = computed(() => {
    const bytes = stats.value.totalSize
    return `${stats.value.totalSizeMB} MB (${formatSize(bytes)})`
  })

  // 加载文件列表
  async function loadFiles(): Promise<void> {
    loading.value = true
    error.value = null
    try {
      const response = await syncApi.getFiles()
      files.value = response.files || []
      buildDirectoryTree()
    } catch (err) {
      error.value = err instanceof Error ? err.message : '加载文件失败'
      console.error('Failed to load files:', err)
    } finally {
      loading.value = false
    }
  }

  // 删除文件
  async function deleteFile(filePath: string): Promise<void> {
    await syncApi.deleteFile(filePath)
    await loadFiles()
  }

  // 构建目录树
  function buildDirectoryTree(): void {
    if (!files.value.length) {
      directoryTree.value = {
        name: '根目录',
        path: '',
        is_folder: true,
        children: []
      }
      return
    }

    const folders = new Set<string>()
    const fileNodes: TreeNode[] = []

    // 收集文件夹路径
    files.value.forEach((file) => {
      const parts = file.path.split('/').filter((p) => p)
      fileNodes.push({
        name: parts[parts.length - 1] || file.path,
        path: file.path,
        is_folder: false,
        size: file.size,
        updated_at: file.updated_at
      })

      for (let i = 1; i < parts.length; i++) {
        folders.add(parts.slice(0, i).join('/'))
      }
    })

    // 构建树结构
    const allNodes: Record<string, TreeNode> = {}

    folders.forEach((folderPath) => {
      const parts = folderPath.split('/')
      allNodes[folderPath] = {
        name: parts[parts.length - 1],
        path: folderPath,
        is_folder: true,
        children: []
      }
    })

    fileNodes.forEach((file) => {
      allNodes[file.path] = file
    })

    const root: TreeNode = { name: '根目录', path: '', is_folder: true, children: [] }
    const pathMap: Record<string, TreeNode> = { '': root }

    const sortedPaths = Object.keys(allNodes).sort((a, b) => a.length - b.length)

    sortedPaths.forEach((path) => {
      const node = allNodes[path]
      const parentPath = path.substring(0, path.lastIndexOf('/'))
      const parentKey = parentPath || ''

      if (!pathMap[parentKey]) {
        pathMap[parentKey] = {
          name: parentKey.split('/').pop() || '根目录',
          path: parentKey,
          is_folder: true,
          children: []
        }
      }

      pathMap[parentKey].children!.push(node)
      pathMap[path] = node
    })

    // 排序
    sortChildren(root)
    directoryTree.value = root

    // 默认展开第一级
    root.children?.forEach((child) => {
      if (child.is_folder) {
        expandedFolders.value.add(child.path)
      }
    })
  }

  // 排序子节点
  function sortChildren(node: TreeNode): void {
    if (node.children?.length) {
      node.children.sort((a, b) => {
        if (a.is_folder && !b.is_folder) return -1
        if (!a.is_folder && b.is_folder) return 1
        return a.name.localeCompare(b.name)
      })
      node.children.forEach(sortChildren)
    }
  }

  // 切换文件夹展开状态
  function toggleFolder(path: string): void {
    if (expandedFolders.value.has(path)) {
      expandedFolders.value.delete(path)
    } else {
      expandedFolders.value.add(path)
    }
    // 触发响应式更新
    expandedFolders.value = new Set(expandedFolders.value)
  }

  // 检查是否展开
  function isExpanded(path: string): boolean {
    return expandedFolders.value.has(path)
  }

  return {
    // 状态
    files,
    directoryTree,
    expandedFolders,
    loading,
    error,

    // 计算属性
    stats,
    formattedTotalSize,

    // 方法
    loadFiles,
    deleteFile,
    toggleFolder,
    isExpanded
  }
})

// 工具函数
function formatSize(bytes: number): string {
  if (!bytes) return '0 B'
  const units = ['B', 'KB', 'MB', 'GB']
  let unitIndex = 0
  let size = bytes
  while (size >= 1024 && unitIndex < units.length - 1) {
    size /= 1024
    unitIndex++
  }
  return `${size.toFixed(1)} ${units[unitIndex]}`
}

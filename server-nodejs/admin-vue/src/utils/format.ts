// 格式化文件大小
export function formatSize(bytes?: number): string {
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

// 格式化时间
export function formatTime(isoString?: string | null): string {
  if (!isoString) return '-'
  const date = new Date(isoString)
  return date.toLocaleString('zh-CN', {
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit'
  })
}

// 获取活动图标
export function getActivityIcon(type: string): string {
  const icons: Record<string, string> = {
    sync: '🔄',
    upload: '⬆️',
    download: '⬇️',
    delete: '🗑️',
    settings: '⚙️',
    export: '📤',
    login: '🔐',
    api_key: '🔑'
  }
  return icons[type] || '📌'
}

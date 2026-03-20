<script setup lang="ts">
import { NCard, NGrid, NGi, NStatistic, NIcon, NTag } from 'naive-ui'
import {
  CheckmarkCircleOutline,
  CloseCircleOutline,
  PersonOutline,
  DocumentOutline
} from '@vicons/ionicons5'
import type { ServerStatus } from '@/stores/ui'
import type { UserInfo } from '@/api/types'

interface Props {
  totalFiles: number
  totalSize: string
  serverStatus: ServerStatus
  apiEnabled: boolean
  userInfo?: UserInfo | null
}

const props = defineProps<Props>()

const emit = defineEmits<{
  clickApi: []
}>()

// 格式化日期
function formatDate(dateStr: string): string {
  if (!dateStr) return '-'
  const date = new Date(dateStr)
  return date.toLocaleDateString('zh-CN', {
    year: 'numeric',
    month: '2-digit',
    day: '2-digit'
  })
}

// 格式化文件大小
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
</script>

<template>
  <NGrid :cols="4" :x-gap="16" :y-gap="16" responsive="screen" item-responsive>
    <!-- 用户信息卡片 -->
    <NGi span="4 m:2 l:1">
      <NCard>
        <NStatistic label="用户名">
          <template #prefix>
            <NIcon :component="PersonOutline" />
          </template>
          <template #default>
            <span style="font-size: 18px">{{ userInfo?.username || '-' }}</span>
          </template>
        </NStatistic>
        <template #footer>
          <span style="font-size: 12px; color: #999">
            注册于 {{ formatDate(userInfo?.created_at || '') }}
          </span>
        </template>
      </NCard>
    </NGi>

    <!-- 同步文件数 -->
    <NGi span="4 m:2 l:1">
      <NCard>
        <NStatistic label="同步文件数" :value="userInfo?.sync_file_count ?? totalFiles">
          <template #prefix>
            <NIcon :component="DocumentOutline" />
          </template>
        </NStatistic>
        <template #footer>
          <span style="font-size: 12px; color: #999">
            {{ userInfo?.sync_folder_count ?? 0 }} 个文件夹
          </span>
        </template>
      </NCard>
    </NGi>

    <!-- 总存储大小 -->
    <NGi span="4 m:2 l:1">
      <NCard>
        <NStatistic label="总存储大小" :value="userInfo?.sync_total_size_mb ?? totalSize">
          <template #prefix>💾</template>
          <template #suffix v-if="userInfo">MB</template>
        </NStatistic>
        <template #footer v-if="userInfo">
          <span style="font-size: 12px; color: #999">
            {{ formatSize(userInfo.sync_total_size) }}
          </span>
        </template>
      </NCard>
    </NGi>

    <!-- 服务器状态 -->
    <NGi span="4 m:2 l:1">
      <NCard hoverable style="cursor: pointer" @click="emit('clickApi')">
        <NStatistic label="服务器状态">
          <template #default>
            <NTag :type="serverStatus === 'online' ? 'success' : 'error'">
              <template #icon>
                <NIcon
                  :component="
                    serverStatus === 'online'
                      ? CheckmarkCircleOutline
                      : CloseCircleOutline
                  "
                />
              </template>
              {{ serverStatus === 'online' ? '在线' : '离线' }}
            </NTag>
          </template>
        </NStatistic>
        <template #footer>
          <span style="font-size: 12px; color: #999">
            API {{ apiEnabled ? '已启用' : '已禁用' }}
          </span>
        </template>
      </NCard>
    </NGi>
  </NGrid>
</template>

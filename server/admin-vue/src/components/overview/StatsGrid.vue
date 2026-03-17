<script setup lang="ts">
import { NCard, NGrid, NGi, NStatistic, NIcon, NTag } from 'naive-ui'
import {
  FolderOutline,
  KeyOutline,
  CheckmarkCircleOutline,
  CloseCircleOutline
} from '@vicons/ionicons5'
import type { ServerStatus } from '@/stores/ui'

interface Props {
  totalFiles: number
  totalSize: string
  serverStatus: ServerStatus
  apiEnabled: boolean
}

defineProps<Props>()

const emit = defineEmits<{
  clickApi: []
}>()
</script>

<template>
  <NGrid :cols="4" :x-gap="16" :y-gap="16" responsive="screen" item-responsive>
    <NGi span="4 m:2 l:1">
      <NCard>
        <NStatistic label="同步文件数" :value="totalFiles">
          <template #prefix>
            <NIcon :component="FolderOutline" />
          </template>
        </NStatistic>
      </NCard>
    </NGi>

    <NGi span="4 m:2 l:1">
      <NCard>
        <NStatistic label="总存储大小" :value="totalSize">
          <template #prefix>💾</template>
        </NStatistic>
      </NCard>
    </NGi>

    <NGi span="4 m:2 l:1">
      <NCard>
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
      </NCard>
    </NGi>

    <NGi span="4 m:2 l:1">
      <NCard hoverable style="cursor: pointer" @click="emit('clickApi')">
        <NStatistic label="API 访问">
          <template #default>
            <NTag :type="apiEnabled ? 'success' : 'warning'">
              <template #icon>
                <NIcon :component="KeyOutline" />
              </template>
              {{ apiEnabled ? '已启用' : '已禁用' }}
            </NTag>
          </template>
        </NStatistic>
      </NCard>
    </NGi>
  </NGrid>
</template>

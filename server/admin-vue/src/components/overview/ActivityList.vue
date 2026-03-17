<script setup lang="ts">
import { NEmpty, NList, NListItem, NThing, NText } from 'naive-ui'
import type { Activity } from '@/stores/ui'
import { formatTime, getActivityIcon } from '@/utils/format'

interface Props {
  activities: Activity[]
}

defineProps<Props>()
</script>

<template>
  <div v-if="activities.length === 0">
    <NEmpty description="暂无活动记录" />
  </div>

  <NList v-else bordered>
    <NListItem v-for="activity in activities" :key="activity.id">
      <NThing>
        <template #avatar>
          <span style="font-size: 1.25rem">{{ getActivityIcon(activity.type) }}</span>
        </template>
        <template #header>
          {{ activity.message }}
        </template>
        <template #description>
          <NText depth="3">{{ formatTime(activity.time) }}</NText>
        </template>
      </NThing>
    </NListItem>
  </NList>
</template>

<style scoped>
.n-list {
  max-height: 300px;
  overflow-y: auto;
}
</style>

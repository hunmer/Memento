<script setup lang="ts">
import { NTabs, NTabPane, NIcon, NSpace } from 'naive-ui'
import {
  HomeOutline,
  FolderOutline,
  KeyOutline,
  ExtensionPuzzleOutline,
  SettingsOutline,
  PhonePortraitOutline
} from '@vicons/ionicons5'
import { useUIStore, type TabId } from '@/stores/ui'

const uiStore = useUIStore()

const tabs: { id: TabId; label: string; icon: typeof HomeOutline }[] = [
  { id: 'overview', label: '概览', icon: HomeOutline },
  { id: 'files', label: '文件管理', icon: FolderOutline },
  { id: 'apikeys', label: 'API Keys', icon: KeyOutline },
  { id: 'plugins', label: '插件商店', icon: ExtensionPuzzleOutline },
  { id: 'devices', label: '设备管理', icon: PhonePortraitOutline },
  { id: 'settings', label: '设置', icon: SettingsOutline }
]

function handleTabChange(value: string): void {
  uiStore.setTab(value as TabId)
}
</script>

<template>
  <NTabs
    :value="uiStore.activeTab"
    @update:value="handleTabChange"
    type="line"
    animated
    style="margin-bottom: 16px"
  >
    <NTabPane
      v-for="tab in tabs"
      :key="tab.id"
      :name="tab.id"
    >
      <template #tab>
        <NSpace align="center" :size="6">
          <NIcon :component="tab.icon" />
          {{ tab.label }}
        </NSpace>
      </template>
    </NTabPane>
  </NTabs>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import {
  NTabs, NTabPane, NCard, NButton, NSpace, NIcon, NEmpty, NSpin, NModal, NInput, useDialog, useMessage }
 from 'naive-ui'
import {
  ExtensionPuzzleOutline,
  CloudDownloadOutline,
  SettingsOutline,
  TrashOutline,
  PlayCircleOutline,
  RefreshOutline,
} from '@vicons/ionicons5'
import { usePluginsStore } from '@/stores/plugins'
import type { InstalledPlugin, StorePlugin } from '@/api/types'

type PluginSubTab = 'installed' | 'store'

const pluginsStore = usePluginsStore()
const message = useMessage()
const dialog = useDialog()

const fileInput = ref<File | null>(null)
const fileInputRef = ref<HTMLInputElement | null>(null)
const activeSubTab = ref<PluginSubTab>('installed')
const showConfigModal = ref(false)
const storeConfigURL = ref('')
const syncInterval = ref(0)

const pluginTabs: { id: PluginSubTab; label: string; icon: typeof ExtensionPuzzleOutline }[] = [
  { id: 'installed', label: '已安装', icon: ExtensionPuzzleOutline },
  { id: 'store', label: '插件商店', icon: CloudDownloadOutline },
]

// 初始化数据
onMounted(async () => {
  await Promise.all([
    pluginsStore.fetchInstalledPlugins(),
    pluginsStore.fetchStoreConfig(),
  ])
})

// 切换子标签页
function handleSubTabChange(value: PluginSubTab): void {
  activeSubTab.value = value
}

// 刷新商店
async function handleRefreshStore(): Promise<void> {
  await pluginsStore.fetchStorePlugins()
}

// 打开配置弹窗
function handleOpenConfig(): void {
  storeConfigURL.value = pluginsStore.storeConfig.storeURL || ''
  syncInterval.value = pluginsStore.storeConfig.syncInterval || 0
  showConfigModal.value = true
}

// 保存配置
async function handleSaveConfig(): Promise<void> {
  if (!storeConfigURL.value) {
    message.warning('请输入商店 URL')
    return
  }
  const success = await pluginsStore.updateStoreConfig({
    storeURL: storeConfigURL.value,
    syncInterval: syncInterval.value,
  })
  if (success) {
    message.success('配置已保存')
    showConfigModal.value = false
  } else {
    message.error('保存配置失败')
  }
}

// 文件上传处理
function handleFileSelect(event: Event): void {
  const file = (event.target as HTMLInputElement).files?.[0] as File
  if (!file) {
    message.warning('请选择 ZIP 文件')
    return
  }
  fileInput.value = file
}

// 触发文件选择框
function triggerFileSelect(): void {
  fileInputRef.value?.click()
}

// 上传插件
async function handleUpload(): Promise<void> {
  if (!fileInput.value) return
  const success = await pluginsStore.uploadPlugin(fileInput.value)
  if (success) {
    message.success('插件上传成功')
    fileInput.value = null
    if (fileInputRef.value) {
      fileInputRef.value.value = ''
    }
  } else {
    message.error(pluginsStore.error || '上传失败')
  }
}

// 从商店安装
async function handleInstallFromStore(plugin: StorePlugin): Promise<void> {
  const success = await pluginsStore.installFromStore(plugin.downloadURL)
  if (success) {
    message.success(`${plugin.title} 安装成功`)
  } else {
    message.error(pluginsStore.error || '安装失败')
  }
}

// 启用插件
async function handleEnable(plugin: InstalledPlugin): Promise<void> {
  const success = await pluginsStore.enablePlugin(plugin.uuid)
  if (success) {
    message.success(`${plugin.title} 已启用`)
  }
}

// 禁用插件
async function handleDisable(plugin: InstalledPlugin): Promise<void> {
  const success = await pluginsStore.disablePlugin(plugin.uuid)
  if (success) {
    message.success(`${plugin.title} 已禁用`)
  }
}

// 卸载插件
async function handleUninstall(plugin: InstalledPlugin): Promise<void> {
  dialog.warning({
    title: '确认卸载',
    content: `确定要卸载 "${plugin.title}" 吗？此操作不可恢复。`,
    positiveText: '确认',
    onPositiveClick: async () => {
      const success = await pluginsStore.uninstallPlugin(plugin.uuid)
      if (success) {
        message.success(`${plugin.title} 已卸载`)
      }
    },
  })
}

// 获取状态标签
function getStatusLabel(plugin: InstalledPlugin): string {
  if (plugin.status === 'enabled') return '已启用'
  if (plugin.status === 'disabled') return '已禁用'
  return '已安装'
}

// 获取状态样式类
function getStatusClass(plugin: InstalledPlugin): string {
  if (plugin.status === 'enabled') return 'enabled'
  if (plugin.status === 'disabled') return 'disabled'
  return 'installed'
}
</script>

<template>
  <div class="plugins-container">
    <!-- Tab Navigation -->
    <NTabs v-model:value="activeSubTab" type="line" animated @update:value="handleSubTabChange">
      <NTabPane v-for="tab in pluginTabs" :key="tab.id" :name="tab.id">
        <template #tab>
          <NSpace align="center" :size="6">
            <NIcon :component="tab.icon" />
            {{ tab.label }}
          </NSpace>
        </template>
      </NTabPane>
    </NTabs>

    <!-- Content Area -->
    <div class="tab-content">
      <!-- Installed Plugins -->
      <div v-show="activeSubTab === 'installed'" class="plugin-section">
        <div class="section-header">
          <NSpace justify="space-between" align="center">
            <span>已安装插件 ({{ pluginsStore.installedPlugins.length }})</span>
            <NSpace>
              <input
                ref="fileInputRef"
                type="file"
                accept=".zip"
                style="display: none"
                @change="handleFileSelect"
              />
              <NButton size="small" @click="triggerFileSelect">
                选择文件
              </NButton>
              <NButton size="small" :disabled="!fileInput" @click="handleUpload" :loading="pluginsStore.loading">
                <template #icon>
                  <NIcon :component="CloudDownloadOutline" />
                </template>
                上传插件
              </NButton>
              <span v-if="fileInput" class="file-name">{{ fileInput.name }}</span>
            </NSpace>
          </NSpace>
        </div>

        <div v-if="pluginsStore.loading" class="loading-container">
          <NSpin size="medium" />
          <span>加载中...</span>
        </div>
        <div v-else-if="pluginsStore.installedPlugins.length === 0" class="empty-state">
          <NEmpty description="暂无已安装的插件">
            <template #extra>
              <NButton @click="handleOpenConfig">
                <template #icon>
                  <NIcon :component="SettingsOutline" />
                </template>
                配置商店
              </NButton>
            </template>
          </NEmpty>
        </div>
        <div v-else class="plugin-grid">
          <NCard
            v-for="plugin in pluginsStore.installedPlugins"
            :key="plugin.uuid"
            :title="plugin.title"
            hoverable
            class="plugin-card"
          >
            <template #header-extra>
              <NSpace align="center" :size="8">
                <span class="plugin-status" :class="getStatusClass(plugin)">
                  {{ getStatusLabel(plugin) }}
                </span>
              </NSpace>
            </template>
            <div class="plugin-info">
              <div class="plugin-author">作者: {{ plugin.author }}</div>
              <div class="plugin-desc">{{ plugin.description }}</div>
              <div class="plugin-meta">
                <span>版本: {{ plugin.version }}</span>
                <span v-if="plugin.website">
                  <a :href="plugin.website" target="_blank">官网</a>
                </span>
              </div>
            </div>
            <div class="plugin-actions">
              <NSpace>
                <NButton
                  v-if="plugin.status === 'enabled'"
                  type="warning"
                  size="small"
                  @click="handleDisable(plugin)"
                >
                  <template #icon>
                    <NIcon :component="PlayCircleOutline" />
                  </template>
                  禁用
                </NButton>
                <NButton
                  v-else
                  type="success"
                  size="small"
                  @click="handleEnable(plugin)"
                >
                  <template #icon>
                    <NIcon :component="PlayCircleOutline" />
                  </template>
                  启用
                </NButton>
                <NButton
                  type="error"
                  size="small"
                  @click="handleUninstall(plugin)"
                >
                  <template #icon>
                    <NIcon :component="TrashOutline" />
                  </template>
                  卸载
                </NButton>
              </NSpace>
            </div>
          </NCard>
        </div>
      </div>

      <!-- Store Plugins -->
      <div v-show="activeSubTab === 'store'" class="plugin-section">
        <div v-if="pluginsStore.loading" class="loading-container">
          <NSpin size="medium" />
          <span>加载中...</span>
        </div>
        <div v-else-if="!pluginsStore.storeConfig.storeURL" class="empty-state">
          <NEmpty description="请先配置商店 URL">
            <template #extra>
              <NButton @click="handleOpenConfig">
                <template #icon>
                  <NIcon :component="SettingsOutline" />
                </template>
                配置商店
              </NButton>
            </template>
          </NEmpty>
        </div>
        <div v-else>
          <div class="section-header">
            <NSpace justify="space-between" align="center">
              <span>商店插件 ({{ pluginsStore.storePlugins.length }})</span>
              <NButton
                size="small"
                @click="handleRefreshStore"
                :loading="pluginsStore.loading"
              >
                <template #icon>
                  <NIcon :component="RefreshOutline" />
                </template>
              </NButton>
            </NSpace>
          </div>

          <div class="plugin-grid">
            <NCard
              v-for="plugin in pluginsStore.storePlugins"
              :key="plugin.uuid"
              :title="plugin.title"
              hoverable
              class="plugin-card"
            >
              <div class="plugin-header">
                <span class="plugin-title-text">{{ plugin.title }}</span>
                <NButton
                  v-if="pluginsStore.isInstalled(plugin.uuid)"
                  type="success"
                  size="small"
                  disabled
                >
                  <template #icon>
                    <NIcon :component="CloudDownloadOutline" />
                  </template>
                  已安装
                </NButton>
                <NButton
                  v-else
                  type="primary"
                  size="small"
                  @click="handleInstallFromStore(plugin)"
                  :loading="pluginsStore.loading"
                >
                  <template #icon>
                    <NIcon :component="CloudDownloadOutline" />
                  </template>
                  安装
                </NButton>
              </div>
              <div class="plugin-info">
                <div class="plugin-author">作者: {{ plugin.author }}</div>
                <div class="plugin-desc">{{ plugin.description }}</div>
                <div class="plugin-meta">
                  <span>版本: {{ plugin.version }}</span>
                </div>
              </div>
            </NCard>
          </div>
        </div>
      </div>
    </div>

    <!-- Config Modal -->
    <NModal
      v-model:show="showConfigModal"
      preset="dialog"
      title="商店配置"
      positive-text="保存"
      @positive-click="handleSaveConfig"
    >
      <NSpace vertical :size="16">
        <NInput
          v-model:value="storeConfigURL"
          placeholder="商店 JSON URL"
        />
        <div class="config-hint">
          输入插件商店的 JSON 文件 URL，服务器将定期从此 URL 获取可用插件列表
        </div>
      </NSpace>
    </NModal>
  </div>
</template>

<style scoped>
.plugins-container {
  padding: 0;
}

.tab-content {
  margin-top: 16px;
  min-height: 300px;
}

.section-header {
  margin-bottom: 16px;
}

.plugin-section {
  padding: 16px;
  background: #fff;
  border-radius: 8px;
}

.plugin-grid {
  display: grid;
  gap: 16px;
  grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
}

.loading-container {
  display: flex;
  justify-content: center;
  align-items: center;
  gap: 8px;
  padding: 40px;
  color: #666;
}

.empty-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 16px;
  padding: 40px;
  color: #999;
}

.plugin-card {
  cursor: pointer;
  transition: all 0.3s ease;
}

 .plugin-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
}

.plugin-status {
  font-size: 12px;
  padding: 2px 8px;
  border-radius: 4px;
}

 .plugin-status.enabled {
  background-color: #e8f5e9;
  color: #1a7f37;
}

.plugin-status.disabled {
  background-color: #fff3e0;
  color: #f59e0b;
}

.plugin-status.installed {
  background-color: #e3f2fd;
  color: #1890ff;
}

.plugin-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.plugin-title-text {
  font-weight: 500;
}

.plugin-info {
  margin: 12px 0;
  font-size: 13px;
  color: #666;
}

.plugin-author {
  margin-bottom: 4px;
}

.plugin-desc {
  margin-bottom: 8px;
  line-height: 1.4;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
    text-align: center;
}

.plugin-meta {
  display: flex;
  gap: 12px;
  font-size: 12px;
  color: #999;
  justify-content: center;
}

.plugin-actions {
  margin-top: 12px;
  padding-top: 12px;
  border-top: 1px solid #eee;
}

.config-hint {
  font-size: 12px;
  color: #999;
  margin-top: 4px;
}

.file-name {
  font-size: 12px;
  color: #666;
  max-width: 200px;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
</style>

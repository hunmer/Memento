<script setup lang="ts">
import { computed } from 'vue'
import { NButton, NSpace, NIcon, NPopconfirm } from 'naive-ui'
import {
  FolderOutline,
  FolderOpenOutline,
  DocumentOutline
} from '@vicons/ionicons5'
import type { TreeNode } from '@/stores/files'
import { formatSize, formatTime } from '@/utils/format'

interface Props {
  node: TreeNode
  level: number
  expandedFolders: Set<string>
}

const props = defineProps<Props>()

const emit = defineEmits<{
  toggle: [path: string]
  download: [path: string]
  delete: [path: string]
}>()

const isExpanded = computed(() => props.expandedFolders.has(props.node.path))

function handleToggle(): void {
  if (props.node.is_folder) {
    emit('toggle', props.node.path)
  }
}

function handleDownload(): void {
  if (!props.node.is_folder) {
    emit('download', props.node.path)
  }
}

function handleDelete(): void {
  if (!props.node.is_folder) {
    emit('delete', props.node.path)
  }
}
</script>

<template>
  <div class="tree-item" :style="{ paddingLeft: `${level * 20}px` }">
    <!-- 文件夹节点 -->
    <div v-if="node.is_folder" class="folder-node" @click="handleToggle">
      <NIcon class="tree-icon" :size="20">
        <component :is="isExpanded ? FolderOpenOutline : FolderOutline" />
      </NIcon>
      <span class="tree-name">{{ node.name }}</span>
      <span class="tree-info">{{ node.children?.length || 0 }} 项</span>
    </div>

    <!-- 文件节点 -->
    <div v-else class="file-node">
      <NIcon class="tree-icon" :size="20">
        <DocumentOutline />
      </NIcon>
      <span class="tree-name">{{ node.name }}</span>
      <span class="tree-info">{{ formatSize(node.size) }}</span>
      <span class="tree-info">{{ formatTime(node.updated_at) }}</span>
      <NSpace class="tree-actions" :size="4">
        <NButton size="tiny" @click="handleDownload">下载</NButton>
        <NPopconfirm @positive-click="handleDelete">
          <template #trigger>
            <NButton size="tiny" type="error">删除</NButton>
          </template>
          确定要删除 {{ node.path }} 吗？此操作不可恢复。
        </NPopconfirm>
      </NSpace>
    </div>

    <!-- 子节点 -->
    <div
      v-if="node.is_folder && isExpanded && node.children?.length"
      class="tree-children"
    >
      <TreeNodeComponent
        v-for="child in node.children"
        :key="child.path"
        :node="child"
        :level="level + 1"
        :expanded-folders="expandedFolders"
        @toggle="(path: string) => emit('toggle', path)"
        @download="(path: string) => emit('download', path)"
        @delete="(path: string) => emit('delete', path)"
      />
    </div>
  </div>
</template>

<style scoped>
.tree-item {
  border-bottom: 1px solid #e5e7eb;
}

.tree-item:last-child {
  border-bottom: none;
}

.folder-node,
.file-node {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 8px 12px;
  cursor: pointer;
  transition: background-color 0.2s;
}

.folder-node:hover,
.file-node:hover {
  background-color: #f5f5f5;
}

.tree-icon {
  flex-shrink: 0;
}

.tree-name {
  flex: 1;
  font-family: monospace;
  word-break: break-all;
}

.tree-info {
  color: #6b7280;
  font-size: 0.875rem;
  white-space: nowrap;
}

.tree-actions {
  flex-shrink: 0;
}

.tree-children {
  border-left: 2px solid #e5e7eb;
  margin-left: 12px;
}
</style>

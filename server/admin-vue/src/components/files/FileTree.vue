<script setup lang="ts">
import { NEmpty } from 'naive-ui'
import type { TreeNode } from '@/stores/files'
import TreeNodeComponent from './TreeNode.vue'

interface Props {
  node: TreeNode
  expandedFolders: Set<string>
}

defineProps<Props>()

const emit = defineEmits<{
  toggle: [path: string]
  download: [path: string]
  delete: [path: string]
}>()
</script>

<template>
  <div class="file-tree-container">
    <NEmpty v-if="!node.children?.length" description="暂无同步文件" />

    <div v-else class="directory-tree">
      <TreeNodeComponent
        v-for="child in node.children"
        :key="child.path"
        :node="child"
        :level="0"
        :expanded-folders="expandedFolders"
        @toggle="(path: string) => emit('toggle', path)"
        @download="(path: string) => emit('download', path)"
        @delete="(path: string) => emit('delete', path)"
      />
    </div>
  </div>
</template>

<style scoped>
.file-tree-container {
  max-height: 600px;
  overflow-y: auto;
  border: 1px solid #e5e7eb;
  border-radius: 8px;
}

.directory-tree {
  padding: 8px;
}
</style>

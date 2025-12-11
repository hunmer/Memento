const { createApp, ref, reactive, computed, onMounted, watch, h } = Vue;

// TreeNode 组件定义
const TreeNode = Vue.defineComponent({
    props: {
        node: Object,
        level: Number,
        expandedFolders: Object
    },
    emits: ['toggle', 'download', 'delete'],
    setup(props, { emit }) {
        const isExpanded = computed(() => {
            return props.expandedFolders.has(props.node.path);
        });

        const toggle = () => {
            if (props.node.is_folder) {
                emit('toggle', props.node.path);
            }
        };

        const download = () => {
            if (!props.node.is_folder) {
                emit('download', props.node.path);
            }
        };

        const deleteNode = () => {
            if (!props.node.is_folder) {
                emit('delete', props.node.path);
            }
        };

        const formatSize = (bytes) => {
            if (!bytes) return '-';
            const units = ['B', 'KB', 'MB', 'GB'];
            let unitIndex = 0;
            let size = bytes;
            while (size >= 1024 && unitIndex < units.length - 1) {
                size /= 1024;
                unitIndex++;
            }
            return `${size.toFixed(1)} ${units[unitIndex]}`;
        };

        const formatTime = (isoString) => {
            if (!isoString) return '-';
            const date = new Date(isoString);
            return date.toLocaleString('zh-CN');
        };

        return () => {
            const paddingStyle = { paddingLeft: (props.level * 20) + 'px' };

            if (props.node.is_folder) {
                const children = [];

                // 文件夹头部
                children.push(
                    h('div', { class: 'folder-node', onClick: toggle }, [
                        h('span', { class: 'tree-icon' }, isExpanded.value ? '📂' : '📁'),
                        h('span', { class: 'tree-name' }, props.node.name),
                        h('span', { class: 'tree-info' }, `${props.node.children ? props.node.children.length : 0} 项`)
                    ])
                );

                // 子节点
                if (props.node.is_folder && isExpanded.value && props.node.children) {
                    children.push(
                        h('div', { class: 'tree-children' },
                            props.node.children.map(child =>
                                h(TreeNode, {
                                    key: child.path,
                                    node: child,
                                    level: props.level + 1,
                                    expandedFolders: props.expandedFolders,
                                    onToggle: (path) => emit('toggle', path),
                                    onDownload: (path) => emit('download', path),
                                    onDelete: (path) => emit('delete', path)
                                })
                            )
                        )
                    );
                }

                return h('div', { class: 'tree-item', style: paddingStyle }, children);
            } else {
                return h('div', { class: 'tree-item', style: paddingStyle }, [
                    h('div', { class: 'file-node' }, [
                        h('span', { class: 'tree-icon' }, '📄'),
                        h('span', { class: 'tree-name' }, props.node.name),
                        h('span', { class: 'tree-info' }, formatSize(props.node.size)),
                        h('span', { class: 'tree-info' }, formatTime(props.node.updated_at)),
                        h('div', { class: 'tree-actions' }, [
                            h('button', { class: 'btn btn-sm', onClick: download }, '下载'),
                            h('button', { class: 'btn btn-sm btn-danger', onClick: deleteNode }, '删除')
                        ])
                    ])
                ]);
            }
        };
    }
});

// 主应用
createApp({
    components: {
        TreeNode,
        'tree-node': TreeNode
    },
    setup() {
        // State
        const isLoggedIn = ref(false);
        const loading = ref(false);
        const loadingMessage = ref('');
        const error = ref('');
        const activeTab = ref('overview');
        const currentUser = ref('');
        const token = ref('');
        const serverUrl = ref(localStorage.getItem('serverUrl') || 'http://localhost:8080');
        const serverStatus = ref('offline');

        const loginForm = reactive({
            username: '',
            password: ''
        });

        const stats = reactive({
            totalFiles: 0,
            totalSize: 0,
            lastSync: null
        });

        const files = ref([]);
        const directoryTree = ref(null);
        const currentPath = ref('');
        const expandedFolders = ref(new Set());
        const recentActivities = ref([]);
        const toasts = ref([]);

        // Methods
        const showToast = (message, type = 'success') => {
            const id = Date.now();
            toasts.value.push({ id, message, type });
            setTimeout(() => {
                toasts.value = toasts.value.filter(t => t.id !== id);
            }, 3000);
        };

        const setLoading = (isLoading, message = '') => {
            loading.value = isLoading;
            loadingMessage.value = message;
        };

        const apiRequest = async (endpoint, options = {}) => {
            const url = `${serverUrl.value}${endpoint}`;
            const headers = {
                'Content-Type': 'application/json',
                ...options.headers
            };

            if (token.value) {
                headers['Authorization'] = `Bearer ${token.value}`;
            }

            try {
                const response = await fetch(url, {
                    ...options,
                    headers
                });

                // 处理认证错误 (401/403)
                if (response.status === 401 || response.status === 403) {
                    console.warn('Token expired, clearing credentials');
                    // 清除过期的认证信息
                    token.value = '';
                    currentUser.value = '';
                    localStorage.removeItem('token');
                    localStorage.removeItem('username');
                    isLoggedIn.value = false;

                    showToast('登录已过期，请重新登录', 'error');
                    throw new Error('登录已过期，请重新登录');
                }

                if (!response.ok) {
                    const errorData = await response.json().catch(() => ({}));
                    throw new Error(errorData.error || `HTTP Error: ${response.status}`);
                }

                return response.json();
            } catch (err) {
                // 如果是网络错误或服务器未启动，也清除token避免死循环
                if (err.message.includes('Failed to fetch') || err.message.includes('NetworkError')) {
                    console.warn('Network error, clearing token to prevent retry loop');
                    token.value = '';
                    currentUser.value = '';
                    localStorage.removeItem('token');
                    localStorage.removeItem('username');
                    isLoggedIn.value = false;
                }
                throw err;
            }
        };

        const login = async () => {
            if (!loginForm.username || !loginForm.password) {
                error.value = '请输入用户名和密码';
                return;
            }

            setLoading(true, '登录中...');
            error.value = '';

            try {
                // Save server URL
                localStorage.setItem('serverUrl', serverUrl.value);

                const data = await apiRequest('/api/v1/auth/login', {
                    method: 'POST',
                    body: JSON.stringify({
                        username: loginForm.username,
                        password: loginForm.password,
                        device_id: 'admin_panel',
                        device_name: 'Admin Panel'
                    })
                });

                token.value = data.token;
                currentUser.value = loginForm.username;
                isLoggedIn.value = true;

                // Save to localStorage
                localStorage.setItem('token', token.value);
                localStorage.setItem('username', currentUser.value);

                showToast('登录成功');
                await loadDashboardData();
            } catch (err) {
                error.value = err.message || '登录失败，请检查用户名和密码';
            } finally {
                setLoading(false);
            }
        };

        const logout = () => {
            isLoggedIn.value = false;
            token.value = '';
            currentUser.value = '';
            localStorage.removeItem('token');
            localStorage.removeItem('username');
            showToast('已退出登录');
        };

        const checkServerHealth = async () => {
            try {
                await fetch(`${serverUrl.value}/health`);
                serverStatus.value = 'online';
            } catch {
                serverStatus.value = 'offline';
            }
        };

        const loadDashboardData = async () => {
            // 检查是否仍有有效token
            if (!token.value) {
                console.log('No valid token, skipping dashboard data load');
                return;
            }

            try {
                await Promise.all([
                    checkServerHealth(),
                    loadFiles(),  // loadFiles will call buildDirectoryTree internally
                    loadStats()
                ]);
            } catch (err) {
                // 如果加载失败，可能是token问题，apiRequest已经处理了清理
                console.error('Failed to load dashboard data:', err);
            }
        };

        const loadFiles = async () => {
            try {
                const data = await apiRequest('/api/v1/sync/list');
                files.value = data.files || [];

                // Update stats
                stats.totalFiles = files.value.length;
                stats.totalSize = files.value.reduce((sum, f) => sum + (f.size || 0), 0);

                // Build directory tree from files list (纯前端处理)
                buildDirectoryTree();
            } catch (err) {
                console.error('Failed to load files:', err);
            }
        };

        // 前端构建树状结构 (纯前端处理，无需API)
        const buildDirectoryTree = () => {
            if (!files.value || files.value.length === 0) {
                directoryTree.value = {
                    name: '根目录',
                    path: '',
                    is_folder: true,
                    children: []
                };
                return;
            }

            // 步骤1: 收集所有唯一的文件夹路径
            const folders = new Set();
            const fileNodes = [];

            files.value.forEach(file => {
                const parts = file.path.split('/').filter(p => p); // 过滤空字符串
                fileNodes.push({
                    name: parts[parts.length - 1] || file.path,
                    path: file.path,
                    is_folder: false,
                    size: file.size,
                    updated_at: file.updated_at
                });

                // 构建所有父文件夹路径
                for (let i = 1; i < parts.length; i++) {
                    const folderPath = parts.slice(0, i).join('/');
                    folders.add(folderPath);
                }
            });

            // 步骤2: 创建所有节点（文件夹和文件）
            const allNodes = {};

            // 添加文件夹节点
            folders.forEach(folderPath => {
                const parts = folderPath.split('/');
                const name = parts[parts.length - 1];
                allNodes[folderPath] = {
                    name: name,
                    path: folderPath,
                    is_folder: true,
                    children: []
                };
            });

            // 添加文件节点
            fileNodes.forEach(file => {
                allNodes[file.path] = file;
            });

            // 步骤3: 构建父子关系
            const root = { name: '根目录', path: '', is_folder: true, children: [] };
            const pathMap = { '': root };

            // 按路径长度排序，确保父节点在子节点之前处理
            const sortedPaths = Object.keys(allNodes).sort((a, b) => a.length - b.length);

            sortedPaths.forEach(path => {
                const node = allNodes[path];
                const parentPath = path.substring(0, path.lastIndexOf('/'));

                // 如果父路径为空，说明是根级节点
                const parentKey = parentPath || '';

                // 确保父节点存在
                if (!pathMap[parentKey]) {
                    pathMap[parentKey] = {
                        name: parentKey.split('/').pop() || '根目录',
                        path: parentKey,
                        is_folder: true,
                        children: []
                    };
                }

                pathMap[parentKey].children.push(node);
                pathMap[path] = node;
            });

            // 步骤4: 排序子节点（文件夹优先，按名称排序）
            const sortChildren = (node) => {
                if (node.children && node.children.length > 0) {
                    node.children.sort((a, b) => {
                        if (a.is_folder && !b.is_folder) return -1;
                        if (!a.is_folder && b.is_folder) return 1;
                        return a.name.localeCompare(b.name);
                    });
                    node.children.forEach(sortChildren);
                }
            };

            sortChildren(root);
            directoryTree.value = root;

            // 默认展开根目录下的第一级文件夹
            if (root.children) {
                root.children.forEach(child => {
                    if (child.is_folder) {
                        expandedFolders.value.add(child.path);
                    }
                });
                // 触发响应式更新
                expandedFolders.value = new Set(expandedFolders.value);
            }
        };

        const loadStats = async () => {
            try {
                const data = await apiRequest('/api/v1/sync/status');
                if (data.lastSync) {
                    stats.lastSync = formatTime(data.lastSync);
                }
            } catch (err) {
                console.error('Failed to load stats:', err);
            }
        };

        const refreshFiles = async () => {
            setLoading(true, '刷新文件列表...');
            try {
                await loadFiles();  // buildDirectoryTree is called inside loadFiles
                showToast('文件列表已刷新');
            } catch (err) {
                showToast(err.message, 'error');
            } finally {
                setLoading(false);
            }
        };

        const toggleFolder = (folderPath) => {
            if (expandedFolders.value.has(folderPath)) {
                expandedFolders.value.delete(folderPath);
            } else {
                expandedFolders.value.add(folderPath);
            }
            // 触发响应式更新
            expandedFolders.value = new Set(expandedFolders.value);
        };

        const isFolderExpanded = (folderPath) => {
            return expandedFolders.value.has(folderPath);
        };

        const downloadFile = async (filePath) => {
            setLoading(true, '下载文件...');
            try {
                const data = await apiRequest(`/api/v1/sync/pull/${filePath}`);

                // Create download
                const blob = new Blob([JSON.stringify(data, null, 2)], { type: 'application/json' });
                const url = URL.createObjectURL(blob);
                const a = document.createElement('a');
                a.href = url;
                a.download = filePath.split('/').pop();
                a.click();
                URL.revokeObjectURL(url);

                showToast('下载成功');
            } catch (err) {
                showToast(err.message, 'error');
            } finally {
                setLoading(false);
            }
        };

        const deleteFile = async (filePath) => {
            if (!confirm(`确定要删除 ${filePath} 吗？此操作不可恢复。`)) {
                return;
            }

            setLoading(true, '删除文件...');
            try {
                await apiRequest(`/api/v1/sync/delete/${filePath}`, {
                    method: 'DELETE'
                });
                await loadFiles();
                showToast('文件已删除');
            } catch (err) {
                showToast(err.message, 'error');
            } finally {
                setLoading(false);
            }
        };

        const exportData = async () => {
            setLoading(true, '导出ZIP文件...');
            try {
                const data = await apiRequest('/api/v1/sync/export', {
                    method: 'POST'
                });

                if (data.success) {
                    // 下载ZIP文件
                    const downloadUrl = `${serverUrl.value}/api/v1/sync/download/${data.file_name}`;
                    const response = await fetch(downloadUrl, {
                        headers: {
                            'Authorization': `Bearer ${token.value}`
                        }
                    });

                    if (!response.ok) {
                        throw new Error('下载失败');
                    }

                    const blob = await response.blob();
                    const url = URL.createObjectURL(blob);
                    const a = document.createElement('a');
                    a.href = url;
                    a.download = data.file_name;
                    a.click();
                    URL.revokeObjectURL(url);

                    showToast(`数据导出成功 (${data.metadata.file_count} 个文件, ${data.metadata.total_size_mb} MB)`);
                    addActivity('export', `导出了 ${data.metadata.file_count} 个文件`);
                } else {
                    throw new Error(data.error || '导出失败');
                }
            } catch (err) {
                showToast(err.message, 'error');
            } finally {
                setLoading(false);
            }
        };

        const clearServerData = async () => {
            if (!confirm('警告：此操作将删除服务器上的所有同步数据！\n\n确定要继续吗？')) {
                return;
            }

            if (!confirm('再次确认：这将永久删除所有数据，无法恢复！')) {
                return;
            }

            setLoading(true, '清空服务器数据...');
            try {
                // Delete all files
                for (const file of files.value) {
                    await apiRequest(`/api/v1/sync/delete/${file.path}`, {
                        method: 'DELETE'
                    });
                }
                await loadFiles();
                showToast('服务器数据已清空');
                addActivity('delete', '清空了服务器数据');
            } catch (err) {
                showToast(err.message, 'error');
            } finally {
                setLoading(false);
            }
        };

        const addActivity = (type, message) => {
            recentActivities.value.unshift({
                id: Date.now(),
                type,
                message,
                time: new Date().toISOString()
            });
            // Keep only last 10 activities
            if (recentActivities.value.length > 10) {
                recentActivities.value.pop();
            }
        };

        // Utilities
        const formatSize = (bytes) => {
            if (!bytes) return '0 B';
            const units = ['B', 'KB', 'MB', 'GB'];
            let unitIndex = 0;
            let size = bytes;
            while (size >= 1024 && unitIndex < units.length - 1) {
                size /= 1024;
                unitIndex++;
            }
            return `${size.toFixed(1)} ${units[unitIndex]}`;
        };

        const formatTime = (isoString) => {
            if (!isoString) return '-';
            const date = new Date(isoString);
            return date.toLocaleString('zh-CN');
        };

        const getActivityIcon = (type) => {
            const icons = {
                sync: '🔄',
                upload: '⬆️',
                download: '⬇️',
                delete: '🗑️',
                settings: '⚙️',
                export: '📤',
                login: '🔐'
            };
            return icons[type] || '📌';
        };

        // Lifecycle
        onMounted(async () => {
            // Check for saved login
            const savedToken = localStorage.getItem('token');
            const savedUsername = localStorage.getItem('username');

            if (savedToken && savedUsername) {
                token.value = savedToken;
                currentUser.value = savedUsername;
                isLoggedIn.value = true;

                try {
                    // 尝试加载数据，如果token无效会自动清理
                    await loadDashboardData();
                } catch (err) {
                    console.log('Initial load failed, user may need to re-login');
                }
            }

            // Check server status periodically
            setInterval(checkServerHealth, 30000);
        });

        return {
            // State
            isLoggedIn,
            loading,
            loadingMessage,
            error,
            activeTab,
            currentUser,
            serverUrl,
            serverStatus,
            loginForm,
            stats,
            files,
            directoryTree,
            currentPath,
            expandedFolders,
            recentActivities,
            toasts,

            // Methods
            login,
            logout,
            refreshFiles,
            toggleFolder,
            isFolderExpanded,
            downloadFile,
            deleteFile,
            exportData,
            clearServerData,

            // Utilities
            formatSize,
            formatTime,
            getActivityIcon
        };
    }
}).mount('#app');

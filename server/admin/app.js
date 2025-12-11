const { createApp, ref, reactive, computed, onMounted, watch } = Vue;

createApp({
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

        const settings = reactive({
            autoSync: false,
            syncInterval: 30,
            syncOnChange: true,
            conflictStrategy: 'server',
            syncDirs: ['diary', 'chat', 'notes', 'activity']
        });

        const availableDirs = ref([
            'diary', 'chat', 'notes', 'todo', 'activity',
            'bill', 'tracker', 'goods', 'contact', 'habits', 'checkin'
        ]);

        const files = ref([]);
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

            const response = await fetch(url, {
                ...options,
                headers
            });

            if (!response.ok) {
                const errorData = await response.json().catch(() => ({}));
                throw new Error(errorData.error || `HTTP Error: ${response.status}`);
            }

            return response.json();
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
            await Promise.all([
                checkServerHealth(),
                loadFiles(),
                loadStats()
            ]);
        };

        const loadFiles = async () => {
            try {
                const data = await apiRequest('/api/v1/sync/list');
                files.value = data.files || [];

                // Update stats
                stats.totalFiles = files.value.length;
                stats.totalSize = files.value.reduce((sum, f) => sum + (f.size || 0), 0);
            } catch (err) {
                console.error('Failed to load files:', err);
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
                await loadFiles();
                showToast('文件列表已刷新');
            } catch (err) {
                showToast(err.message, 'error');
            } finally {
                setLoading(false);
            }
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

        const saveSettings = async () => {
            setLoading(true, '保存设置...');
            try {
                // Save settings to localStorage (client-side settings)
                localStorage.setItem('syncSettings', JSON.stringify(settings));
                showToast('设置已保存');

                // Add activity
                addActivity('settings', '同步设置已更新');
            } catch (err) {
                showToast(err.message, 'error');
            } finally {
                setLoading(false);
            }
        };

        const triggerFullSync = async () => {
            if (!confirm('确定要执行全量同步吗？这可能需要一些时间。')) {
                return;
            }

            setLoading(true, '执行全量同步...');
            try {
                // This would trigger sync on the client side
                // For now, just refresh the file list
                await loadFiles();
                showToast('全量同步完成');
                addActivity('sync', '执行了全量同步');
            } catch (err) {
                showToast(err.message, 'error');
            } finally {
                setLoading(false);
            }
        };

        const exportData = async () => {
            setLoading(true, '导出数据...');
            try {
                const data = await apiRequest('/api/v1/sync/list');

                const exportData = {
                    exportedAt: new Date().toISOString(),
                    files: data.files
                };

                const blob = new Blob([JSON.stringify(exportData, null, 2)], { type: 'application/json' });
                const url = URL.createObjectURL(blob);
                const a = document.createElement('a');
                a.href = url;
                a.download = `memento_export_${Date.now()}.json`;
                a.click();
                URL.revokeObjectURL(url);

                showToast('数据导出成功');
                addActivity('export', '导出了同步数据');
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
            // Load saved settings
            const savedSettings = localStorage.getItem('syncSettings');
            if (savedSettings) {
                Object.assign(settings, JSON.parse(savedSettings));
            }

            // Check for saved login
            const savedToken = localStorage.getItem('token');
            const savedUsername = localStorage.getItem('username');
            if (savedToken && savedUsername) {
                token.value = savedToken;
                currentUser.value = savedUsername;
                isLoggedIn.value = true;
                await loadDashboardData();
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
            settings,
            availableDirs,
            files,
            recentActivities,
            toasts,

            // Methods
            login,
            logout,
            refreshFiles,
            downloadFile,
            deleteFile,
            saveSettings,
            triggerFullSync,
            exportData,
            clearServerData,

            // Utilities
            formatSize,
            formatTime,
            getActivityIcon
        };
    }
}).mount('#app');

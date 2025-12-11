/**
 * Memento HTTP 客户端
 */
export class MementoClient {
    config;
    constructor(config) {
        this.config = config;
    }
    /**
     * 发送 GET 请求
     */
    async get(path, params) {
        let url = `${this.config.serverUrl}${path}`;
        if (params && Object.keys(params).length > 0) {
            const searchParams = new URLSearchParams(params);
            url += `?${searchParams.toString()}`;
        }
        const response = await fetch(url, {
            method: 'GET',
            headers: this.getHeaders(),
        });
        return this.handleResponse(response);
    }
    /**
     * 发送 POST 请求
     */
    async post(path, body) {
        const response = await fetch(`${this.config.serverUrl}${path}`, {
            method: 'POST',
            headers: this.getHeaders(),
            body: body ? JSON.stringify(body) : undefined,
        });
        return this.handleResponse(response);
    }
    /**
     * 发送 PUT 请求
     */
    async put(path, body) {
        const response = await fetch(`${this.config.serverUrl}${path}`, {
            method: 'PUT',
            headers: this.getHeaders(),
            body: body ? JSON.stringify(body) : undefined,
        });
        return this.handleResponse(response);
    }
    /**
     * 发送 DELETE 请求
     */
    async delete(path, params) {
        let url = `${this.config.serverUrl}${path}`;
        if (params && Object.keys(params).length > 0) {
            const searchParams = new URLSearchParams(params);
            url += `?${searchParams.toString()}`;
        }
        const response = await fetch(url, {
            method: 'DELETE',
            headers: this.getHeaders(),
        });
        return this.handleResponse(response);
    }
    /**
     * 获取请求头
     */
    getHeaders() {
        return {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${this.config.authToken}`,
        };
    }
    /**
     * 处理响应
     */
    async handleResponse(response) {
        const data = await response.json();
        if (!data.success) {
            throw new Error(data.error || `请求失败: ${response.status}`);
        }
        return data;
    }
    // ==================== Chat API ====================
    /**
     * 获取频道列表
     */
    async getChannels(params) {
        return this.get('/api/v1/plugins/chat/channels', params);
    }
    /**
     * 创建频道
     */
    async createChannel(data) {
        return this.post('/api/v1/plugins/chat/channels', data);
    }
    /**
     * 获取消息列表
     */
    async getMessages(channelId, params) {
        return this.get(`/api/v1/plugins/chat/channels/${channelId}/messages`, params);
    }
    /**
     * 发送消息
     */
    async sendMessage(channelId, data) {
        return this.post(`/api/v1/plugins/chat/channels/${channelId}/messages`, data);
    }
    // ==================== Notes API ====================
    /**
     * 获取笔记列表
     */
    async getNotes(params) {
        return this.get('/api/v1/plugins/notes/notes', params);
    }
    /**
     * 创建笔记
     */
    async createNote(data) {
        return this.post('/api/v1/plugins/notes/notes', data);
    }
    /**
     * 更新笔记
     */
    async updateNote(id, data) {
        return this.put(`/api/v1/plugins/notes/notes/${id}`, data);
    }
    /**
     * 搜索笔记
     */
    async searchNotes(keyword, params) {
        const queryParams = { keyword };
        if (params?.offset !== undefined)
            queryParams.offset = String(params.offset);
        if (params?.count !== undefined)
            queryParams.count = String(params.count);
        return this.get('/api/v1/plugins/notes/search', queryParams);
    }
    // ==================== Activity API ====================
    /**
     * 获取活动列表
     */
    async getActivities(params) {
        return this.get('/api/v1/plugins/activity/activities', params);
    }
    /**
     * 创建活动
     */
    async createActivity(data) {
        return this.post('/api/v1/plugins/activity/activities', data);
    }
    /**
     * 获取今日统计
     */
    async getTodayStats() {
        return this.get('/api/v1/plugins/activity/stats/today');
    }
    // ==================== Goods API ====================
    /**
     * 获取仓库列表
     */
    async getWarehouses(params) {
        return this.get('/api/v1/plugins/goods/warehouses', params);
    }
    /**
     * 获取物品列表
     */
    async getItems(params) {
        return this.get('/api/v1/plugins/goods/items', params);
    }
    /**
     * 创建物品
     */
    async createItem(data) {
        return this.post('/api/v1/plugins/goods/items', data);
    }
    /**
     * 搜索物品
     */
    async searchItems(keyword, params) {
        return this.get('/api/v1/plugins/goods/search', { keyword, ...params });
    }
    // ==================== Bill API ====================
    /**
     * 获取账户列表
     */
    async getAccounts(params) {
        return this.get('/api/v1/plugins/bill/accounts', params);
    }
    /**
     * 获取账单列表
     */
    async getBills(accountId, params) {
        return this.get(`/api/v1/plugins/bill/accounts/${accountId}/bills`, params);
    }
    /**
     * 创建账单
     */
    async createBill(accountId, data) {
        return this.post(`/api/v1/plugins/bill/accounts/${accountId}/bills`, data);
    }
    /**
     * 获取账单统计
     */
    async getBillStats(params) {
        return this.get('/api/v1/plugins/bill/stats', params);
    }
    // ==================== Todo API ====================
    /**
     * 获取任务列表
     */
    async getTasks(params) {
        return this.get('/api/v1/plugins/todo/tasks', params);
    }
    /**
     * 创建任务
     */
    async createTask(data) {
        return this.post('/api/v1/plugins/todo/tasks', data);
    }
    /**
     * 更新任务
     */
    async updateTask(id, data) {
        return this.put(`/api/v1/plugins/todo/tasks/${id}`, data);
    }
    /**
     * 完成任务
     */
    async completeTask(id) {
        return this.post(`/api/v1/plugins/todo/tasks/${id}/complete`);
    }
    /**
     * 获取今日任务
     */
    async getTodayTasks() {
        return this.get('/api/v1/plugins/todo/tasks/filter/today');
    }
    /**
     * 获取过期任务
     */
    async getOverdueTasks() {
        return this.get('/api/v1/plugins/todo/tasks/filter/overdue');
    }
    /**
     * 搜索任务
     */
    async searchTasks(keyword) {
        return this.get('/api/v1/plugins/todo/search', { keyword });
    }
    /**
     * 获取任务统计
     */
    async getTodoStats() {
        return this.get('/api/v1/plugins/todo/stats');
    }
}
//# sourceMappingURL=memento-client.js.map
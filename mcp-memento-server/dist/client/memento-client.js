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
    // ==================== Diary API ====================
    /**
     * 获取日记列表
     */
    async getDiaryEntries(params) {
        return this.get('/api/v1/plugins/diary/entries', params);
    }
    /**
     * 获取指定日期的日记
     */
    async getDiaryEntry(date) {
        return this.get(`/api/v1/plugins/diary/entries/${date}`);
    }
    /**
     * 创建日记
     */
    async createDiaryEntry(data) {
        return this.post('/api/v1/plugins/diary/entries', data);
    }
    /**
     * 更新日记
     */
    async updateDiaryEntry(date, data) {
        return this.put(`/api/v1/plugins/diary/entries/${date}`, data);
    }
    /**
     * 删除日记
     */
    async deleteDiaryEntry(date) {
        return this.delete(`/api/v1/plugins/diary/entries/${date}`);
    }
    /**
     * 搜索日记
     */
    async searchDiaryEntries(params) {
        return this.get('/api/v1/plugins/diary/search', params);
    }
    /**
     * 获取日记统计
     */
    async getDiaryStats() {
        return this.get('/api/v1/plugins/diary/stats');
    }
    // ==================== Checkin API ====================
    async getCheckinItems(params) {
        return this.get('/api/v1/plugins/checkin/items', params);
    }
    async getCheckinItem(id) {
        return this.get(`/api/v1/plugins/checkin/items/${id}`);
    }
    async createCheckinItem(data) {
        return this.post('/api/v1/plugins/checkin/items', data);
    }
    async updateCheckinItem(id, data) {
        return this.put(`/api/v1/plugins/checkin/items/${id}`, data);
    }
    async deleteCheckinItem(id) {
        return this.delete(`/api/v1/plugins/checkin/items/${id}`);
    }
    async addCheckinRecord(itemId, data) {
        return this.post(`/api/v1/plugins/checkin/items/${itemId}/checkin`, data);
    }
    async getCheckinStats() {
        return this.get('/api/v1/plugins/checkin/stats');
    }
    // ==================== Day API ====================
    async getMemorialDays(params) {
        return this.get('/api/v1/plugins/day/days', params);
    }
    async getMemorialDay(id) {
        return this.get(`/api/v1/plugins/day/days/${id}`);
    }
    async createMemorialDay(data) {
        return this.post('/api/v1/plugins/day/days', data);
    }
    async updateMemorialDay(id, data) {
        return this.put(`/api/v1/plugins/day/days/${id}`, data);
    }
    async deleteMemorialDay(id) {
        return this.delete(`/api/v1/plugins/day/days/${id}`);
    }
    async searchMemorialDays(params) {
        return this.get('/api/v1/plugins/day/search', params);
    }
    async getDayStats() {
        return this.get('/api/v1/plugins/day/stats');
    }
    // ==================== Tracker API ====================
    async getTrackerGoals(params) {
        return this.get('/api/v1/plugins/tracker/goals', params);
    }
    async getTrackerGoal(id) {
        return this.get(`/api/v1/plugins/tracker/goals/${id}`);
    }
    async createTrackerGoal(data) {
        return this.post('/api/v1/plugins/tracker/goals', data);
    }
    async updateTrackerGoal(id, data) {
        return this.put(`/api/v1/plugins/tracker/goals/${id}`, data);
    }
    async deleteTrackerGoal(id) {
        return this.delete(`/api/v1/plugins/tracker/goals/${id}`);
    }
    async addTrackerRecord(data) {
        return this.post('/api/v1/plugins/tracker/records', data);
    }
    async getTrackerRecords(goalId) {
        return this.get(`/api/v1/plugins/tracker/goals/${goalId}/records`);
    }
    async getTrackerStats() {
        return this.get('/api/v1/plugins/tracker/stats');
    }
    // ==================== Contact API ====================
    async getContacts(params) {
        return this.get('/api/v1/plugins/contact/contacts', params);
    }
    async getContact(id) {
        return this.get(`/api/v1/plugins/contact/contacts/${id}`);
    }
    async createContact(data) {
        return this.post('/api/v1/plugins/contact/contacts', data);
    }
    async updateContact(id, data) {
        return this.put(`/api/v1/plugins/contact/contacts/${id}`, data);
    }
    async deleteContact(id) {
        return this.delete(`/api/v1/plugins/contact/contacts/${id}`);
    }
    async searchContacts(keyword) {
        return this.get('/api/v1/plugins/contact/contacts/search', { keyword });
    }
    async getContactStats() {
        return this.get('/api/v1/plugins/contact/stats/total-contacts');
    }
    // ==================== Calendar API ====================
    async getCalendarEvents(params) {
        return this.get('/api/v1/plugins/calendar/events', params);
    }
    async getCalendarEvent(id) {
        return this.get(`/api/v1/plugins/calendar/events/${id}`);
    }
    async createCalendarEvent(data) {
        return this.post('/api/v1/plugins/calendar/events', data);
    }
    async updateCalendarEvent(id, data) {
        return this.put(`/api/v1/plugins/calendar/events/${id}`, data);
    }
    async deleteCalendarEvent(id) {
        return this.delete(`/api/v1/plugins/calendar/events/${id}`);
    }
    async completeCalendarEvent(id) {
        return this.post(`/api/v1/plugins/calendar/events/${id}/complete`);
    }
    async searchCalendarEvents(keyword) {
        return this.get('/api/v1/plugins/calendar/events/search', { keyword });
    }
}
//# sourceMappingURL=memento-client.js.map
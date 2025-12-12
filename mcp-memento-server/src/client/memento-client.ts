/**
 * Memento HTTP 客户端
 */

import type { MementoConfig, ApiResponse, PaginatedResponse } from '../types/index.js';

export class MementoClient {
  private config: MementoConfig;

  constructor(config: MementoConfig) {
    this.config = config;
  }

  /**
   * 发送 GET 请求
   */
  async get<T>(path: string, params?: Record<string, string>): Promise<ApiResponse<T>> {
    let url = `${this.config.serverUrl}${path}`;
    if (params && Object.keys(params).length > 0) {
      const searchParams = new URLSearchParams(params);
      url += `?${searchParams.toString()}`;
    }

    const response = await fetch(url, {
      method: 'GET',
      headers: this.getHeaders(),
    });

    return this.handleResponse<T>(response);
  }

  /**
   * 发送 POST 请求
   */
  async post<T>(path: string, body?: unknown): Promise<ApiResponse<T>> {
    const response = await fetch(`${this.config.serverUrl}${path}`, {
      method: 'POST',
      headers: this.getHeaders(),
      body: body ? JSON.stringify(body) : undefined,
    });

    return this.handleResponse<T>(response);
  }

  /**
   * 发送 PUT 请求
   */
  async put<T>(path: string, body?: unknown): Promise<ApiResponse<T>> {
    const response = await fetch(`${this.config.serverUrl}${path}`, {
      method: 'PUT',
      headers: this.getHeaders(),
      body: body ? JSON.stringify(body) : undefined,
    });

    return this.handleResponse<T>(response);
  }

  /**
   * 发送 DELETE 请求
   */
  async delete<T>(path: string, params?: Record<string, string>): Promise<ApiResponse<T>> {
    let url = `${this.config.serverUrl}${path}`;
    if (params && Object.keys(params).length > 0) {
      const searchParams = new URLSearchParams(params);
      url += `?${searchParams.toString()}`;
    }

    const response = await fetch(url, {
      method: 'DELETE',
      headers: this.getHeaders(),
    });

    return this.handleResponse<T>(response);
  }

  /**
   * 获取请求头
   */
  private getHeaders(): Record<string, string> {
    return {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${this.config.authToken}`,
    };
  }

  /**
   * 处理响应
   */
  private async handleResponse<T>(response: Response): Promise<ApiResponse<T>> {
    const data = await response.json() as ApiResponse<T>;

    if (!data.success) {
      throw new Error(data.error || `请求失败: ${response.status}`);
    }

    return data;
  }

  // ==================== Chat API ====================

  /**
   * 获取频道列表
   */
  async getChannels(params?: { offset?: number; count?: number }) {
    return this.get('/api/v1/plugins/chat/channels', params as Record<string, string>);
  }

  /**
   * 创建频道
   */
  async createChannel(data: { name: string; description?: string; avatar?: string }) {
    return this.post('/api/v1/plugins/chat/channels', data);
  }

  /**
   * 获取消息列表
   */
  async getMessages(channelId: string, params?: { offset?: number; count?: number }) {
    return this.get(`/api/v1/plugins/chat/channels/${channelId}/messages`, params as Record<string, string>);
  }

  /**
   * 发送消息
   */
  async sendMessage(channelId: string, data: {
    content: string;
    senderId: string;
    senderName: string;
    type?: string;
    metadata?: Record<string, unknown>;
  }) {
    return this.post(`/api/v1/plugins/chat/channels/${channelId}/messages`, data);
  }

  // ==================== Notes API ====================

  /**
   * 获取笔记列表
   */
  async getNotes(params?: { folderId?: string; offset?: number; count?: number }) {
    return this.get('/api/v1/plugins/notes/notes', params as Record<string, string>);
  }

  /**
   * 创建笔记
   */
  async createNote(data: {
    title: string;
    content: string;
    folderId?: string;
    tags?: string[];
  }) {
    return this.post('/api/v1/plugins/notes/notes', data);
  }

  /**
   * 更新笔记
   */
  async updateNote(id: string, data: {
    title?: string;
    content?: string;
    folderId?: string;
    tags?: string[];
  }) {
    return this.put(`/api/v1/plugins/notes/notes/${id}`, data);
  }

  /**
   * 搜索笔记
   */
  async searchNotes(keyword: string, params?: { offset?: number; count?: number }) {
    const queryParams: Record<string, string> = { keyword };
    if (params?.offset !== undefined) queryParams.offset = String(params.offset);
    if (params?.count !== undefined) queryParams.count = String(params.count);
    return this.get('/api/v1/plugins/notes/search', queryParams);
  }

  // ==================== Activity API ====================

  /**
   * 获取活动列表
   */
  async getActivities(params?: { date?: string; offset?: number; count?: number }) {
    return this.get('/api/v1/plugins/activity/activities', params as Record<string, string>);
  }

  /**
   * 创建活动
   */
  async createActivity(data: {
    startTime: string;
    endTime: string;
    title: string;
    tags?: string[];
    description?: string;
    mood?: number;
  }) {
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
  async getWarehouses(params?: { offset?: number; count?: number }) {
    return this.get('/api/v1/plugins/goods/warehouses', params as Record<string, string>);
  }

  /**
   * 获取物品列表
   */
  async getItems(params?: { warehouseId?: string; offset?: number; count?: number }) {
    return this.get('/api/v1/plugins/goods/items', params as Record<string, string>);
  }

  /**
   * 创建物品
   */
  async createItem(data: {
    name: string;
    warehouseId: string;
    description?: string;
    quantity?: number;
    category?: string;
    tags?: string[];
  }) {
    return this.post('/api/v1/plugins/goods/items', data);
  }

  /**
   * 搜索物品
   */
  async searchItems(keyword: string, params?: { warehouseId?: string }) {
    return this.get('/api/v1/plugins/goods/search', { keyword, ...params } as Record<string, string>);
  }

  // ==================== Bill API ====================

  /**
   * 获取账户列表
   */
  async getAccounts(params?: { offset?: number; count?: number }) {
    return this.get('/api/v1/plugins/bill/accounts', params as Record<string, string>);
  }

  /**
   * 获取账单列表
   */
  async getBills(accountId: string, params?: { offset?: number; count?: number }) {
    return this.get(`/api/v1/plugins/bill/accounts/${accountId}/bills`, params as Record<string, string>);
  }

  /**
   * 创建账单
   */
  async createBill(accountId: string, data: {
    type: 'income' | 'expense' | 'transfer';
    amount: number;
    category?: string;
    description?: string;
    date?: string;
    tags?: string[];
  }) {
    return this.post(`/api/v1/plugins/bill/accounts/${accountId}/bills`, data);
  }

  /**
   * 获取账单统计
   */
  async getBillStats(params?: { startDate?: string; endDate?: string }) {
    return this.get('/api/v1/plugins/bill/stats', params as Record<string, string>);
  }

  // ==================== Todo API ====================

  /**
   * 获取任务列表
   */
  async getTasks(params?: {
    completed?: string;
    priority?: string;
    category?: string;
    offset?: number;
    count?: number;
  }) {
    return this.get('/api/v1/plugins/todo/tasks', params as Record<string, string>);
  }

  /**
   * 创建任务
   */
  async createTask(data: {
    title: string;
    description?: string;
    dueDate?: string;
    priority?: number;
    category?: string;
    tags?: string[];
  }) {
    return this.post('/api/v1/plugins/todo/tasks', data);
  }

  /**
   * 更新任务
   */
  async updateTask(id: string, data: {
    title?: string;
    description?: string;
    completed?: boolean;
    dueDate?: string;
    priority?: number;
    category?: string;
    tags?: string[];
  }) {
    return this.put(`/api/v1/plugins/todo/tasks/${id}`, data);
  }

  /**
   * 完成任务
   */
  async completeTask(id: string) {
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
  async searchTasks(keyword: string) {
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
  async getDiaryEntries(params?: { startDate?: string; endDate?: string; offset?: number; count?: number }) {
    return this.get('/api/v1/plugins/diary/entries', params as Record<string, string>);
  }

  /**
   * 获取指定日期的日记
   */
  async getDiaryEntry(date: string) {
    return this.get(`/api/v1/plugins/diary/entries/${date}`);
  }

  /**
   * 创建日记
   */
  async createDiaryEntry(data: {
    date: string;
    content: string;
    mood?: number;
    weather?: string;
    tags?: string[];
  }) {
    return this.post('/api/v1/plugins/diary/entries', data);
  }

  /**
   * 更新日记
   */
  async updateDiaryEntry(date: string, data: {
    content?: string;
    mood?: number;
    weather?: string;
    tags?: string[];
  }) {
    return this.put(`/api/v1/plugins/diary/entries/${date}`, data);
  }

  /**
   * 删除日记
   */
  async deleteDiaryEntry(date: string) {
    return this.delete(`/api/v1/plugins/diary/entries/${date}`);
  }

  /**
   * 搜索日记
   */
  async searchDiaryEntries(params?: {
    keyword?: string;
    startDate?: string;
    endDate?: string;
    mood?: string;
    offset?: number;
    count?: number;
  }) {
    return this.get('/api/v1/plugins/diary/search', params as Record<string, string>);
  }

  /**
   * 获取日记统计
   */
  async getDiaryStats() {
    return this.get('/api/v1/plugins/diary/stats');
  }

  // ==================== Checkin API ====================

  async getCheckinItems(params?: { offset?: number; count?: number }) {
    return this.get('/api/v1/plugins/checkin/items', params as Record<string, string>);
  }

  async getCheckinItem(id: string) {
    return this.get(`/api/v1/plugins/checkin/items/${id}`);
  }

  async createCheckinItem(data: { name: string; icon?: string; color?: string; group?: string; description?: string }) {
    return this.post('/api/v1/plugins/checkin/items', data);
  }

  async updateCheckinItem(id: string, data: { name?: string; icon?: string; color?: string; group?: string; description?: string }) {
    return this.put(`/api/v1/plugins/checkin/items/${id}`, data);
  }

  async deleteCheckinItem(id: string) {
    return this.delete(`/api/v1/plugins/checkin/items/${id}`);
  }

  async addCheckinRecord(itemId: string, data: { date: string; note?: string }) {
    return this.post(`/api/v1/plugins/checkin/items/${itemId}/checkin`, data);
  }

  async getCheckinStats() {
    return this.get('/api/v1/plugins/checkin/stats');
  }

  // ==================== Day API ====================

  async getMemorialDays(params?: { sortMode?: string; offset?: number; count?: number }) {
    return this.get('/api/v1/plugins/day/days', params as Record<string, string>);
  }

  async getMemorialDay(id: string) {
    return this.get(`/api/v1/plugins/day/days/${id}`);
  }

  async createMemorialDay(data: { name: string; date: string; type?: string; description?: string; color?: string }) {
    return this.post('/api/v1/plugins/day/days', data);
  }

  async updateMemorialDay(id: string, data: { name?: string; date?: string; type?: string; description?: string; color?: string }) {
    return this.put(`/api/v1/plugins/day/days/${id}`, data);
  }

  async deleteMemorialDay(id: string) {
    return this.delete(`/api/v1/plugins/day/days/${id}`);
  }

  async searchMemorialDays(params?: { sortMode?: string; startDate?: string; endDate?: string; includeExpired?: boolean }) {
    return this.get('/api/v1/plugins/day/search', params as Record<string, string>);
  }

  async getDayStats() {
    return this.get('/api/v1/plugins/day/stats');
  }

  // ==================== Tracker API ====================

  async getTrackerGoals(params?: { offset?: number; count?: number }) {
    return this.get('/api/v1/plugins/tracker/goals', params as Record<string, string>);
  }

  async getTrackerGoal(id: string) {
    return this.get(`/api/v1/plugins/tracker/goals/${id}`);
  }

  async createTrackerGoal(data: { name: string; targetValue: number; unit: string; group?: string; description?: string }) {
    return this.post('/api/v1/plugins/tracker/goals', data);
  }

  async updateTrackerGoal(id: string, data: { name?: string; targetValue?: number; unit?: string; group?: string; description?: string }) {
    return this.put(`/api/v1/plugins/tracker/goals/${id}`, data);
  }

  async deleteTrackerGoal(id: string) {
    return this.delete(`/api/v1/plugins/tracker/goals/${id}`);
  }

  async addTrackerRecord(data: { goalId: string; value: number; date: string; note?: string }) {
    return this.post('/api/v1/plugins/tracker/records', data);
  }

  async getTrackerRecords(goalId: string) {
    return this.get(`/api/v1/plugins/tracker/goals/${goalId}/records`);
  }

  async getTrackerStats() {
    return this.get('/api/v1/plugins/tracker/stats');
  }

  // ==================== Contact API ====================

  async getContacts(params?: { offset?: number; count?: number }) {
    return this.get('/api/v1/plugins/contact/contacts', params as Record<string, string>);
  }

  async getContact(id: string) {
    return this.get(`/api/v1/plugins/contact/contacts/${id}`);
  }

  async createContact(data: { name: string; phone?: string; email?: string; tags?: string[]; notes?: string }) {
    return this.post('/api/v1/plugins/contact/contacts', data);
  }

  async updateContact(id: string, data: { name?: string; phone?: string; email?: string; tags?: string[]; notes?: string }) {
    return this.put(`/api/v1/plugins/contact/contacts/${id}`, data);
  }

  async deleteContact(id: string) {
    return this.delete(`/api/v1/plugins/contact/contacts/${id}`);
  }

  async searchContacts(keyword: string) {
    return this.get('/api/v1/plugins/contact/contacts/search', { keyword });
  }

  async getContactStats() {
    return this.get('/api/v1/plugins/contact/stats/total-contacts');
  }

  // ==================== Calendar API ====================

  async getCalendarEvents(params?: { startDate?: string; endDate?: string; offset?: number; count?: number }) {
    return this.get('/api/v1/plugins/calendar/events', params as Record<string, string>);
  }

  async getCalendarEvent(id: string) {
    return this.get(`/api/v1/plugins/calendar/events/${id}`);
  }

  async createCalendarEvent(data: { title: string; startTime: string; endTime?: string; description?: string; location?: string }) {
    return this.post('/api/v1/plugins/calendar/events', data);
  }

  async updateCalendarEvent(id: string, data: { title?: string; startTime?: string; endTime?: string; description?: string; location?: string }) {
    return this.put(`/api/v1/plugins/calendar/events/${id}`, data);
  }

  async deleteCalendarEvent(id: string) {
    return this.delete(`/api/v1/plugins/calendar/events/${id}`);
  }

  async completeCalendarEvent(id: string) {
    return this.post(`/api/v1/plugins/calendar/events/${id}/complete`);
  }

  async searchCalendarEvents(keyword: string) {
    return this.get('/api/v1/plugins/calendar/events/search', { keyword });
  }
}

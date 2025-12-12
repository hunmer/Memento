/**
 * Memento HTTP 客户端
 */
import type { MementoConfig, ApiResponse } from '../types/index.js';
export declare class MementoClient {
    private config;
    constructor(config: MementoConfig);
    /**
     * 发送 GET 请求
     */
    get<T>(path: string, params?: Record<string, string>): Promise<ApiResponse<T>>;
    /**
     * 发送 POST 请求
     */
    post<T>(path: string, body?: unknown): Promise<ApiResponse<T>>;
    /**
     * 发送 PUT 请求
     */
    put<T>(path: string, body?: unknown): Promise<ApiResponse<T>>;
    /**
     * 发送 DELETE 请求
     */
    delete<T>(path: string, params?: Record<string, string>): Promise<ApiResponse<T>>;
    /**
     * 获取请求头
     */
    private getHeaders;
    /**
     * 处理响应
     */
    private handleResponse;
    /**
     * 获取频道列表
     */
    getChannels(params?: {
        offset?: number;
        count?: number;
    }): Promise<ApiResponse<unknown>>;
    /**
     * 创建频道
     */
    createChannel(data: {
        name: string;
        description?: string;
        avatar?: string;
    }): Promise<ApiResponse<unknown>>;
    /**
     * 获取消息列表
     */
    getMessages(channelId: string, params?: {
        offset?: number;
        count?: number;
    }): Promise<ApiResponse<unknown>>;
    /**
     * 发送消息
     */
    sendMessage(channelId: string, data: {
        content: string;
        senderId: string;
        senderName: string;
        type?: string;
        metadata?: Record<string, unknown>;
    }): Promise<ApiResponse<unknown>>;
    /**
     * 获取笔记列表
     */
    getNotes(params?: {
        folderId?: string;
        offset?: number;
        count?: number;
    }): Promise<ApiResponse<unknown>>;
    /**
     * 创建笔记
     */
    createNote(data: {
        title: string;
        content: string;
        folderId?: string;
        tags?: string[];
    }): Promise<ApiResponse<unknown>>;
    /**
     * 更新笔记
     */
    updateNote(id: string, data: {
        title?: string;
        content?: string;
        folderId?: string;
        tags?: string[];
    }): Promise<ApiResponse<unknown>>;
    /**
     * 搜索笔记
     */
    searchNotes(keyword: string, params?: {
        offset?: number;
        count?: number;
    }): Promise<ApiResponse<unknown>>;
    /**
     * 获取活动列表
     */
    getActivities(params?: {
        date?: string;
        offset?: number;
        count?: number;
    }): Promise<ApiResponse<unknown>>;
    /**
     * 创建活动
     */
    createActivity(data: {
        startTime: string;
        endTime: string;
        title: string;
        tags?: string[];
        description?: string;
        mood?: number;
    }): Promise<ApiResponse<unknown>>;
    /**
     * 获取今日统计
     */
    getTodayStats(): Promise<ApiResponse<unknown>>;
    /**
     * 获取仓库列表
     */
    getWarehouses(params?: {
        offset?: number;
        count?: number;
    }): Promise<ApiResponse<unknown>>;
    /**
     * 获取物品列表
     */
    getItems(params?: {
        warehouseId?: string;
        offset?: number;
        count?: number;
    }): Promise<ApiResponse<unknown>>;
    /**
     * 创建物品
     */
    createItem(data: {
        name: string;
        warehouseId: string;
        description?: string;
        quantity?: number;
        category?: string;
        tags?: string[];
    }): Promise<ApiResponse<unknown>>;
    /**
     * 搜索物品
     */
    searchItems(keyword: string, params?: {
        warehouseId?: string;
    }): Promise<ApiResponse<unknown>>;
    /**
     * 获取账户列表
     */
    getAccounts(params?: {
        offset?: number;
        count?: number;
    }): Promise<ApiResponse<unknown>>;
    /**
     * 获取账单列表
     */
    getBills(accountId: string, params?: {
        offset?: number;
        count?: number;
    }): Promise<ApiResponse<unknown>>;
    /**
     * 创建账单
     */
    createBill(accountId: string, data: {
        type: 'income' | 'expense' | 'transfer';
        amount: number;
        category?: string;
        description?: string;
        date?: string;
        tags?: string[];
    }): Promise<ApiResponse<unknown>>;
    /**
     * 获取账单统计
     */
    getBillStats(params?: {
        startDate?: string;
        endDate?: string;
    }): Promise<ApiResponse<unknown>>;
    /**
     * 获取任务列表
     */
    getTasks(params?: {
        completed?: string;
        priority?: string;
        category?: string;
        offset?: number;
        count?: number;
    }): Promise<ApiResponse<unknown>>;
    /**
     * 创建任务
     */
    createTask(data: {
        title: string;
        description?: string;
        dueDate?: string;
        priority?: number;
        category?: string;
        tags?: string[];
    }): Promise<ApiResponse<unknown>>;
    /**
     * 更新任务
     */
    updateTask(id: string, data: {
        title?: string;
        description?: string;
        completed?: boolean;
        dueDate?: string;
        priority?: number;
        category?: string;
        tags?: string[];
    }): Promise<ApiResponse<unknown>>;
    /**
     * 完成任务
     */
    completeTask(id: string): Promise<ApiResponse<unknown>>;
    /**
     * 获取今日任务
     */
    getTodayTasks(): Promise<ApiResponse<unknown>>;
    /**
     * 获取过期任务
     */
    getOverdueTasks(): Promise<ApiResponse<unknown>>;
    /**
     * 搜索任务
     */
    searchTasks(keyword: string): Promise<ApiResponse<unknown>>;
    /**
     * 获取任务统计
     */
    getTodoStats(): Promise<ApiResponse<unknown>>;
    /**
     * 获取日记列表
     */
    getDiaryEntries(params?: {
        startDate?: string;
        endDate?: string;
        offset?: number;
        count?: number;
    }): Promise<ApiResponse<unknown>>;
    /**
     * 获取指定日期的日记
     */
    getDiaryEntry(date: string): Promise<ApiResponse<unknown>>;
    /**
     * 创建日记
     */
    createDiaryEntry(data: {
        date: string;
        content: string;
        mood?: number;
        weather?: string;
        tags?: string[];
    }): Promise<ApiResponse<unknown>>;
    /**
     * 更新日记
     */
    updateDiaryEntry(date: string, data: {
        content?: string;
        mood?: number;
        weather?: string;
        tags?: string[];
    }): Promise<ApiResponse<unknown>>;
    /**
     * 删除日记
     */
    deleteDiaryEntry(date: string): Promise<ApiResponse<unknown>>;
    /**
     * 搜索日记
     */
    searchDiaryEntries(params?: {
        keyword?: string;
        startDate?: string;
        endDate?: string;
        mood?: string;
        offset?: number;
        count?: number;
    }): Promise<ApiResponse<unknown>>;
    /**
     * 获取日记统计
     */
    getDiaryStats(): Promise<ApiResponse<unknown>>;
    getCheckinItems(params?: {
        offset?: number;
        count?: number;
    }): Promise<ApiResponse<unknown>>;
    getCheckinItem(id: string): Promise<ApiResponse<unknown>>;
    createCheckinItem(data: {
        name: string;
        icon?: string;
        color?: string;
        group?: string;
        description?: string;
    }): Promise<ApiResponse<unknown>>;
    updateCheckinItem(id: string, data: {
        name?: string;
        icon?: string;
        color?: string;
        group?: string;
        description?: string;
    }): Promise<ApiResponse<unknown>>;
    deleteCheckinItem(id: string): Promise<ApiResponse<unknown>>;
    addCheckinRecord(itemId: string, data: {
        date: string;
        note?: string;
    }): Promise<ApiResponse<unknown>>;
    getCheckinStats(): Promise<ApiResponse<unknown>>;
    getMemorialDays(params?: {
        sortMode?: string;
        offset?: number;
        count?: number;
    }): Promise<ApiResponse<unknown>>;
    getMemorialDay(id: string): Promise<ApiResponse<unknown>>;
    createMemorialDay(data: {
        name: string;
        date: string;
        type?: string;
        description?: string;
        color?: string;
    }): Promise<ApiResponse<unknown>>;
    updateMemorialDay(id: string, data: {
        name?: string;
        date?: string;
        type?: string;
        description?: string;
        color?: string;
    }): Promise<ApiResponse<unknown>>;
    deleteMemorialDay(id: string): Promise<ApiResponse<unknown>>;
    searchMemorialDays(params?: {
        sortMode?: string;
        startDate?: string;
        endDate?: string;
        includeExpired?: boolean;
    }): Promise<ApiResponse<unknown>>;
    getDayStats(): Promise<ApiResponse<unknown>>;
    getTrackerGoals(params?: {
        offset?: number;
        count?: number;
    }): Promise<ApiResponse<unknown>>;
    getTrackerGoal(id: string): Promise<ApiResponse<unknown>>;
    createTrackerGoal(data: {
        name: string;
        targetValue: number;
        unit: string;
        group?: string;
        description?: string;
    }): Promise<ApiResponse<unknown>>;
    updateTrackerGoal(id: string, data: {
        name?: string;
        targetValue?: number;
        unit?: string;
        group?: string;
        description?: string;
    }): Promise<ApiResponse<unknown>>;
    deleteTrackerGoal(id: string): Promise<ApiResponse<unknown>>;
    addTrackerRecord(data: {
        goalId: string;
        value: number;
        date: string;
        note?: string;
    }): Promise<ApiResponse<unknown>>;
    getTrackerRecords(goalId: string): Promise<ApiResponse<unknown>>;
    getTrackerStats(): Promise<ApiResponse<unknown>>;
    getContacts(params?: {
        offset?: number;
        count?: number;
    }): Promise<ApiResponse<unknown>>;
    getContact(id: string): Promise<ApiResponse<unknown>>;
    createContact(data: {
        name: string;
        phone?: string;
        email?: string;
        tags?: string[];
        notes?: string;
    }): Promise<ApiResponse<unknown>>;
    updateContact(id: string, data: {
        name?: string;
        phone?: string;
        email?: string;
        tags?: string[];
        notes?: string;
    }): Promise<ApiResponse<unknown>>;
    deleteContact(id: string): Promise<ApiResponse<unknown>>;
    searchContacts(keyword: string): Promise<ApiResponse<unknown>>;
    getContactStats(): Promise<ApiResponse<unknown>>;
    getCalendarEvents(params?: {
        startDate?: string;
        endDate?: string;
        offset?: number;
        count?: number;
    }): Promise<ApiResponse<unknown>>;
    getCalendarEvent(id: string): Promise<ApiResponse<unknown>>;
    createCalendarEvent(data: {
        title: string;
        startTime: string;
        endTime?: string;
        description?: string;
        location?: string;
    }): Promise<ApiResponse<unknown>>;
    updateCalendarEvent(id: string, data: {
        title?: string;
        startTime?: string;
        endTime?: string;
        description?: string;
        location?: string;
    }): Promise<ApiResponse<unknown>>;
    deleteCalendarEvent(id: string): Promise<ApiResponse<unknown>>;
    completeCalendarEvent(id: string): Promise<ApiResponse<unknown>>;
    searchCalendarEvents(keyword: string): Promise<ApiResponse<unknown>>;
}
//# sourceMappingURL=memento-client.d.ts.map
/**
 * Memento MCP Server 类型定义
 */

// ==================== 通用类型 ====================

export interface ApiResponse<T = unknown> {
  success: boolean;
  data?: T;
  error?: string;
  timestamp: string;
}

export interface PaginatedResponse<T = unknown> extends ApiResponse<T[]> {
  total: number;
  offset: number;
  count: number;
  hasMore: boolean;
}

// ==================== Chat 类型 ====================

export interface Channel {
  id: string;
  name: string;
  description?: string;
  avatar?: string;
  createdAt: string;
  updatedAt: string;
}

export interface Message {
  id: string;
  channelId: string;
  content: string;
  senderId: string;
  senderName: string;
  type?: string;
  metadata?: Record<string, unknown>;
  createdAt: string;
}

// ==================== Notes 类型 ====================

export interface Note {
  id: string;
  title: string;
  content: string;
  folderId?: string;
  tags?: string[];
  isPinned?: boolean;
  createdAt: string;
  updatedAt: string;
}

export interface Folder {
  id: string;
  name: string;
  parentId?: string;
  color?: string;
  icon?: string;
  createdAt: string;
  updatedAt: string;
}

// ==================== Activity 类型 ====================

export interface Activity {
  id: string;
  startTime: string;
  endTime: string;
  title: string;
  tags?: string[];
  description?: string;
  mood?: number;
  metadata?: Record<string, unknown>;
}

export interface ActivityStats {
  date: string;
  activityCount: number;
  durationMinutes: number;
  durationHours: number;
  remainingMinutes: number;
}

// ==================== Goods 类型 ====================

export interface Warehouse {
  id: string;
  name: string;
  description?: string;
  icon?: string;
  color?: string;
  createdAt: string;
  updatedAt: string;
}

export interface GoodsItem {
  id: string;
  warehouseId?: string;
  warehouseName?: string;
  name: string;
  description?: string;
  quantity: number;
  category?: string;
  tags?: string[];
  customFields?: Record<string, unknown>;
  createdAt: string;
  updatedAt: string;
}

// ==================== Bill 类型 ====================

export interface Account {
  id: string;
  name: string;
  type: string;
  balance: number;
  currency?: string;
  icon?: string;
  color?: string;
  description?: string;
  createdAt: string;
  updatedAt: string;
}

export interface Bill {
  id: string;
  accountId: string;
  type: 'income' | 'expense' | 'transfer';
  amount: number;
  category?: string;
  description?: string;
  date: string;
  tags?: string[];
  createdAt: string;
  updatedAt: string;
}

export interface BillStats {
  totalIncome: number;
  totalExpense: number;
  balance: number;
  billCount: number;
  byCategory?: Record<string, number>;
}

// ==================== Todo 类型 ====================

export interface Task {
  id: string;
  title: string;
  description?: string;
  completed: boolean;
  completedAt?: string;
  dueDate?: string;
  dueTime?: string;
  priority: number;
  category?: string;
  tags?: string[];
  subtasks?: Subtask[];
  reminder?: string;
  repeat?: string;
  notes?: string;
  createdAt: string;
  updatedAt: string;
}

export interface Subtask {
  id: string;
  title: string;
  completed: boolean;
}

export interface TodoStats {
  total: number;
  completed: number;
  pending: number;
  overdue: number;
  today: number;
  todayCompleted: number;
  completionRate: string;
  byPriority: {
    none: number;
    low: number;
    medium: number;
    high: number;
  };
  byCategory: Record<string, number>;
}

// ==================== 配置类型 ====================

export interface MementoConfig {
  serverUrl: string;
  authToken: string;
}

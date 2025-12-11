#!/usr/bin/env node
/**
 * Memento MCP Server
 *
 * 提供 AI 工具用于管理 Memento 应用中的个人数据
 *
 * 环境变量:
 * - MEMENTO_SERVER_URL: Memento 服务器地址 (如 http://localhost:8080)
 * - MEMENTO_AUTH_TOKEN: JWT 认证令牌
 */

import 'dotenv/config';

import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
} from '@modelcontextprotocol/sdk/types.js';

import { loadConfig, validateConfig } from './config.js';
import { MementoClient } from './client/memento-client.js';
import { getToolDefinitions } from './tools/index.js';

async function main() {
  // 加载配置
  let config;
  try {
    config = loadConfig();
    validateConfig(config);
  } catch (error) {
    console.error('配置错误:', error instanceof Error ? error.message : error);
    console.error('');
    console.error('请设置以下环境变量:');
    console.error('  MEMENTO_SERVER_URL - Memento 服务器地址');
    console.error('  MEMENTO_AUTH_TOKEN - JWT 认证令牌');
    process.exit(1);
  }

  // 创建 HTTP 客户端
  const client = new MementoClient(config);

  // 创建 MCP 服务器
  const server = new Server(
    {
      name: 'mcp-memento-server',
      version: '1.0.0',
    },
    {
      capabilities: {
        tools: {},
      },
    }
  );

  // 注册工具列表处理器
  server.setRequestHandler(ListToolsRequestSchema, async () => {
    return {
      tools: getToolDefinitions(),
    };
  });

  // 注册工具调用处理器
  server.setRequestHandler(CallToolRequestSchema, async (request) => {
    const { name, arguments: args } = request.params;

    try {
      switch (name) {
        // ==================== Chat 工具 ====================

        case 'memento_chat_getChannels': {
          const result = await client.getChannels(args as { offset?: number; count?: number });
          return { content: [{ type: 'text', text: JSON.stringify(result.data, null, 2) }] };
        }

        case 'memento_chat_createChannel': {
          const result = await client.createChannel(args as { name: string; description?: string });
          return { content: [{ type: 'text', text: JSON.stringify(result.data, null, 2) }] };
        }

        case 'memento_chat_getMessages': {
          const { channelId, ...params } = args as { channelId: string; offset?: number; count?: number };
          const result = await client.getMessages(channelId, params);
          return { content: [{ type: 'text', text: JSON.stringify(result.data, null, 2) }] };
        }

        case 'memento_chat_sendMessage': {
          const { channelId, ...data } = args as {
            channelId: string;
            content: string;
            senderId: string;
            senderName: string;
          };
          const result = await client.sendMessage(channelId, data);
          return { content: [{ type: 'text', text: JSON.stringify(result.data, null, 2) }] };
        }

        // ==================== Notes 工具 ====================

        case 'memento_notes_getNotes': {
          const result = await client.getNotes(args as { folderId?: string; offset?: number; count?: number });
          return { content: [{ type: 'text', text: JSON.stringify(result.data, null, 2) }] };
        }

        case 'memento_notes_createNote': {
          const result = await client.createNote(args as {
            title: string;
            content: string;
            folderId?: string;
            tags?: string[];
          });
          return { content: [{ type: 'text', text: JSON.stringify(result.data, null, 2) }] };
        }

        case 'memento_notes_updateNote': {
          const { id, ...data } = args as {
            id: string;
            title?: string;
            content?: string;
            tags?: string[];
          };
          const result = await client.updateNote(id, data);
          return { content: [{ type: 'text', text: JSON.stringify(result.data, null, 2) }] };
        }

        case 'memento_notes_searchNotes': {
          const { keyword, ...params } = args as { keyword: string; offset?: number; count?: number };
          const result = await client.searchNotes(keyword, params);
          return { content: [{ type: 'text', text: JSON.stringify(result.data, null, 2) }] };
        }

        // ==================== Activity 工具 ====================

        case 'memento_activity_getActivities': {
          const result = await client.getActivities(args as { date?: string; offset?: number; count?: number });
          return { content: [{ type: 'text', text: JSON.stringify(result.data, null, 2) }] };
        }

        case 'memento_activity_createActivity': {
          const result = await client.createActivity(args as {
            startTime: string;
            endTime: string;
            title: string;
            tags?: string[];
            description?: string;
            mood?: number;
          });
          return { content: [{ type: 'text', text: JSON.stringify(result.data, null, 2) }] };
        }

        case 'memento_activity_getTodayStats': {
          const result = await client.getTodayStats();
          return { content: [{ type: 'text', text: JSON.stringify(result.data, null, 2) }] };
        }

        // ==================== Goods 工具 ====================

        case 'memento_goods_getWarehouses': {
          const result = await client.getWarehouses(args as { offset?: number; count?: number });
          return { content: [{ type: 'text', text: JSON.stringify(result.data, null, 2) }] };
        }

        case 'memento_goods_getItems': {
          const result = await client.getItems(args as { warehouseId?: string; offset?: number; count?: number });
          return { content: [{ type: 'text', text: JSON.stringify(result.data, null, 2) }] };
        }

        case 'memento_goods_createItem': {
          const result = await client.createItem(args as {
            name: string;
            warehouseId: string;
            description?: string;
            quantity?: number;
            category?: string;
            tags?: string[];
          });
          return { content: [{ type: 'text', text: JSON.stringify(result.data, null, 2) }] };
        }

        case 'memento_goods_searchItems': {
          const { keyword, ...params } = args as { keyword: string; warehouseId?: string };
          const result = await client.searchItems(keyword, params);
          return { content: [{ type: 'text', text: JSON.stringify(result.data, null, 2) }] };
        }

        // ==================== Bill 工具 ====================

        case 'memento_bill_getAccounts': {
          const result = await client.getAccounts(args as { offset?: number; count?: number });
          return { content: [{ type: 'text', text: JSON.stringify(result.data, null, 2) }] };
        }

        case 'memento_bill_getBills': {
          const { accountId, ...params } = args as { accountId: string; offset?: number; count?: number };
          const result = await client.getBills(accountId, params);
          return { content: [{ type: 'text', text: JSON.stringify(result.data, null, 2) }] };
        }

        case 'memento_bill_createBill': {
          const { accountId, ...data } = args as {
            accountId: string;
            type: 'income' | 'expense' | 'transfer';
            amount: number;
            category?: string;
            description?: string;
            date?: string;
          };
          const result = await client.createBill(accountId, data);
          return { content: [{ type: 'text', text: JSON.stringify(result.data, null, 2) }] };
        }

        case 'memento_bill_getStats': {
          const result = await client.getBillStats(args as { startDate?: string; endDate?: string });
          return { content: [{ type: 'text', text: JSON.stringify(result.data, null, 2) }] };
        }

        // ==================== Todo 工具 ====================

        case 'memento_todo_getTasks': {
          const result = await client.getTasks(args as {
            completed?: string;
            priority?: string;
            category?: string;
            offset?: number;
            count?: number;
          });
          return { content: [{ type: 'text', text: JSON.stringify(result.data, null, 2) }] };
        }

        case 'memento_todo_createTask': {
          const result = await client.createTask(args as {
            title: string;
            description?: string;
            dueDate?: string;
            priority?: number;
            category?: string;
            tags?: string[];
          });
          return { content: [{ type: 'text', text: JSON.stringify(result.data, null, 2) }] };
        }

        case 'memento_todo_updateTask': {
          const { id, ...data } = args as {
            id: string;
            title?: string;
            description?: string;
            completed?: boolean;
            dueDate?: string;
            priority?: number;
          };
          const result = await client.updateTask(id, data);
          return { content: [{ type: 'text', text: JSON.stringify(result.data, null, 2) }] };
        }

        case 'memento_todo_completeTask': {
          const { id } = args as { id: string };
          const result = await client.completeTask(id);
          return { content: [{ type: 'text', text: JSON.stringify(result.data, null, 2) }] };
        }

        case 'memento_todo_getTodayTasks': {
          const result = await client.getTodayTasks();
          return { content: [{ type: 'text', text: JSON.stringify(result.data, null, 2) }] };
        }

        case 'memento_todo_getOverdueTasks': {
          const result = await client.getOverdueTasks();
          return { content: [{ type: 'text', text: JSON.stringify(result.data, null, 2) }] };
        }

        case 'memento_todo_searchTasks': {
          const { keyword } = args as { keyword: string };
          const result = await client.searchTasks(keyword);
          return { content: [{ type: 'text', text: JSON.stringify(result.data, null, 2) }] };
        }

        case 'memento_todo_getStats': {
          const result = await client.getTodoStats();
          return { content: [{ type: 'text', text: JSON.stringify(result.data, null, 2) }] };
        }

        default:
          throw new Error(`未知工具: ${name}`);
      }
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      return { content: [{ type: 'text', text: `错误: ${message}` }], isError: true };
    }
  });

  // 启动服务器
  const transport = new StdioServerTransport();
  await server.connect(transport);

  console.error('Memento MCP Server 已启动');
  console.error(`服务器地址: ${config.serverUrl}`);
}

main().catch((error) => {
  console.error('启动失败:', error);
  process.exit(1);
});

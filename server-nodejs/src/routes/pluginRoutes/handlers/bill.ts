import { PluginDataService } from '../../../services/pluginDataService';
import { PluginHandlers, PluginResult } from '../types';
import { generateUUID, createPaginatedResult } from '../utils';
import { addHooksToHandlers, ActionType } from '../hooks';

/**
 * 创建 Bill 插件专用处理器
 *
 * 数据格式：accounts.json 文件包含账户列表，每个账户有嵌套的 bills 数组
 * 账户可能是 JSON 编码的字符串或 Map 对象
 */
export function createBillHandlers(pluginDataService: PluginDataService): PluginHandlers {
  // 读取所有账户（包含嵌套的账单）
  async function readAllAccounts(
    userId: string,
    encryptionKey: string
  ): Promise<Record<string, unknown>[]> {
    const accountsData = await pluginDataService.readPluginData(
      userId,
      'bill',
      'accounts.json',
      encryptionKey
    );

    if (!accountsData) return [];

    const accountsRaw =
      (accountsData as Record<string, unknown>)?.accounts as Array<unknown> || [];
    return accountsRaw
      .map((a: unknown) => {
        // 兼容两种存储格式：
        // 1. 客户端格式：账户是 JSON 编码的字符串
        // 2. 标准格式：账户是 Map 对象
        if (typeof a === 'string') {
          try {
            return JSON.parse(a) as Record<string, unknown>;
          } catch {
            return {};
          }
        }
        return a as Record<string, unknown>;
      })
      .filter((a) => Object.keys(a).length > 0);
  }

  // 保存所有账户
  async function saveAllAccounts(
    userId: string,
    encryptionKey: string,
    accounts: Record<string, unknown>[]
  ): Promise<void> {
    await pluginDataService.writePluginData(
      userId,
      'bill',
      'accounts.json',
      { accounts: accounts.map((a) => JSON.stringify(a)) },
      encryptionKey
    );
  }

  // 将客户端格式的账单转换为标准格式
  function convertClientBillToDto(
    bill: Record<string, unknown>
  ): Record<string, unknown> {
    const amount = (bill.amount as number) || 0;
    const type = amount >= 0 ? 'income' : 'expense';

    return {
      id: bill.id || generateUUID(),
      accountId: bill.accountId || '',
      amount: Math.abs(amount),
      type,
      category: bill.category || '其他',
      description: bill.description || bill.note || '',
      date: bill.date || bill.createdAt || new Date().toISOString(),
      createdAt: bill.createdAt || new Date().toISOString(),
      updatedAt: bill.updatedAt || new Date().toISOString(),
      tags: bill.tags || (bill.tag ? [bill.tag] : []),
      ...bill, // 保留其他字段
    };
  }

  const handlers: PluginHandlers = {
    // 获取账户列表
    async getList(
      userId: string,
      encryptionKey: string,
      params: Record<string, unknown>
    ): Promise<PluginResult> {
      try {
        let accounts = await readAllAccounts(userId, encryptionKey);

        // 转换为 AccountDto（不包含账单列表）
        const accountDtos = accounts.map((a) => ({
          id: a.id,
          name: a.name || a.title,
          balance: a.balance ?? a.totalAmount ?? 0,
          icon: a.icon || (a.iconCodePoint ? String(a.iconCodePoint) : undefined),
          color:
            a.color ||
            (a.backgroundColor
              ? `#${(a.backgroundColor as number).toString(16).padStart(8, '0')}`
              : undefined),
          createdAt: a.createdAt,
          updatedAt: a.updatedAt,
        }));

        const result = createPaginatedResult(accountDtos, {
          offset: params.offset as number,
          count: params.count as number,
        });

        return { isSuccess: true, data: result };
      } catch (e) {
        return { isSuccess: false, message: `获取账户失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },

    // 根据 ID 获取账户
    async getById(
      userId: string,
      encryptionKey: string,
      params: Record<string, unknown>
    ): Promise<PluginResult> {
      try {
        const accounts = await readAllAccounts(userId, encryptionKey);
        const account = accounts.find((a: Record<string, unknown>) => a.id === params.id);

        if (!account) {
          return { isSuccess: false, message: '账户不存在', code: 'NOT_FOUND' };
        }

        const accountDto = {
          id: account.id,
          name: account.name || account.title,
          balance: account.balance ?? account.totalAmount ?? 0,
          icon: account.icon || (account.iconCodePoint ? String(account.iconCodePoint) : undefined),
          color:
            account.color ||
            (account.backgroundColor
              ? `#${(account.backgroundColor as number).toString(16).padStart(8, '0')}`
              : undefined),
          createdAt: account.createdAt,
          updatedAt: account.updatedAt,
        };

        return { isSuccess: true, data: accountDto };
      } catch (e) {
        return { isSuccess: false, message: `获取账户失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },

    // 创建账户
    async create(
      userId: string,
      encryptionKey: string,
      params: Record<string, unknown>
    ): Promise<PluginResult> {
      try {
        const accounts = await readAllAccounts(userId, encryptionKey);
        const now = new Date().toISOString();

        const newAccount = {
          ...params,
          id: params.id || generateUUID(),
          bills: [],
          createdAt: now,
          updatedAt: now,
        };

        accounts.push(newAccount);
        await saveAllAccounts(userId, encryptionKey, accounts);

        return { isSuccess: true, data: newAccount };
      } catch (e) {
        return { isSuccess: false, message: `创建账户失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },

    // 更新账户
    async update(
      userId: string,
      encryptionKey: string,
      params: Record<string, unknown>
    ): Promise<PluginResult> {
      try {
        const accounts = await readAllAccounts(userId, encryptionKey);
        const index = accounts.findIndex((a: Record<string, unknown>) => a.id === params.id);

        if (index === -1) {
          return { isSuccess: false, message: '账户不存在', code: 'NOT_FOUND' };
        }

        const updatedAccount = {
          ...accounts[index],
          ...params,
          updatedAt: new Date().toISOString(),
        };
        accounts[index] = updatedAccount;

        await saveAllAccounts(userId, encryptionKey, accounts);
        return { isSuccess: true, data: updatedAccount };
      } catch (e) {
        return { isSuccess: false, message: `更新账户失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },

    // 删除账户
    async delete(
      userId: string,
      encryptionKey: string,
      params: Record<string, unknown>
    ): Promise<PluginResult> {
      try {
        const accounts = await readAllAccounts(userId, encryptionKey);
        const initialLength = accounts.length;
        const filtered = accounts.filter((a: Record<string, unknown>) => a.id !== params.id);

        if (filtered.length === initialLength) {
          return { isSuccess: false, message: '账户不存在', code: 'NOT_FOUND' };
        }

        await saveAllAccounts(userId, encryptionKey, filtered);
        return { isSuccess: true, data: { id: params.id } };
      } catch (e) {
        return { isSuccess: false, message: `删除账户失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },

    // 获取账单列表
    async getBills(
      userId: string,
      encryptionKey: string,
      params: Record<string, unknown>
    ): Promise<PluginResult> {
      try {
        const accounts = await readAllAccounts(userId, encryptionKey);
        const accountId = params.accountId as string | undefined;
        let allBills: Record<string, unknown>[] = [];

        for (const account of accounts) {
          if (accountId && account.id !== accountId) continue;
          const bills = (account.bills as Array<unknown>) || [];
          allBills = allBills.concat(
            bills.map((b) => convertClientBillToDto(b as Record<string, unknown>))
          );
        }

        // 按日期排序（最新在前）
        allBills.sort((a, b) => {
          const aDate = (a.date as string) || '';
          const bDate = (b.date as string) || '';
          return bDate.localeCompare(aDate);
        });

        const result = createPaginatedResult(allBills, {
          offset: params.offset as number,
          count: params.count as number,
        });

        return { isSuccess: true, data: result };
      } catch (e) {
        return { isSuccess: false, message: `获取账单失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },

    // 获取单个账单
    async getBillById(
      userId: string,
      encryptionKey: string,
      params: Record<string, unknown>
    ): Promise<PluginResult> {
      try {
        const accounts = await readAllAccounts(userId, encryptionKey);

        for (const account of accounts) {
          const bills = (account.bills as Record<string, unknown>[]) || [];
          const bill = bills.find((b) => b.id === params.id);
          if (bill) {
            return { isSuccess: true, data: convertClientBillToDto(bill) };
          }
        }

        return { isSuccess: false, message: '账单不存在', code: 'NOT_FOUND' };
      } catch (e) {
        return { isSuccess: false, message: `获取账单失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },

    // 创建账单
    async createBill(
      userId: string,
      encryptionKey: string,
      params: Record<string, unknown>
    ): Promise<PluginResult> {
      try {
        const accounts = await readAllAccounts(userId, encryptionKey);
        const accountIndex = accounts.findIndex(
          (a: Record<string, unknown>) => a.id === params.accountId
        );

        if (accountIndex === -1) {
          return { isSuccess: false, message: '账户不存在', code: 'NOT_FOUND' };
        }

        const now = new Date().toISOString();
        const newBill = {
          ...params,
          id: params.id || generateUUID(),
          createdAt: now,
          updatedAt: now,
        };

        const account = accounts[accountIndex];
        const bills = (account.bills as Array<unknown>) || [];
        bills.push(newBill);
        account.bills = bills;

        // 更新账户余额
        const amount = (params.amount as number) || 0;
        const currentBalance = (account.balance as number) ?? (account.totalAmount as number) ?? 0;
        account.balance = currentBalance + amount;
        account.updatedAt = now;

        await saveAllAccounts(userId, encryptionKey, accounts);
        return { isSuccess: true, data: convertClientBillToDto(newBill) };
      } catch (e) {
        return { isSuccess: false, message: `创建账单失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },

    // 更新账单
    async updateBill(
      userId: string,
      encryptionKey: string,
      params: Record<string, unknown>
    ): Promise<PluginResult> {
      try {
        const accounts = await readAllAccounts(userId, encryptionKey);

        for (let i = 0; i < accounts.length; i++) {
          const account = accounts[i];
          const bills = (account.bills as Record<string, unknown>[]) || [];
          const billIndex = bills.findIndex((b) => b.id === params.id);

          if (billIndex !== -1) {
            const oldBill = bills[billIndex];
            const oldAmount = (oldBill.amount as number) || 0;
            const newAmount = (params.amount as number) || 0;

            const updatedBill = {
              ...oldBill,
              ...params,
              updatedAt: new Date().toISOString(),
            };
            bills[billIndex] = updatedBill;
            account.bills = bills;

            // 更新账户余额
            const currentBalance = (account.balance as number) ?? (account.totalAmount as number) ?? 0;
            account.balance = currentBalance - oldAmount + newAmount;
            account.updatedAt = new Date().toISOString();

            await saveAllAccounts(userId, encryptionKey, accounts);
            return { isSuccess: true, data: convertClientBillToDto(updatedBill) };
          }
        }

        return { isSuccess: false, message: '账单不存在', code: 'NOT_FOUND' };
      } catch (e) {
        return { isSuccess: false, message: `更新账单失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },

    // 删除账单
    async deleteBill(
      userId: string,
      encryptionKey: string,
      params: Record<string, unknown>
    ): Promise<PluginResult> {
      try {
        const accounts = await readAllAccounts(userId, encryptionKey);

        for (let i = 0; i < accounts.length; i++) {
          const account = accounts[i];
          const bills = (account.bills as Record<string, unknown>[]) || [];
          const billIndex = bills.findIndex((b) => b.id === params.id);

          if (billIndex !== -1) {
            const oldBill = bills[billIndex];
            const oldAmount = (oldBill.amount as number) || 0;

            bills.splice(billIndex, 1);
            account.bills = bills;

            // 更新账户余额
            const currentBalance = (account.balance as number) ?? (account.totalAmount as number) ?? 0;
            account.balance = currentBalance - oldAmount;
            account.updatedAt = new Date().toISOString();

            await saveAllAccounts(userId, encryptionKey, accounts);
            return { isSuccess: true, data: { id: params.id } };
          }
        }

        return { isSuccess: false, message: '账单不存在', code: 'NOT_FOUND' };
      } catch (e) {
        return { isSuccess: false, message: `删除账单失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },

    // 按账户获取账单
    async getBillsByAccount(
      userId: string,
      encryptionKey: string,
      params: Record<string, unknown>
    ): Promise<PluginResult> {
      // 直接复制 getBills 的逻辑，避免使用 this
      try {
        const accounts = await readAllAccounts(userId, encryptionKey);
        const accountId = params.accountId as string | undefined;
        let allBills: Record<string, unknown>[] = [];

        for (const account of accounts) {
          if (accountId && account.id !== accountId) continue;
          const bills = (account.bills as Array<unknown>) || [];
          allBills = allBills.concat(
            bills.map((b) => convertClientBillToDto(b as Record<string, unknown>))
          );
        }

        // 按日期排序（最新在前）
        allBills.sort((a, b) => {
          const aDate = (a.date as string) || '';
          const bDate = (b.date as string) || '';
          return bDate.localeCompare(aDate);
        });

        const result = createPaginatedResult(allBills, {
          offset: params.offset as number,
          count: params.count as number,
        });

        return { isSuccess: true, data: result };
      } catch (e) {
        return { isSuccess: false, message: `获取账单失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },

    // 为账户创建账单
    async createBillForAccount(
      userId: string,
      encryptionKey: string,
      params: Record<string, unknown>
    ): Promise<PluginResult> {
      // 直接复制 createBill 的逻辑，避免使用 this
      try {
        const accounts = await readAllAccounts(userId, encryptionKey);
        const accountIndex = accounts.findIndex(
          (a: Record<string, unknown>) => a.id === params.accountId
        );

        if (accountIndex === -1) {
          return { isSuccess: false, message: '账户不存在', code: 'NOT_FOUND' };
        }

        const now = new Date().toISOString();
        const newBill = {
          ...params,
          id: params.id || generateUUID(),
          createdAt: now,
          updatedAt: now,
        };

        const account = accounts[accountIndex];
        const bills = (account.bills as Array<unknown>) || [];
        bills.push(newBill);
        account.bills = bills;

        // 更新账户余额
        const amount = (params.amount as number) || 0;
        const currentBalance = (account.balance as number) ?? (account.totalAmount as number) ?? 0;
        account.balance = currentBalance + amount;
        account.updatedAt = now;

        await saveAllAccounts(userId, encryptionKey, accounts);
        return { isSuccess: true, data: convertClientBillToDto(newBill) };
      } catch (e) {
        return { isSuccess: false, message: `创建账单失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },

    // 获取统计
    async getStats(
      userId: string,
      encryptionKey: string,
      params: Record<string, unknown>
    ): Promise<PluginResult> {
      try {
        const accounts = await readAllAccounts(userId, encryptionKey);
        let totalIncome = 0;
        let totalExpense = 0;
        let billCount = 0;

        for (const account of accounts) {
          const bills = (account.bills as Array<unknown>) || [];
          for (const bill of bills) {
            const b = bill as Record<string, unknown>;
            const amount = (b.amount as number) || 0;

            if (amount >= 0) {
              totalIncome += amount;
            } else {
              totalExpense += Math.abs(amount);
            }
            billCount++;
          }
        }

        return {
          isSuccess: true,
          data: {
            totalIncome,
            totalExpense,
            balance: totalIncome - totalExpense,
            billCount,
            accountCount: accounts.length,
          },
        };
      } catch (e) {
        return { isSuccess: false, message: `获取统计失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },
  };

  // 定义 handler 到 hook 的映射
  const hookMappings: Record<string, { action: ActionType; entity?: string }> = {
    getList: { action: 'read', entity: 'Account' },
    getById: { action: 'read', entity: 'Account' },
    create: { action: 'create', entity: 'Account' },
    update: { action: 'update', entity: 'Account' },
    delete: { action: 'delete', entity: 'Account' },
    getBills: { action: 'read', entity: 'Bill' },
    getBillById: { action: 'read', entity: 'Bill' },
    createBill: { action: 'create', entity: 'Bill' },
    updateBill: { action: 'update', entity: 'Bill' },
    deleteBill: { action: 'delete', entity: 'Bill' },
    getBillsByAccount: { action: 'read', entity: 'Bill' },
    createBillForAccount: { action: 'create', entity: 'Bill' },
    getStats: { action: 'read', entity: 'BillStats' },
  };

  return addHooksToHandlers('bill', handlers, hookMappings);
}

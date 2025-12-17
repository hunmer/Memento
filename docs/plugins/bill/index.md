# Bill - 账单管理插件

![Bill Plugin](/icon.png)

💰 **Bill 账单管理** - 智能理财助手，让每一分钱都清清楚楚

## 核心功能

### 💳 多账户管理
- **账户类型**：支持储蓄卡、信用卡、现金、电子钱包等多种账户
- **账户信息**：记录账户名称、余额、所属银行、备注等
- **余额同步**：支持手动或自动更新账户余额
- **账户图标**：自定义账户图标，便于识别
- **独立记账**：每个账户独立管理账单和统计

### 📝 收支记录
- **快速记账**：一键记录收入和支出
- **分类管理**：预设多种收支分类（餐饮、交通、购物等）
- **自定义分类**：创建个人专属的收支分类
- **标签系统**：为账单添加标签，实现精细化管理
- **金额规则**：正数表示收入，负数表示支出

### 📊 数据统计
- **收支报表**：按周、月、年查看收支情况
- **分类统计**：各类别支出占比分析，饼图可视化
- **趋势分析**：收支变化趋势图表
- **预算管理**：设置月度/年度预算，超支预警
- **实时统计**：今日财务、本月财务、记账次数

### 🔍 智能搜索
- **日期范围**：快速筛选指定时间段的账单
- **金额范围**：按金额大小筛选账单
- **分类筛选**：按收支分类筛选
- **关键词搜索**：通过备注、标签搜索账单
- **时间范围**：支持本周、本月、本年或自定义日期

### 🤖 AI 数据分析
- **OpenAI 集成**：注册到 AI 助手，提供账单数据分析
- **智能提示**：在 AI 对话中使用 `` {{`bill_getBills()`}} `` 获取数据
- **数据格式**：返回 JSON 格式的统计数据和详细记录
- **日期支持**：支持多种日期格式，自动筛选账单
- **统计分析**：自动计算总收入、总支出、净余额

## 技术架构

### 核心组件

#### 插件主类 (`BillPlugin`)
```dart
class BillPlugin extends PluginBase {
  // 继承 PluginBase，实现插件基本功能
  // 管理账单控制器和 Prompt 控制器
}
```

#### 主界面入口
- **双 Tab 导航**：账单列表视图 + 统计分析视图
- **智能跳转**：无账户时自动跳转到账户管理
- **卡片视图**：主页展示今日财务、本月财务、记账次数

#### 核心控制器
- **BillController**：管理账户和账单的 CRUD 操作
- **PromptController**：注册到 OpenAI 插件，支持 AI 数据分析

### 数据模型

模型#### Account (账户)
```dart
class Account {
  String id;              // UUID v4 唯一标识
  String title;           // 账户名称
  IconData icon;          // 账户图标
  Color backgroundColor;  // 背景颜色
  double totalAmount;     // 账户总金额（自动计算）
  List<Bill> bills;       // 账单列表
}
```

#### Bill (账单模型)
```dart
class Bill {
  String id;          // UUID v4 唯一标识
  String title;       // 账单标题
  double amount;      // 金额（正数=收入，负数=支出）
  String category;    // 分类
  DateTime date;      // 账单日期
  String note;        // 备注（可选）
  String? tag;        // 标签（可选）
  IconData icon;      // 图标
  Color iconColor;    // 图标颜色
  String accountId;   // 所属账户ID
}
```

### 存储结构

#### 本地存储
- **存储路径**：`bill/accounts.json`
- **存储格式**：JSON 字符串数组
- **数据嵌套**：账户内嵌套账单列表

```json
{
  "accounts": [
    "{\"id\":\"...\",\"title\":\"现金账户\",\"totalAmount\":5000.0,\"bills\":[...]}",
    "{\"id\":\"...\",\"title\":\"信用卡\",\"totalAmount\":-1200.0,\"bills\":[...]}"
  ]
}
```

### 对外 API

#### 统计接口
```dart
// 获取今日财务统计（收入+支出净值）
double getTodayFinance();

// 获取本月财务统计（收入+支出净值）
double getMonthFinance();

// 获取本月记账次数
int getMonthBillCount();
```

#### 账单管理接口
```dart
// 账户管理
Future<void> createAccount(Account account);
Future<void> saveAccount(Account account);
Future<void> deleteAccount(String accountId);

// 账单管理
Future<void> saveBill(Bill bill);        // 创建或更新账单
Future<void> deleteBill(String accountId, String billId);
Future<List<Bill>> getBills({DateTime? startDate, DateTime? endDate});

// 统计分析
Future<Map<String, double>> getCategoryStatistics({DateTime? startDate, DateTime? endDate});
Future<double> getTotalIncome({DateTime? startDate, DateTime? endDate});
Future<double> getTotalExpense({DateTime? startDate, DateTime? endDate});
```

### 事件系统

#### 支持的事件类型
| 事件名 | 触发时机 | 参数 |
|-------|---------|------|
| `bill_added` | 新建/更新账单时 | `Bill bill, String accountId` |
| `bill_deleted` | 删除账单时 | `String billId, String accountId` |
| `account_added` | 新建账户时 | `Account account` |
| `account_deleted` | 删除账户时 | `String accountId` |

### 界面层结构

#### 主要界面组件
- **BillListScreen**：账单列表主界面，时间段选择器、统计卡片
- **BillStatsScreen**：统计分析界面，饼图展示、类别排名
- **BillEditScreen**：账单编辑/创建界面
- **AccountListScreen**：账户列表界面
- **AccountEditScreen**：账户编辑/创建界面
- **AccountBillsScreen**：单个账户的账单界面

#### 布局特性
- **时间筛选**：SegmentedButton 支持周/月/年切换
- **滑动删除**：Dismissible 组件，支持确认对话框
- **实时更新**：监听 `BillPlugin` 的 `notifyListeners()` 自动刷新
- **统计卡片**：实时计算选定时间范围内的收支

## 使用场景

### 个人理财
帮助您：
- 了解每月收支状况
- 控制不必要支出
- 制定储蓄计划
- 跟踪投资理财

### 家庭记账
适合家庭用户：
- 记录家庭共同开支
- 分摊生活费用
- 跟踪教育、房贷等大额支出
- 制定家庭预算

### 生意记账
小微企业用户：
- 记录营业收入和成本
- 跟踪客户付款情况
- 分析利润来源
- 制作财务报表

## 操作指南

### 添加账户
1. 进入「账单」插件主界面
2. 如果无账户，自动跳转到账户列表页面
3. 点击右上角的「+」按钮
4. 填写账户名称、选择图标和颜色
5. 保存设置

### 记录账单
1. 在账单列表界面点击「+」按钮
2. 选择收入或支出类型
3. 输入金额（正数=收入，负数=支出）
4. 选择分类和添加备注
5. 选择关联账户
6. 保存账单

### 查看统计
1. 在账单列表中切换到「统计分析」Tab
2. 选择统计周期（周/月/年）
3. 查看收支概览卡片
4. 分析支出分类饼图
5. 浏览类别排名列表

### AI 数据分析
1. 进入 OpenAI 插件对话界面
2. 使用以下格式调用账单数据：
   ```
   请分析我在 `` {{`bill_getBills(startDate: "2025-01-01", endDate: "2025-01-31")`}} `` 的账单数据
   ```
3. AI 将返回 JSON 格式的统计数据和详细记录

## 高级功能

### 数据统计
- **收支概览**：总收入、总支出、结余显示
- **分类饼图**：使用 fl_chart 绘制，直观展示支出占比
- **类别排名**：按支出金额从高到低排序
- **时间筛选**：支持周/月/年或自定义日期范围

### AI 集成功能
- **数据分析**：自动分析账单数据，生成财务洞察
- **智能建议**：基于历史数据提供理财建议
- **趋势预测**：预测未来支出趋势
- **异常检测**：识别异常支出模式

### 事件系统
- **实时广播**：账单和账户变更时自动广播事件
- **插件通信**：其他插件可监听账单事件
- **数据同步**：支持跨插件数据同步

## 数据分析示例

### 返回数据格式
```json
{
  "sum": {
    "tInc": 5000.00,    // 总收入
    "tExp": 3000.00,    // 总支出
    "net": 2000.00      // 净余额
  },
  "catStat": {
    "工资": 5000.00,
    "餐饮": -800.00,
    "交通": -200.00
  },
  "records": [
    {
      "date": "2025-01-15",
      "title": "工资收入",
      "cat": "工资",
      "amt": 5000.00,
      "note": "月度工资"
    }
  ]
}
```

### 使用方法
在 OpenAI 插件中可以使用：
- `` {{`bill_getBills(startDate: "2025-01-01", endDate: "2025-01-31")`}} `` - 指定日期范围
- `` {{`bill_getBills()`}} `` - 获取所有账单数据
- `` {{`bill_getBills(startDate: "2025-01-01")`}} `` - 指定开始日期

## 理财建议

💰 **52周存钱法**：每周递增存款金额，一年下来存下一笔可观资金

💰 **信封理财法**：将不同用途的钱分装在不同的"信封"里，专款专用

💰 **记账习惯**：每天睡前花2分钟记录当天支出，培养良好理财习惯

💰 **定期分析**：每月查看一次账单，分析支出合理性，及时调整消费习惯

## 小贴士

📌 **及时记录**：支出发生后立即记录，避免遗忘

📌 **详细备注**：备注信息越详细，后续查找越方便

📌 **合理分类**：建立适合自己生活的分类体系，不要过于复杂

📌 **金额规则**：正数表示收入，负数表示支出，查看时显示绝对值

📌 **自动计算**：账户总金额会自动计算，无需手动维护

📌 **AI 分析**：充分利用 AI 功能，获得更深入的财务洞察

## 常见问题

**Q: 账单的金额是如何区分收入和支出的？**
A: 通过 `amount` 字段的正负值区分：收入 `amount > 0`，支出 `amount < 0`。

**Q: 账户的 totalAmount 是如何计算的？**
A: 系统自动计算：`totalAmount = bills.fold(0.0, (sum, bill) => sum + bill.amount)`。

**Q: 如何在 AI 分析中使用账单数据？**
A: 在 OpenAI 插件中使用：`` {{`bill_getBills(startDate: "2025-01-01", endDate: "2025-01-31")`}} ``。

**Q: 为什么账户数据使用嵌套的 JSON 字符串？**
A: 简化数据结构，每个账户作为独立 JSON 字符串，便于序列化/反序列化。

**Q: 支持哪些日期格式？**
A: 支持 `YYYY-MM-DD`、`YYYY/MM/DD`、ISO 8601 等多种格式。

**Q: 如何恢复误删的账单？**
A: 当前版本暂不支持回收站功能，建议定期备份数据。

**Q: 账单数据可以导出吗？**
A: 当前版本暂未实现导出功能，可在未来版本中添加 CSV/Excel 导出。

---

*让理财成为一种习惯，让生活更加从容*

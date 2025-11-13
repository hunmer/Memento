# Store 插件 JS API 文档

## 概述

Store 插件提供了 14 个 JS API，用于在 JavaScript 环境中管理商品、积分���用户物品。所有 API 都通过 `window.plugins.store.*` 访问。

---

## API 列表

### 商品管理

#### 1. getProducts
获取所有商品列表

**签名**:
```javascript
async getProducts(): Promise<Product[]>
```

**返回值**:
```typescript
Product[] // 商品数组
```

**示例**:
```javascript
const products = await window.plugins.store.getProducts();
console.log('商品列表:', JSON.parse(products));
```

**返回数据结构**:
```json
[
  {
    "id": "1731473170123",
    "name": "免作业卡",
    "description": "可免除一次作业",
    "image": "assets/card.png",
    "stock": 10,
    "price": 50,
    "exchange_start": "2025-01-01T00:00:00.000Z",
    "exchange_end": "2025-12-31T23:59:59.999Z",
    "use_duration": 30
  }
]
```

---

#### 2. getProduct
获取单个商品详情

**签名**:
```javascript
async getProduct(productId: string): Promise<Product>
```

**参数**:
- `productId`: 商品 ID

**返回值**:
```typescript
Product // 商品对象
```

**异常**:
- 商品不存在时抛出异常

**示例**:
```javascript
const product = await window.plugins.store.getProduct('1731473170123');
console.log('商品详情:', JSON.parse(product));
```

---

#### 3. createProduct
创建新商品

**签名**:
```javascript
async createProduct(
  name: string,
  description: string,
  price: number,
  stock: number,
  exchangeStart: string,
  exchangeEnd: string,
  useDuration: number,
  image?: string
): Promise<Product>
```

**参数**:
- `name`: 商品名称
- `description`: 商品描述
- `price`: 价格（积分）
- `stock`: 库存数量
- `exchangeStart`: 兑换开始时间（ISO 8601 格式）
- `exchangeEnd`: 兑换结束时间（ISO 8601 格式）
- `useDuration`: 使用期限（天数）
- `image`: 商品图片路径（可选）

**返回值**:
```typescript
Product // 创建的商品对象
```

**示例**:
```javascript
const newProduct = await window.plugins.store.createProduct(
  '迟到豁免卡',
  '可豁免一次迟到',
  30,
  20,
  '2025-01-01T00:00:00.000Z',
  '2025-12-31T23:59:59.999Z',
  60,
  'assets/late_pass.png'
);
console.log('创建成功:', JSON.parse(newProduct));
```

---

#### 4. updateProduct
更新商品信息

**签名**:
```javascript
async updateProduct(
  productId: string,
  name: string,
  description: string,
  price: number,
  stock: number,
  exchangeStart: string,
  exchangeEnd: string,
  useDuration: number,
  image?: string
): Promise<Product>
```

**参数**:
- `productId`: 商品 ID
- 其他参数同 `createProduct`

**返回值**:
```typescript
Product // 更新后的商品对象
```

**异常**:
- 商品不存在时抛出异常

**示例**:
```javascript
const updated = await window.plugins.store.updateProduct(
  '1731473170123',
  '免作业卡（升级版）',
  '可免除两次作业',
  100,
  5,
  '2025-01-01T00:00:00.000Z',
  '2025-12-31T23:59:59.999Z',
  60
);
console.log('更新成功:', JSON.parse(updated));
```

---

#### 5. deleteProduct
删除商品（归档）

**签名**:
```javascript
async deleteProduct(productId: string): Promise<boolean>
```

**参数**:
- `productId`: 商品 ID

**返回值**:
```typescript
boolean // 总是返回 true
```

**注意**:
- 商品会被归档而不是物理删除
- 可通过 `restoreProduct` 恢复

**示例**:
```javascript
await window.plugins.store.deleteProduct('1731473170123');
console.log('商品已归档');
```

---

### 兑换功能

#### 6. redeem
兑换商品

**签名**:
```javascript
async redeem(productId: string): Promise<RedeemResult>
```

**参数**:
- `productId`: 商品 ID

**返回值**:
```typescript
{
  success: boolean,
  message: string,
  currentPoints: number
}
```

**示例**:
```javascript
const result = await window.plugins.store.redeem('1731473170123');
const data = JSON.parse(result);
if (data.success) {
  console.log('兑换成功！剩余积分:', data.currentPoints);
} else {
  console.log('兑换失败:', data.message);
}
```

**失败原因**:
- 积分不足
- 库存不足
- 不在兑换期内

---

### 积分管理

#### 7. getPoints
获取当前积分

**签名**:
```javascript
async getPoints(): Promise<number>
```

**返回值**:
```typescript
number // 当前积分值
```

**示例**:
```javascript
const points = await window.plugins.store.getPoints();
console.log('当前积分:', points);
```

---

#### 8. addPoints
添加或扣除积分

**签名**:
```javascript
async addPoints(points: number, reason: string): Promise<PointsResult>
```

**参数**:
- `points`: 积分值（正数增加，负数减少）
- `reason`: 变动原因描述

**返回值**:
```typescript
{
  success: boolean,
  currentPoints: number,
  message: string
}
```

**示例**:
```javascript
// 增加积分
const result1 = await window.plugins.store.addPoints(50, '完成任务奖励');
console.log('增加成功:', JSON.parse(result1));

// 扣除积分
const result2 = await window.plugins.store.addPoints(-20, '购买道具');
console.log('扣除成功:', JSON.parse(result2));
```

---

### 历史记录

#### 9. getRedeemHistory
获取兑换历史

**签名**:
```javascript
async getRedeemHistory(): Promise<UserItem[]>
```

**返回值**:
```typescript
UserItem[] // 用户物品数组
```

**示例**:
```javascript
const history = await window.plugins.store.getRedeemHistory();
console.log('兑换历史:', JSON.parse(history));
```

**返回数据结构**:
```json
[
  {
    "id": "1731473170456",
    "product_id": "1731473170123",
    "remaining": 1,
    "expire_date": "2025-02-15T00:00:00.000Z",
    "purchase_date": "2025-01-15T10:30:00.000Z",
    "purchase_price": 50,
    "product_snapshot": {
      "name": "免作业卡",
      "image": "assets/card.png",
      ...
    }
  }
]
```

---

#### 10. getPointsHistory
获取积分历史

**签名**:
```javascript
async getPointsHistory(): Promise<PointsLog[]>
```

**返回值**:
```typescript
PointsLog[] // 积分记录数组
```

**示例**:
```javascript
const logs = await window.plugins.store.getPointsHistory();
console.log('积分历史:', JSON.parse(logs));
```

**返回数据结构**:
```json
[
  {
    "id": "1731473170789",
    "type": "获得",
    "value": 10,
    "reason": "完成签到奖励",
    "timestamp": "2025-01-15T08:30:00.000Z"
  },
  {
    "id": "1731473170790",
    "type": "消耗",
    "value": 50,
    "reason": "兑换商品: 免作业卡",
    "timestamp": "2025-01-15T10:15:00.000Z"
  }
]
```

---

### 用户物品

#### 11. getUserItems
获取用户物品列表

**签名**:
```javascript
async getUserItems(): Promise<UserItem[]>
```

**返回值**:
```typescript
UserItem[] // 用户物品数组
```

**示例**:
```javascript
const items = await window.plugins.store.getUserItems();
console.log('我的物品:', JSON.parse(items));
```

---

#### 12. useItem
使用物品

**签名**:
```javascript
async useItem(itemId: string): Promise<UseItemResult>
```

**参数**:
- `itemId`: 物品 ID

**返回值**:
```typescript
{
  success: boolean,
  message: string
}
```

**示例**:
```javascript
const result = await window.plugins.store.useItem('1731473170456');
const data = JSON.parse(result);
if (data.success) {
  console.log('使用成功');
} else {
  console.log('使用失败:', data.message);
}
```

**注意**:
- 使用后剩余次数减 1
- 次数归零后物品自动移除
- 过期物品无法使用

---

### 归档管理

#### 13. archiveProduct
归档商品

**签名**:
```javascript
async archiveProduct(productId: string): Promise<boolean>
```

**参数**:
- `productId`: 商品 ID

**返回值**:
```typescript
boolean // 总是返回 true
```

**示例**:
```javascript
await window.plugins.store.archiveProduct('1731473170123');
console.log('商品已归档');
```

---

#### 14. restoreProduct
恢复归档商品

**签名**:
```javascript
async restoreProduct(productId: string): Promise<boolean>
```

**参数**:
- `productId`: 归档商品 ID

**返回值**:
```typescript
boolean // 总是返回 true
```

**异常**:
- 归档商品不存在时抛出异常

**示例**:
```javascript
await window.plugins.store.restoreProduct('1731473170123');
console.log('商品已恢复');
```

---

#### 15. getArchivedProducts
获取归档商品列表

**签名**:
```javascript
async getArchivedProducts(): Promise<Product[]>
```

**返回值**:
```typescript
Product[] // 归档商品数组
```

**示例**:
```javascript
const archived = await window.plugins.store.getArchivedProducts();
console.log('归档商品:', JSON.parse(archived));
```

---

## 完整使用示例

### 示例 1: 商品管理流程

```javascript
// 1. 创建商品
const product = await window.plugins.store.createProduct(
  '迟到豁免卡',
  '可豁免一次迟到',
  30,
  20,
  '2025-01-01T00:00:00.000Z',
  '2025-12-31T23:59:59.999Z',
  60
);
const productData = JSON.parse(product);
console.log('商品已创建:', productData);

// 2. 获取所有商品
const products = await window.plugins.store.getProducts();
console.log('商品列表:', JSON.parse(products));

// 3. 更新商品
const updated = await window.plugins.store.updateProduct(
  productData.id,
  '迟到豁免卡（升级版）',
  '可豁免两次迟到',
  50,
  15,
  '2025-01-01T00:00:00.000Z',
  '2025-12-31T23:59:59.999Z',
  90
);
console.log('商品已更新:', JSON.parse(updated));

// 4. 归档商品
await window.plugins.store.archiveProduct(productData.id);
console.log('商品已归档');

// 5. 恢复商品
await window.plugins.store.restoreProduct(productData.id);
console.log('商品已恢复');
```

---

### 示例 2: 积分与兑换流程

```javascript
// 1. 查看当前积分
let points = await window.plugins.store.getPoints();
console.log('当前积分:', points);

// 2. 增加积分
const addResult = await window.plugins.store.addPoints(100, '完成每日任务');
console.log('增加积分:', JSON.parse(addResult));

// 3. 获取商品列表
const products = await window.plugins.store.getProducts();
const productList = JSON.parse(products);
const firstProduct = productList[0];

// 4. 兑换商品
const redeemResult = await window.plugins.store.redeem(firstProduct.id);
const redeemData = JSON.parse(redeemResult);
if (redeemData.success) {
  console.log('兑换成功！剩余积分:', redeemData.currentPoints);

  // 5. 查看我的物品
  const items = await window.plugins.store.getUserItems();
  console.log('我的物品:', JSON.parse(items));

  // 6. 使用物品
  const itemList = JSON.parse(items);
  const useResult = await window.plugins.store.useItem(itemList[0].id);
  console.log('使用结果:', JSON.parse(useResult));
} else {
  console.log('兑换失败:', redeemData.message);
}

// 7. 查看积分历史
const history = await window.plugins.store.getPointsHistory();
console.log('积分历史:', JSON.parse(history));
```

---

### 示例 3: 自动化积分管理

```javascript
// ���期检查过期物品
async function checkExpiredItems() {
  const items = await window.plugins.store.getUserItems();
  const itemList = JSON.parse(items);
  const now = new Date();

  itemList.forEach(item => {
    const expireDate = new Date(item.expire_date);
    const daysLeft = Math.floor((expireDate - now) / (1000 * 60 * 60 * 24));

    if (daysLeft <= 7) {
      console.log(`警告: ${item.product_snapshot.name} 还有 ${daysLeft} 天过期`);
    }
  });
}

// 自动兑换最便宜的商品
async function redeemCheapest() {
  const products = await window.plugins.store.getProducts();
  const productList = JSON.parse(products);

  // 按价格排序
  productList.sort((a, b) => a.price - b.price);

  // 兑换第一个（最便宜的）
  if (productList.length > 0) {
    const result = await window.plugins.store.redeem(productList[0].id);
    console.log('自动兑换结果:', JSON.parse(result));
  }
}

// 执行
await checkExpiredItems();
await redeemCheapest();
```

---

## 错误处理

所有 API 调用都应该使用 try-catch 包裹：

```javascript
try {
  const product = await window.plugins.store.getProduct('invalid_id');
} catch (error) {
  console.error('API 调用失败:', error.message);
}
```

**常见异常**:
- `商品不存在: <productId>`
- `物品不存在: <itemId>`
- `归档商品不存在: <productId>`
- JSON 解析错误（网络问题或数据损坏）

---

## 数据类型定义

### Product
```typescript
interface Product {
  id: string;
  name: string;
  description: string;
  image: string;
  stock: number;
  price: number;
  exchange_start: string; // ISO 8601
  exchange_end: string;   // ISO 8601
  use_duration: number;   // 天数
}
```

### UserItem
```typescript
interface UserItem {
  id: string;
  product_id: string;
  remaining: number;
  expire_date: string;    // ISO 8601
  purchase_date: string;  // ISO 8601
  purchase_price: number;
  product_snapshot: Product;
}
```

### PointsLog
```typescript
interface PointsLog {
  id: string;
  type: '获得' | '消耗';
  value: number;
  reason: string;
  timestamp: string;      // ISO 8601
}
```

---

## 性能建议

1. **批量操作**: 避免在循环中频繁调用 API，建议先获取列表再处理
2. **缓存结果**: 商品列表等不常变动的数据可以缓存
3. **异步处理**: 使用 `Promise.all` 并行执行多个独立请求

```javascript
// ✅ 推荐
const [products, points, items] = await Promise.all([
  window.plugins.store.getProducts(),
  window.plugins.store.getPoints(),
  window.plugins.store.getUserItems()
]);

// ❌ 不推荐
const products = await window.plugins.store.getProducts();
const points = await window.plugins.store.getPoints();
const items = await window.plugins.store.getUserItems();
```

---

## 版本历史

- **v1.0.0** (2025-01-15): 初始版本，包含 14 个 API

---

**相关文档**:
- [Store 插件模块文档](CLAUDE.md)
- [Chat 插件 JS API 文档](../chat/JS_API.md)

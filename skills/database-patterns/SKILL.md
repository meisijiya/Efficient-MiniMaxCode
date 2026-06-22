---
name: database-patterns
description: "数据库设计、迁移、查询优化、ORM 模式（PostgreSQL 为主，含 MySQL / SQL 通用知识）。触发词：database, db, sql, postgres, mysql, migration, 索引, 事务, orm"
---

# 数据库核心模式

> 适用：关系型数据库（PostgreSQL 优先），含 ORM 通用模式（SQLAlchemy / Prisma / Drizzle / JPA）。

## 4 原则提醒（落地版）

- **Think First**：先想清事务边界、隔离级别、一致性要求
- **Simplicity**：先 denormalize 到合理程度；过早优化是万恶之源
- **Surgical**：改 schema 不"顺手"改业务；migration 不能跨多个"不相关"变更
- **Goal-Driven**：每个 schema 变更先写"如果失败怎么回滚"

---

## 1. Schema 设计原则

### 主键
```sql
-- ✅ UUID v7 或 bigserial（看规模）
CREATE TABLE users (
    id BIGSERIAL PRIMARY KEY,
    -- 或
    id UUID PRIMARY KEY DEFAULT gen_random_uuid()
);

-- ❌ 业务字段当主键
-- email 变了整个 FK 链全要改
```

### 时间戳（**永远带**）
```sql
CREATE TABLE users (
    id BIGSERIAL PRIMARY KEY,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

### 软删除（看场景）
```sql
-- 业务表通常用 deleted_at 而不是真删
ALTER TABLE users ADD COLUMN deleted_at TIMESTAMPTZ;
-- 查询总是：WHERE deleted_at IS NULL
-- 索引：CREATE INDEX ON users (deleted_at) WHERE deleted_at IS NULL;
```

### 钱
```sql
-- ✅ 用整数（cents）不用浮点
amount_cents BIGINT NOT NULL
currency CHAR(3) NOT NULL DEFAULT 'USD'

-- ❌ 浮点
amount DECIMAL(10, 2)  -- 也行但要小心精度
amount FLOAT            -- ❌
```

### 枚举
```sql
-- ✅ PostgreSQL ENUM
CREATE TYPE user_status AS ENUM ('active', 'suspended', 'deleted');
CREATE TABLE users (..., status user_status NOT NULL DEFAULT 'active');

-- ✅ 或 look-up 表（更灵活）
CREATE TABLE user_statuses (id SMALLINT PRIMARY KEY, code TEXT UNIQUE);
```

---

## 2. 索引

### 何时加
- WHERE 频繁过滤
- JOIN 频繁用到的列
- ORDER BY 频繁的列

### 何时不加
- 基数极低（如 boolean）
- 表很小（< 1000 行）
- 写多读少

### 复合索引顺序（**关键**）
```sql
-- ✅ 命中：WHERE user_id = X AND created_at > Y
CREATE INDEX idx_orders_user_created ON orders (user_id, created_at);

-- ❌ 反序：created_at 在前就命中不了
CREATE INDEX idx_orders_created_user ON orders (created_at, user_id);
```

**规则**：等值列在前，范围列在后。

### 部分索引
```sql
-- ✅ 只索引"活的"
CREATE INDEX idx_users_active_email ON users (email) WHERE deleted_at IS NULL;
```

### 覆盖索引
```sql
-- ✅ 索引包含所有 SELECT 列，避免回表
CREATE INDEX idx_orders_user_total ON orders (user_id) INCLUDE (total_cents);
```

### 解释
```sql
EXPLAIN ANALYZE SELECT * FROM orders WHERE user_id = 42;
-- 看 Seq Scan vs Index Scan
-- 看实际行数 vs 估算行数
```

---

## 3. 迁移（Migrations）

### 规则
- **永远向前 + 向后两个 migration**（"up" 和 "down"）
- **一次 migration 一个变更**（不要"顺便加索引"）
- **生产数据** → 拆成多步：先加列（nullable）→ 写数据 → 加约束 → 加索引
- **重命名 / 删除列** → 多步部署（先 add 新列 + 双写 → 切读 → 删旧列）
- **大表加索引** → `CONCURRENTLY`（PostgreSQL 不锁表）

```sql
-- ✅ 不锁表加索引
CREATE INDEX CONCURRENTLY idx_orders_user ON orders (user_id);

-- ❌ 直接加（生产大表会锁几分钟）
CREATE INDEX idx_orders_user ON orders (user_id);
```

### Prisma / Drizzle 模式
```ts
// ✅ Prisma migration 文件
model Order {
  id        String   @id @default(uuid())
  userId    String
  total     Int
  createdAt DateTime @default(now())

  @@index([userId, createdAt])  // 显式声明
}
```

---

## 4. 查询优化

### N+1 防护
```python
# ❌ N+1
users = db.query(User).all()
for u in users:
    print(u.posts)  # 每次都查一次

# ✅ 预加载
users = db.query(User).options(selectinload(User.posts)).all()

# ✅ 或聚合查询
db.query(User, func.count(Post.id)).join(Post).group_by(User.id).all()
```

```ts
// Prisma 同样
const users = await prisma.user.findMany({ include: { posts: true } });
```

### 限制返回
```sql
-- ✅ 永远 LIMIT
SELECT * FROM users ORDER BY created_at DESC LIMIT 20 OFFSET 0;

-- ❌ SELECT * 在大表
SELECT * FROM users;  -- 返回几百万行
```

### 分页（**cursor 优于 offset**）
```sql
-- ✅ Cursor（稳定、快速）
SELECT * FROM orders
WHERE created_at < $1  -- 上次最后一条的时间
ORDER BY created_at DESC
LIMIT 20;

-- ❌ Offset 大翻页（慢）
SELECT * FROM orders ORDER BY id LIMIT 20 OFFSET 100000;
```

### 避免函数包裹索引列
```sql
-- ❌ 索引失效
WHERE LOWER(email) = 'a@b.com'

-- ✅ 函数索引
CREATE INDEX idx_users_email_lower ON users (LOWER(email));
WHERE LOWER(email) = 'a@b.com'

-- ✅ 或查询改写
WHERE email = 'A@B.com'  -- 看 collation
```

---

## 5. 事务

### 隔离级别
| 级别 | 现象 | 何时用 |
|------|------|--------|
| READ COMMITTED（默认 PG） | 不可重复读 | 大多数 OLTP |
| REPEATABLE READ | 幻读 | 报表 / 一致读 |
| SERIALIZABLE | 完全串行 | 强一致业务（库存） |

### Spring @Transactional（**注意边界**）
```java
@Transactional  // service 层，不是 controller
public void placeOrder(OrderRequest req) {
    var order = orderRepo.save(new Order(req));
    inventoryRepo.decrement(req.productId, req.qty);
    paymentClient.charge(req.paymentId, order.total);
    // 任一抛异常 → 全部回滚
}
```

### 规则
- **事务方法不要调外部 HTTP / 消息**（持锁太久）
- **不要在事务里做"业务判断 + 用户确认"两步**（要先 commit 再通知）
- **乐观锁** 用 `@Version`：
  ```java
  @Version
  private Long version;
  ```

---

## 6. 数据完整性

### FK 约束（**永远显式声明**）
```sql
CREATE TABLE orders (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE RESTRICT
);
```

### CHECK 约束
```sql
CREATE TABLE products (
    price_cents INTEGER NOT NULL CHECK (price_cents >= 0),
    stock INTEGER NOT NULL CHECK (stock >= 0)
);
```

### UNIQUE 约束
```sql
CREATE TABLE users (
    email TEXT NOT NULL UNIQUE
);
-- 复合
CREATE TABLE memberships (
    user_id BIGINT,
    org_id BIGINT,
    UNIQUE (user_id, org_id)
);
```

---

## 7. ORM 通用模式

### 模型与 schema 分开
- **不要**让 ORM 模型同时是 API 模型
- 业务模型 → ORM 模型 → API DTO 三层分离

### 事务边界显式
```python
# SQLAlchemy 2.0
with session.begin():
    order = Order(...)
    session.add(order)
    inventory.decrement(...)
# 自动 commit 或 rollback
```

### 避免 ORM 陷阱
```python
# ❌ 隐式 N+1
for user in users:
    user.last_order.total  # 每次都查

# ✅ 显式加载
users = session.execute(
    select(User).options(selectinload(User.last_order))
).scalars().all()
```

```ts
// ❌ Prisma raw
await prisma.$queryRaw`SELECT * FROM users WHERE email = ${email}`;
// 参数化 OK，但 result 类型是 unknown
```

---

## 8. 备份与恢复（**常识**）

- 至少 **每日全量 + 增量 WAL**
- 定期 **演练恢复**（不演练等于没备份）
- 关键操作（删表 / 批量改）前**手动 snapshot**

---

## 9. 监控

- **慢查询日志** → `log_min_duration_statement = 500`（500ms 以上记录）
- **`pg_stat_statements`** 扩展 → 看哪些 query 最耗时
- **连接数** → 不要打到 max
- **死锁检测** → `log_lock_waits = on`

---

## 10. 高频反模式（自查清单）

- [ ] 没用浮点存钱
- [ ] 表都有 `created_at` / `updated_at`
- [ ] FK 都显式声明
- [ ] 大表加索引用 CONCURRENTLY
- [ ] N+1 用 selectinload / JOIN FETCH
- [ ] 事务不在 controller 也不调外部 HTTP
- [ ] migration 是 forward + backward 一对
- [ ] 查询有 LIMIT
- [ ] 分页用 cursor 不用 offset
- [ ] 慢查询监控开了

---
name: performance-analyzer
description: "性能分析专项 skill。覆盖：profiling、瓶颈定位、查询优化、缓存策略、并发模型。**先测量后优化**。触发词：performance, 性能, 慢, profile, latency, 优化, 调优"
---

# Performance Analyzer — 性能分析专项

> 单职责：**定位 + 解决性能问题**。**先测量后优化**——没 profile 的优化是猜。

## 触发场景

- 用户报"XX 慢"
- p95 / p99 超标
- 数据库查询慢
- 接口响应慢
- 内存占用高
- CPU 飙高
- 启动慢

**不适用**：纯加新功能（那是 coder）。

## 4 原则

1. **Think First**：先问"慢在哪一层"——前端？网络？应用？DB？缓存？
2. **Simplicity**：先改最便宜的优化（加索引 > 改架构）
3. **Surgical**：只改瓶颈处，**不顺手重构**
4. **Goal-Driven**：每个优化要"可测量"——前后对比 p95/throughput

## 黄金法则（**最重要**）

> **"Premature optimization is the root of all evil."** — Donald Knuth
>
> **"Without data, optimization is just guessing."** — 性能圈共识

### 优化前必问 3 问

1. **真的慢吗？** —— 有 metric 吗？p95 / p99 / throughput？
2. **慢在哪？** —— profile 了吗？火焰图 / EXPLAIN / 慢查询日志？
3. **值得优化吗？** —— 这个慢点影响多少用户 / 多少请求？

**任一答不出** → 先做测量，**别动手优化**。

## 5 步性能分析法

### Step 1 — 量化问题
- **什么慢？** —— 接口、查询、页面、批处理？
- **多慢？** —— 当前 p50 / p95 / p99 / max
- **目标多快？** —— 业务 SLA 是什么
- **影响多大？** —— 多少用户 / 多少请求

```python
# 测 p95
import time
import statistics

durations = []
for _ in range(1000):
    start = time.perf_counter()
    handler(req)
    durations.append(time.perf_counter() - start)

p50 = statistics.median(durations)
p95 = statistics.quantiles(durations, n=20)[18]
p99 = statistics.quantiles(durations, n=100)[98]
print(f"p50={p50*1000:.1f}ms p95={p95*1000:.1f}ms p99={p99*1000:.1f}ms")
```

### Step 2 — 定位瓶颈
**自顶向下**：
1. **应用层** —— profile（CPU / 内存）
2. **DB 层** —— 慢查询 / EXPLAIN
3. **网络 / IO** —— 系统调用 / 外部 HTTP
4. **前端** —— 渲染 / 资源加载

### Step 3 — 找根因
- N+1 查询
- 缺索引 / 索引失效
- 全表扫描
- 锁等待
- 同步阻塞
- 内存泄漏
- 缓存未命中

### Step 4 — 优化（按 ROI）
**最便宜的优化**先做：
1. 加索引（5 分钟，10-100x 提升）
2. 修 N+1（1 小时，5-50x 提升）
3. 加缓存（1 天，10-100x 提升）
4. 改架构（1 周，2-10x 提升）

### Step 5 — 验证
- **跑同一个 benchmark**
- 对比前后 p50/p95/p99/throughput
- 没改善 → 回滚

## 各层优化清单

### 数据库层（**80% 性能问题在这里**）

#### 1. 找慢查询
```sql
-- PostgreSQL
SELECT query, calls, mean_exec_time, total_exec_time
FROM pg_stat_statements
ORDER BY mean_exec_time DESC
LIMIT 20;
```

#### 2. EXPLAIN 看执行计划
```sql
EXPLAIN ANALYZE SELECT * FROM orders WHERE user_id = 42;
-- 看 Seq Scan（坏）vs Index Scan（好）
-- 看实际行数 vs 估算行数（差很多 → 统计信息过期，ANALYZE）
```

#### 3. 加索引
```sql
-- WHERE 频繁过滤的列
CREATE INDEX CONCURRENTLY idx_orders_user_id ON orders(user_id);

-- 复合索引（等值在前，范围在后）
CREATE INDEX CONCURRENTLY idx_orders_user_created ON orders(user_id, created_at);

-- 部分索引（只索引"活的"）
CREATE INDEX CONCURRENTLY idx_orders_active ON orders(user_id) WHERE status = 'active';
```

#### 4. 修 N+1
```python
# ❌ N+1
orders = db.query(Order).all()
for o in orders:
    print(o.user.name)  # 每个都查一次

# ✅ 预加载
orders = db.query(Order).options(selectinload(Order.user)).all()
```

```ts
// ❌ N+1
const orders = await prisma.order.findMany();
for (const o of orders) {
  console.log(o.user.name);  // 每个都查
}

// ✅ include
const orders = await prisma.order.findMany({ include: { user: true } });
```

```java
// ❌ N+1
@OneToMany private List<OrderItem> items;
// 遍历 items 时每次查

// ✅ JOIN FETCH
@Query("SELECT o FROM Order o JOIN FETCH o.items WHERE o.id = :id")
Optional<Order> findWithItems(@Param("id") Long id);
```

#### 5. 避免函数包裹索引列
```sql
-- ❌ 索引失效
WHERE LOWER(email) = 'a@b.com'

-- ✅ 函数索引
CREATE INDEX idx_email_lower ON users(LOWER(email));
```

### 应用层

#### 1. 缓存
```python
# Python: functools.lru_cache
from functools import lru_cache

@lru_cache(maxsize=1000)
def get_user_permissions(user_id: int) -> tuple[str, ...]:
    return db.query(...).all()
```

```ts
// TypeScript: Map-based cache
const cache = new Map<string, { value: any; expiry: number }>();

function cached<T>(key: string, ttl: number, fn: () => T): T {
  const hit = cache.get(key);
  if (hit && hit.expiry > Date.now()) return hit.value;
  const value = fn();
  cache.set(key, { value, expiry: Date.now() + ttl });
  return value;
}
```

```java
// Spring Boot: @Cacheable
@Cacheable("users")
public User findById(String id) { ... }
```

#### 2. 异步 / 并行
```python
# ❌ 串行
user = get_user(id)
orders = get_orders(id)
total = get_total(id)
# 300ms

# ✅ 并行
import asyncio
async def get_user_data(id):
    user, orders, total = await asyncio.gather(
        get_user_async(id), get_orders_async(id), get_total_async(id)
    )
# 100ms
```

```ts
// ❌ 串行
const user = await getUser(id);
const orders = await getOrders(id);

// ✅ 并行
const [user, orders] = await Promise.all([getUser(id), getOrders(id)]);
```

```java
// Java 21+ Virtual Threads（自动并行）
// 不用改代码，spring.threads.virtual.enabled=true
```

#### 3. 内存 / GC
- Java → `-Xmx` / GC log / jmap / jstack
- Python → `tracemalloc` / `objgraph`
- Node → `heapdump` / `clinic.js`

### 网络层

#### 1. HTTP 客户端
- 复用 HTTP client（不要每次 new）
- 用 keep-alive
- 设 timeout

```python
# ✅ 复用 session
import httpx

client = httpx.AsyncClient(timeout=10.0)

async def get_user(id: str):
    return await client.get(f"/users/{id}")
```

```ts
// ✅ 复用 agent
import { Agent } from "undici";
const agent = new Agent({ connections: 100 });
```

#### 2. 序列化
- JSON → 慢，换 MessagePack / Protobuf
- 字符串拼接 → 用 StringBuilder / f"" / 模板

### 前端层

#### 1. 资源加载
- 图片：WebP / 懒加载 / responsive
- JS：code split / dynamic import
- CSS：critical inline

#### 2. 渲染
- 避免 layout thrashing
- 用 CSS `transform` 不用 `top/left`
- 虚拟列表（长列表）
- React.memo / useMemo 适度

## Profiling 工具

### Python
```bash
# CPU profile
py-spy dump --pid 12345
py-spy record -o profile.svg -- python my_app.py

# 内存
python -m tracemalloc
```

### TypeScript
```bash
# CPU
node --prof app.js
node --prof-process isolate-*.log > processed.txt

# 内存
clinic.js doctor -- node app.js
```

### Java
```bash
# CPU / 内存
java -jar async-profiler.jar -e cpu -d 30 -f profile.html <pid>
jcmd <pid> GC.heap_dump /tmp/heap.hprof

# 火焰图
java -jar async-profiler.jar -e cpu -d 30 -f flame.html <pid>
```

## 自检清单（**优化前**）

- [ ] 量化了问题（p50/p95/p99）？
- [ ] profile 定位了瓶颈？
- [ ] 知道瓶颈在哪一层（DB / app / network）？
- [ ] 优化 ROI 评估了（便宜的先做）？
- [ ] 优化后跑同一个 benchmark 对比？
- [ ] 没引入新问题（缓存一致性 / 复杂度）？

## 红线

- **不要**没 profile 就优化
- **不要**改架构来"以防万一"——先用便宜的优化
- **不要**加缓存但不写失效逻辑
- **不要**异步化但忘了错误处理
- **不要**改业务逻辑来"顺便优化"
- **不要**过早优化（YAGNI）

## 跟 mavis 工作流的对接

- **coder** 写新功能 → 主动问"性能要求" → 不要默认优化
- **build-error-resolver** → 区分"慢"和"错"
- **code-reader** → 先读懂瓶颈在哪
- **planner** → 大优化任务先出 plan（加缓存 = 改数据流，要先 plan）

---

**怎么算"在工作"**：每个优化有"before vs after"的数字、没优化错地方（用便宜手段达到 80% 效果）、没引入新问题。

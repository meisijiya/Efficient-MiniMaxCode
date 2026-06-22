# Project Context — 项目领域语言表

> 来自 matt 的 `CONTEXT.md` 模式：项目级"ubiquitous language"（领域驱动设计 Eric Evans）。**让 agent 写代码用项目自己的术语**——不猜。

## 触发场景

- 新项目 / 接手老项目
- `mavis` 启动时检测到项目根有 `CONTEXT.md` → load
- `coder` / `spec-miner` / `planner` 写涉及业务逻辑的代码前
- 项目术语混乱（"订单 / 任务 / 工单"含义重叠）

**不适用**：
- 极小项目（< 100 行）—— 术语简单到不需要
- 纯技术项目（无业务领域）—— 只有"Order/Payment"等业务概念时才需要

## 核心问题（为什么需要）

**没 CONTEXT.md 时**：

```
用户：加个"任务"
agent：[猜] "任务" = "Order" or "Task" or "Job" or "Ticket"?
agent：写代码时一会儿用 Task，一会儿用 Order，一会儿用 Job
用户：这是同一个东西为啥三种叫法？
```

**有 CONTEXT.md 时**：

```
用户：加个"任务"
agent：[读 CONTEXT.md] 任务 = Order（业务订单，不混同 Job / Ticket）
agent：所有代码统一 Order，不混
用户：✅
```

**本质**：**节省 50% 的"术语澄清"往返**——尤其是长项目、复杂业务。

## 模板：CONTEXT.md

放在项目根 `CONTEXT.md`（与 `AGENTS.md` / `README.md` 同级）：

```markdown
# CONTEXT: [项目名]

> 项目领域语言表（ubiquitous language）。所有 agent / 开发必须使用本表术语。
> 最后更新：YYYY-MM-DD

## 1. 核心实体

| 术语 | 定义 | 不混同 | 例子 |
|------|------|--------|------|
| **Order** | 业务订单（客户下单） | ≠ Job（系统任务）/ ≠ Ticket（工单） | `Order(id, customerId, items)` |
| **OrderItem** | 订单中的单条商品 | ≠ LineItem / ≠ Product | `OrderItem(orderId, productId, qty)` |
| **Customer** | 客户（已注册） | ≠ User（系统用户） / ≠ Guest | `Customer(id, email, tier)` |
| **Payment** | 支付记录 | ≠ Transaction（事务） / ≠ Charge | `Payment(id, orderId, amountCents, status)` |

## 2. 业务流程术语

| 术语 | 含义 | 状态机 |
|------|------|--------|
| **Checkout** | 结算流程（cart → payment → order） | 单一动作 |
| **Fulfillment** | 履约（order → picked → packed → shipped） | 多状态 |
| **Refund** | 退款（基于已支付 order） | 仅对已支付 |

## 3. 状态

| 实体 | 状态 | 含义 |
|------|------|------|
| Order | pending → confirmed → shipped → delivered | 订单生命周期 |
| Order | cancelled | 任何阶段可取消 |
| Payment | pending → succeeded / failed | 支付结果 |
| Payment | refunded | 已退 |

## 4. 关键不变量（Invariants）

> 项目**必须**保持的规则。违反 = bug。

- 一个 Order 必须有 ≥ 1 个 OrderItem
- OrderItem 数量 > 0 才能 confirmed
- Payment 状态 = succeeded 才允许发货
- Refund 只能对 Payment.status = succeeded 触发

## 5. 关键术语反例

| ❌ 不要写 | ✅ 应该写 | 为什么 |
|----------|----------|--------|
| `User` 代表客户 | `Customer` | 系统 User 含 admin / staff / customer，含义不同 |
| `Job` 代表订单处理 | `OrderProcessor` | Job 是通用术语，混同 |
| `Transaction` 代表支付 | `Payment` | Transaction 是 DB 事务概念 |

## 6. 缩写

| 缩写 | 全称 | 例 |
|------|------|-----|
| SO | Sales Order | `soId` |
| PO | Purchase Order | `poId` |
| SKU | Stock Keeping Unit | `skuCode` |
| SLA | Service Level Agreement | `slaHours` |
```

## 工作流

### 1. 项目启动时（1 次）

1. 找到项目根（看 `pom.xml` / `package.json` / `pyproject.toml` 等）
2. 看 `CONTEXT.md` 是否存在
3. 如果**不存在** → **建议**用户创建（spec-miner 第一次 grill 时顺便问）
4. 如果**存在** → load（mavis 启动项目时自动读）

### 2. agent 写代码时（每次）

1. 写之前 → 查 CONTEXT.md 找对应术语
2. 写代码时 → **用 CONTEXT.md 里的术语**（不是同义词 / 翻译）
3. 写完之后 → 自检"我用的术语都在 CONTEXT.md 里吗"

### 3. 新术语出现时

- agent 发现"这个项目用 XX 概念但 CONTEXT.md 里没有"
- → 标 TODO + 加到 CONTEXT.md candidate list
- → meta-writer 提醒用户更新 CONTEXT.md

## 与 mavis 的关系

**mavis 启动时**：
1. 检测到项目根 → 读 `CONTEXT.md`（如有）
2. 告诉所有 agent："本项目用 CONTEXT.md 术语"
3. 找不到时建议创建

**`AGENTS.md`（如果存在）也要 load**——AGENTS.md 是项目级 agent 指令，CONTEXT.md 是项目级术语表。

## 实战：写订单创建代码

**有 CONTEXT.md**（项目用 Order / OrderItem / Customer）：

```java
// ✅ 用 CONTEXT.md 术语
public record CreateOrderRequest(
    @NotNull String customerId,
    @NotEmpty List<OrderItemRequest> items
) {}

public class Order {
    private final String id;
    private final String customerId;
    private final List<OrderItem> items;
    private final OrderStatus status;  // pending / confirmed / ...
    // ...
}
```

**没 CONTEXT.md**（agent 自由发挥）：

```java
// ❌ 术语混乱
public class Task {  // 用户说"任务" agent 用了 Task
    private String userId;  // 用户说"客户" agent 用了 User
    private List<Product> goods;  // OrderItem 变成了 Product
    private String status;  // status 含义不清
}
```

## 反模式

| 反模式 | 修正 |
|--------|------|
| "Order/Job/Ticket 都行" | CONTEXT.md 明确**唯一**术语 |
| 写英文但项目用中文（"订单"） | CONTEXT.md 用项目自己的语言（中文项目 → 中文术语） |
| CONTEXT.md 写得像 README（叙述性） | CONTEXT.md 写得像**字典**（条目化） |
| 永远不更新 CONTEXT.md | 新概念出现 → 必须更新 |
| 只 developer 看 | agent / AI / 新成员都看 |

## 跟其他 skill / agent 的关系

- **`spec-miner`**：grill 用户"实体叫什么" → 写 CONTEXT.md
- **`mavis`**：启动时 load → 所有 agent 共享
- **`coder`**：写代码前查 → 不用错术语
- **`meta-writer`**：术语变更 → 更新 CONTEXT.md + changelog
- **`grill-me`**：术语模糊时 grill 用户

## 维护规则

**什么时候更新**：
- 新概念 / 实体 / 流程出现
- 旧术语换了名
- 不变量变了
- 反例新增

**更新时**：
- `meta-writer` 提议 → 用户确认
- 标"最后更新：YYYY-MM-DD"
- 写 changelog（"v1.1 增加了 SO 缩写"）

## 红线

- ❌ 业务代码用 CONTEXT.md 之外的术语
- ❌ CONTEXT.md 长期不更新
- ❌ 把 CONTEXT.md 当 README 写（叙述性而非条目性）
- ❌ 不变量没记在 CONTEXT.md（导致 agent 不知道）
- ❌ 团队成员不知道有 CONTEXT.md

## 与 matt `CONTEXT.md` 模式对照

| matt 提的 | 我们做的 |
|----------|---------|
| 项目级 domain model | ✅ CONTEXT.md 模板 |
| 节省 verbosity | ✅ "节省 50% 术语澄清往返" |
| 持续更新 | ✅ 维护规则 |
| 命名一致 | ✅ "不混同" 列 |

**吸收度：100%** + 加 DDD 不变量 + 业务流程术语表。

## 一句话总结

> **CONTEXT.md = 项目术语表。放在项目根。mavis 启动时 load。agent 写代码用表内术语——不猜。**

# Context Engineering — 喂对信息

> 来自 addy `context-engineering`：**给 agent 正确的信息在正确的时间**。Context 不是越多越好——**是越对越好**。

## 触发场景

- agent 启动时（在 system prompt 之后）
- 写文档 / PR / ADR 时（哪些放进去 / 哪些不放）
- 任何"agent 输出了 1 个不对劲的答案" 想 debug 时（很可能是 context 问题）
- 选 MCP / 工具时（哪些暴露给 agent）

**不适用**：
- 写业务代码时（这是 coder / verifier 的事）
- 修改 agent prompt 时（改 prompt 不等于改 context）

## 核心原则

> **Context 是稀缺资源。** 每个 token 都有成本——**放对地方**比**放得多**重要。

| 原则 | 含义 |
|------|------|
| **进 context 的必须是当前任务需要的** | 不需要的不进 |
| **当前任务需要的必须进** | 缺了就错 |
| **冲突信息 = 灾难** | "X" 和 "not X" 同时存在 → agent 选错 |
| **过时信息 = 噪音** | 旧 API 路径混在新的里 → agent 用错 |
| **格式影响理解** | 一段散文字 vs 结构化清单 → 准确度差 30% |

## 5 大上下文类型（**必须分清**）

### 1. 系统上下文（每次启动都加载）

**包含**：agent prompt + 当前 skill + 当前 memory

**DO**：
- ✅ 简洁（< 10% context）
- ✅ 结构化（标题 / 列表 / 表格）
- ✅ 关键决策在前

**DON'T**：
- ❌ 长篇大论
- ❌ 重复冗余
- ❌ "以防万一" 的兜底

### 2. 任务上下文（任务相关）

**包含**：用户消息 + 文件 + 之前的对话

**DO**：
- ✅ 只给当前任务需要的文件（不"以防万一"附 50 个）
- ✅ 相关代码贴出来（不全贴，看相关函数）
- ✅ 关键错误信息（堆栈、错误码）

**DON'T**：
- ❌ 整个项目结构图（agent 用不上）
- ❌ 50 个文件 dump
- ❌ 之前所有对话历史

### 3. 领域知识上下文（行业 / 框架 / 业务）

**包含**：skill 内容 / 文档 / 行业惯例

**DO**：
- ✅ Load 相关 skill（不是全部）
- ✅ 引用官方文档的**关键段**（不是全文档）
- ✅ 业务术语表（CONTEXT.md）

**DON'T**：
- ❌ 把所有 skill 全部 load
- ❌ 复制 100 KB 文档到 context
- ❌ 假设 agent 知道你的业务术语

### 4. 工具 / 资源上下文（agent 能用什么）

**包含**：MCP / tools / API 列表

**DO**：
- ✅ 暴露 agent 当前任务真正需要的工具
- ✅ 工具描述清晰（一句话讲清做什么）
- ✅ 危险工具要明确标（HIGH RISK / DESTRUCTIVE）

**DON'T**：
- ❌ 暴露 50 个 tool 让 agent 选（over-choice paralysis）
- ❌ 暴露生产环境 tool 给 read-only 任务
- ❌ 不告诉 agent 工具的 cost / 副作用

### 5. 历史上下文（之前发生过什么）

**包含**：memory / past decisions / similar past work

**DO**：
- ✅ 引用相关 past decision（"上次我们决定 X 因为 Y"）
- ✅ 引用 user-level 偏好（"用户偏好 Spring Boot"）
- ✅ 引用 cross-session insights

**DON'T**：
- ❌ 复制整个 memory 库
- ❌ 提无关 past work（"3 个月前我们改过 X" —— 与当前任务无关）

## 进 context 的 4 道过滤（**每段都过**）

```
[一段信息]
   ↓
Q1: agent 当前任务会用到吗？
   ├─ 否 → 删
   └─ 是 ↓
Q2: agent 能从已有 context 推断出来吗？
   ├─ 是 → 删（除非是关键决策）
   └─ 否 ↓
Q3: 旧吗？和最新信息冲突吗？
   ├─ 冲突 → 只留最新 + 标 ⚠️ conflicting
   └─ 否 ↓
Q4: 表述清楚吗？还是 agent 容易误解？
   └─ 容易误解 → 重写 / 改格式（表格 / 代码 / 列表）
```

## 4 道坎：context 设计

### 1. **结构化 > 散文字**

| 散文字 | 结构化 |
|--------|--------|
| "我们应该用 P95 latency 作为指标。P95 是 95% 的请求。监控 5xx 错误。..." | ```\n| Metric | Target |\n|---|---|\n| P95 latency | < 200ms |\n| 5xx rate | < 0.1% |\n``` |

**为什么**：LLM 对结构化内容的理解准确度比散文字高 30%+。

### 2. **示例 > 规则**

| 规则 | 规则 + 示例 |
|------|------------|
| "错误处理要明确" | "错误处理要明确。例：throw new NotFoundException(`user ${id} not found`) 而非 return null" |

**为什么**：示例锚定理解，规则容易被"以我的理解"覆盖。

### 3. **负例 > 只说正例**

| 只说正例 | 正例 + 负例 |
|----------|-------------|
| "用 Optional 表示可空" | "✅ Optional<User> getUser(id)\n❌ User getUser(id) returns null" |

**为什么**：负例让 agent 知道"不要做什么"，正例容易只学"做什么"。

### 4. **限制比建议强**

| 建议 | 限制 |
|------|------|
| "考虑加 max length" | "❌ 禁止加 max length validation（这不是这个 PR 的范围）" |

**为什么**：建议 = 可选 = agent 容易做；限制 = 必避 = agent 知道"硬边界"。

## 实战：context 优化 checklist

**写文档 / PR / ADR 时**：
- [ ] 这段信息 agent 当前任务**会用到吗**？
- [ ] agent **能推断**出来吗？
- [ ] **最新**吗？有没有过时？
- [ ] **结构化**呈现？
- [ ] 给了**正例 + 负例**吗？
- [ ] 有没有**硬限制**（不是软建议）？

**debug "agent 输出不对劲"**：
- [ ] agent 看到的 context 是什么？
- [ ] 哪些是**冲突**的？
- [ ] 哪些是**过时**的？
- [ ] 哪些是 agent **用不上**但**占用**的？

## 与 addy `context-engineering` 对照

| addy 提的 | 我们做的 |
|----------|---------|
| Feed agents the right information at the right time | ✅ 5 类上下文分清 |
| Rules files | ✅ 进 context 之前 4 道过滤 |
| Context packing | ✅ 结构化 > 散文字 |
| MCP integrations | ✅ 工具 / 资源上下文（4 道坎） |

**吸收度：100%**。

## 跟其他 skill / agent 的关系

- **`grill-me`**：先 grill 用户（搞清需求）→ context-engineering 决定**怎么喂**给 agent
- **`vibecoding-discipline`**：5 实践可以精简成"5 行"，但应该留 1-2 个**反例**
- **`meta-writer`**：写 ADR 时，**必须用本 skill** 的结构化格式
- **所有 agent**：启动时**评估**自己的 context 是否够 / 是不是太多

## 红线

- ❌ 把整个文档 / 库文档塞进 context
- ❌ 散文字大段（不结构化）
- ❌ 冲突信息不标（agent 选哪个？）
- ❌ 过时 API / 旧版本特性不清理
- ❌ "以防万一"地塞一堆 agent 不会用的信息
- ❌ 暴露 50 个 tool 给简单任务（over-choice）

## 一句话总结

> **Context 是稀缺资源——给对不给多。结构化 > 散文字。示例 > 规则。每段都过 4 道过滤。**

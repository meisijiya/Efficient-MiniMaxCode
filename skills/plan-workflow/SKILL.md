---
name: plan-workflow
description: "/plan 工作流 — 触发 spec-miner → planner → coder 流水线。从模糊需求到可执行 plan 一气呵成。触发词：/plan, 计划, planning, 流水线, workflow"
---

# /plan Workflow — Spec → Plan → Build 流水线

> **借鉴 [ohMeisijiyaCode](https://github.com/meisijiya/ohMeisijiyaCode) 的 7 步循环 + Karpathy 原则 1 (Think Before Coding)**
> 用户说 "/plan XX" → 触发完整流水线。**复杂任务的标准入口**。

## 触发方式

```
/plan [需求描述]
```

例如：
- `/plan 给用户系统加 SSO 登录`
- `/plan 把订单导出 CSV 功能加上`
- `/plan 重构用户模块的依赖注入`
- `/plan 实现 webhook 重试机制`

## 流水线（**7 步循环的 Think + Plan 阶段**）

```
用户输入
   ↓
[1] spec-miner → Spec 文档
   ↓
[2] planner → Implementation Plan
   ↓
[3] 用户确认 Plan（mavis 等待）
   ↓
[4] coder → Build（按 plan 钻进模块）
   ↓
[5] verifier → Review（4 层置信度门）
   ↓
[6] test-writer → 补测试
   ↓
[7] meta-writer → 写决策到 KNOWLEDGE / ADR
```

## 何时用

**用**：
- 跨多文件的新功能
- 重构（结构性改动）
- 架构决策（选型 / 拆服务 / 改 schema）
- 模糊需求（用户只说"做 XX"）
- 关键 bug（影响多模块）

**不用**：
- typo / one-liner
- 单一文件的简单改动
- 用户已经给了详细方案

## 完整工作流

### Step 1 — Spec 阶段（spec-miner）

**目标**：把"模糊需求"转成"结构化 Spec"

**输入**：用户原始需求（一句话或多句话）

**输出**：`docs/specs/<feature-name>.md`，包含：
- 一句话目标
- 背景 / 为什么
- 用户与场景
- 功能需求（FR）
- **非目标（NG）**——明确不做的事
- 约束（性能 / 一致性 / 合规 / 技术栈）
- 验收标准（可测的）
- 开放问题（需用户决策）
- 假设（可一眼纠正）

**关键检查**：
- [ ] 非目标显式列了？（反 scope creep 核心）
- [ ] 验收标准都是"可测的"？
- [ ] 开放问题留给用户了？

### Step 2 — Plan 阶段（planner）

**目标**：把 Spec 转成"可执行 Plan"

**输入**：spec-miner 的 Spec 文档

**输出**：`docs/plans/<feature-name>.md`，包含：
- 概览 / 假设 / 需求（从 Spec 继承）
- 架构变更（模块边界、接口契约、数据流）
- 实施步骤（多 Phase，每个独立可 merge）
- 测试策略
- 风险与缓解
- 成功标准

**关键检查**：
- [ ] 模块边界画清楚了？
- [ ] 接口契约定义了（API 签名、数据结构）？
- [ ] 每个 Phase 独立可 merge？
- [ ] 没有"未来扩展"的过度设计？

### Step 3 — 用户确认（**强制**）

mavis **停下来等用户**：
> "Spec + Plan 已经写好（[链接]）。请确认：
> - [ ] 可以开始 Build？
> - [ ] 哪个 Phase 优先？
> - [ ] 有什么要调整的？"

**没有用户确认** → 不进 Build。

### Step 4 — Build 阶段（coder）

**目标**：按 Plan 钻进每个模块实现

**关键约束**（来自 Vibe Coding 防屎山）：
- **不重新做架构决策**（按 Plan 来）
- **5 条解耦实践**（接口、单一职责、组合、增量、纯函数）
- **每 Phase 跑通测试再下一个**
- **karpathy 4 原则全程生效**

**输出**：代码 + commit（每个 Phase 一个 commit）

### Step 5 — Review 阶段（verifier）

**目标**：结构化审查

**触发场景**（借鉴 ohMeisijiyaCode）：
- small（≤10 行）→ 只 reviewer
- feature → reviewer + architect
- project → reviewer + architect + auditor
- 关键决策 → auditor

**输出**：审查报告（4 层置信度门）

### Step 6 — Test 阶段（test-writer）

**目标**：补齐测试覆盖

**类型**：
- 边界（null / 空 / 极值 / 非法字符）
- 异常（每条 catch 路径）
- 集成（API 端到端）
- 结构性（import 方向、状态访问）

### Step 7 — Reflect 阶段（meta-writer）

**目标**：沉淀决策

**写到哪里**：
- 重要架构决策 → `docs/adr/<NNNN>-<decision>.md`
- 跨会话规则 → `docs/KNOWLEDGE.md`
- 时序决策日志 → `docs/DECISIONS.md`
- 项目里程碑 → `docs/M*-ROADMAP.md`

---

## 完整示例（虚构）

```
用户：/plan 给用户系统加 SSO 登录

mavis 触发 /plan workflow:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[1/7] spec-miner
   输出: docs/specs/sso-login.md
   - 一句话目标：用户能用 Google/GitHub 一键登录
   - 非目标：不做账号合并（先单一 provider 后多 provider）
   - 验收：能 Google 登录；登出后状态清理；session 24h 过期
   - 假设：用 OAuth 2.0（不是 SAML）
   - 开放问题：要不要支持多 provider 同时？

[2/7] planner
   输出: docs/plans/sso-login.md
   架构变更：
   - 新增 SsoProvider 接口
   - 新增 GoogleSsoProvider 实现
   - 新增 /auth/sso/{provider}/callback 端点
   - Session 表加 provider_id 字段
   
   Phase 1: 加 SsoProvider 接口 + 空实现（独立可 merge）
   Phase 2: Google OAuth 流程（auth URL + callback）
   Phase 3: Session 关联 + 登出清理
   Phase 4: rate limiting + audit log

[3/7] 用户确认
   mavis: "Plan 已就绪。Phase 1 先做？要不要加多 provider？"

[4/7] coder
   - Phase 1: 加接口 + 空实现
   - Phase 2: Google OAuth
   - Phase 3: Session 关联
   - Phase 4: 收尾

[5/7] verifier
   审查报告：1 个 HIGH（接口粒度可以更细）→ coder 重构 → 重审 → APPROVE

[6/7] test-writer
   补：单元 + 集成 + E2E（用户登录 Google → 跳转 → 落 session → 登出）

[7/7] meta-writer
   docs/adr/0001-sso-interface-design.md
   docs/DECISIONS.md +1 行

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

最终交付：
- Spec + Plan 文档
- 4 个 Phase commit（独立可回滚）
- 完整测试覆盖
- 决策记录
```

## 配置文件位置

| 阶段 | 输出位置 |
|------|----------|
| Spec | `docs/specs/<name>.md` |
| Plan | `docs/plans/<name>.md` |
| ADR | `docs/adr/NNNN-<name>.md` |
| KNOWLEDGE | `docs/KNOWLEDGE.md` |
| DECISIONS | `docs/DECISIONS.md` |

## 流水线速度 vs 质量权衡

| 任务 | 流水线 |
|------|--------|
| typo / one-liner | 跳过 /plan，直接 coder |
| 简单加方法 | coder（不调 /plan） |
| 跨文件功能 | /plan 跑完整 7 步 |
| 重构 | /plan + auditor 关键决策 |
| 大版本 | /plan + patriarch 战略层 |

## 跟 mavis 工作流的对接

- **mavis 收到 "/plan XX"** → 触发本 skill → 跑完整流水线
- **mavis 收到 "做 XX"（模糊）** → 自动判断 → 走 /plan
- **mavis 收到 "修 bug X"** → 简单直接 coder；复杂调 /plan

## 红线

- **不要**跳过 Spec 直接进 Plan（除非用户给了详细方案）
- **不要**Plan 没用户确认就 Build
- **不要**Build 阶段改架构（按 Plan 来）
- **不要**skip Review（4 层置信度门必跑）
- **不要**Reflect 阶段忘记写决策（不沉淀 = 浪费）

---

**怎么算"在工作"**：复杂任务跑完 7 步后用户能**清楚看到每一步的产物**（Spec → Plan → Code → Review → Test → Meta），不返工。

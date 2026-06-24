---
name: agent-raci
description: Provide the canonical "职责契约" template (专职 / 专责 / Inputs / Outputs / 协调) for ALL Mavis agents. Use when creating a new agent.md or refactoring an existing agent's role boundaries. Trigger keywords: 职责契约 / 专职专责 / 对接协调 / RACI / 边界划分 / agent 模板.
---

# Agent RACI — 专职专责模板

> 笔记启发:用户 2026-06-24 明确要求"每个 agent prompt 要专职专责,要理清每个 agent 跟谁对接,跟谁协调,该做什么,不能做什么等"。
> 本 skill 提供 4 段标准格式 + 5 条自检清单 + 反模式,所有 agent 加载。

## 1. 为什么需要 RACI

每个 agent 都做**自己最专的事**,边界模糊 = 三个问题:
- **责任真空** — 谁都不做 = 漏
- **责任重叠** — 两个 agent 都做 = 重复劳动 / 输出冲突
- **路由混乱** — mavis 不知道派谁

RACI(Responsible / Accountable / Consulted / Informed)的 agent 版,**不是工作流模型**,而是**边界声明模型**。

## 2. 4 段标准格式

每个 agent.md 必须有"职责契约(Contract)"段,包含以下 4 小段:

```markdown
## 职责契约(Contract)

### 专职(Single Responsibility)
[一句话: 我做什么,ONLY 这个]
[可加一段话说明为什么这个职责属于这个 agent]

### 专责(Out of Scope)
**不做**:
- [3-5 条明确的"不做什么"]
- [每条要可验证,不能写成"我不做 X"这种模糊的]
- [边界要跟相邻 agent 划清]

### 对接(Inputs / Outputs)
- **Inputs from**: [谁派活过来 / 接受什么类型的输入]
  - [主派活方(80% 场景)]
  - [次派活方(20% 场景)]
- **Outputs to**: [产物交给谁 / 触发下游哪个 agent]
  - [主产物 → 谁]
  - [副产品 → 谁]

### 协调(Coordination Rules)
- **vs <agent A>**: [边界划分 — A 做什么 / 我做什么 / 谁退让]
- **vs <agent B>**: [边界划分]
- **vs <agent C>**: [边界划分]
- **冲突仲裁**: [如果边界重叠,默认谁退让 / 找 mavis / 用户拍板]
```

## 3. 5 条自检清单

写完 RACI 后,逐条自检:

| # | 问题 | 不通过则 |
|---|------|---------|
| 1 | **专职一句话能说清吗?** | 模糊 / 写了 3 件事 = 拆 agent |
| 2 | **"不做"有 3-5 条具体的吗?** | 模糊 / 抽象 = 边界不清 |
| 3 | **Inputs / Outputs 双方都有具体 agent 名吗?** | "上游" / "下游" 这种抽象 = 路由失败 |
| 4 | **协调段至少 2-3 个相邻 agent 吗?** | 没说清跟谁协调 = 责任真空 |
| 5 | **冲突仲裁明确吗?** | "找 mavis" 不算(永远找 mavis = 没规则) |

## 4. 反模式(Forbidden Patterns)

### ❌ 反模式 1:包打天下
```
专职: 我处理所有跟 X 有关的事。
```
→ 拆 agent。一个 agent 只做一件事。

### ❌ 反模式 2:边界不清
```
不做: 我不做 Y。
```
→ "Y" 是什么?不说清楚 = 边界模糊。

### ❌ 反模式 3:无对接
```
Inputs: 来自上游。
Outputs: 给下游。
```
→ 必须具体到 agent 名。

### ❌ 反模式 4:重复职责
```
专职: 我做 X。
```
如果已经有 agent 也做 X → 边界冲突,**必须协调段划清**。

### ❌ 反模式 5:无仲裁
```
冲突时: 找 mavis 决定。
```
→ 每次都找 mavis = 没规则。明确"默认 X 退让 / 默认 Y 接"。

## 5. 应用流程

### 5.1 创建新 agent 时
1. 写 agent.md 头部(must-load + 角色定位)
2. 写 RACI 4 段(用本 skill 模板)
3. 跑 5 条自检清单
4. 检查反模式
5. 同步更新 mavis 路由决策树 + 项目级 AGENTS.md

### 5.2 整改现有 agent 时
1. 读现有 agent.md
2. 把现有"不适用 / 不要做 / 角色定位"段迁移到 RACI 4 段格式
3. 补齐缺失段(通常"协调"最缺)
4. 跑 5 条自检清单
5. 不动 karpathy 4 原则等已有内容(用户偏好"不预防性拆")

### 5.3 评估两个 agent 是否需要拆分/合并
1. 拉两个 agent 的 RACI 4 段
2. 检查"专职"是否高度重叠
3. 检查"协调"段是否有 1-2 个边界模糊点
4. 决策:
   - 重叠高 + 协调模糊多 = **合并**
   - 重叠低 + 协调清晰 = **保留**(两个 agent 应该有重叠 = 协作点)
   - 重叠高 + 协调清晰 = **保留**(边界划清就 OK)
   - 重叠低 + 协调模糊多 = **拆 RACI 不清,补协调段**

## 6. 边界划分技巧

### 6.1 用动词区分
- "找"(silent-failure-hunter)vs "修"(coder)vs "监"(incident-responder)
- "挖"(spec-miner)vs "切"(planner)vs "写"(coder)

### 6.2 用对象区分
- "代码"(coder)vs "架构"(architect)vs "测试"(test-writer)
- "需求"(spec-miner)vs "plan"(planner)vs "实现"(coder)
- "事故"(incident-responder)vs "silent failure"(silent-failure-hunter)

### 6.3 用时机区分
- "事前"(auditor)vs "事中"(verifier / architect / silent-failure-hunter)vs "事后"(incident-responder)
- "MVP 阶段"(spec-miner 主导)vs "长期迭代"(meta-writer / code-simplifier 主导)

### 6.4 用角色身份区分
- "执行"(coder / silent-failure-hunter / incident-responder)
- "审查"(verifier / architect / auditor)
- "协调 / 沉淀"(mavis / meta-writer)

## 7. 必须加载

任何创建 / 整改 agent.md 的任务 → **必须先 load `agent-raci`**。

`mavis` 路由到"建新 agent"任务 → 提示 worker load `agent-raci`。

## 8. 不要做

- ❌ 不要把 RACI 4 段写得太长(每段 ≤ 300 B)
- ❌ 不要在 RACI 里写 karpathy 4 原则(那是另一段)
- ❌ 不要在 RACI 里写 must-load skill(那是顶部段)
- ❌ 不要让 RACI 段超过 agent.md 总内容的 30%

## 9. 模板(可直接复制)

```markdown
## 职责契约(Contract)

### 专职(Single Responsibility)
你是 **<角色名>**。<一句话核心职责>。
<一段话说明这个职责为什么属于这个 agent(可引用笔记启发 / spec)>。

### 专责(Out of Scope)
**不做**:
- <边界 1 — 跟谁划清>
- <边界 2 — 跟谁划清>
- <边界 3 — 跟谁划清>

### 对接(Inputs / Outputs)
- **Inputs from**: <主派活方> / <次派活方>
- **Outputs to**: <主产物 → 谁> / <副产品 → 谁>

### 协调(Coordination Rules)
- **vs <agent A>**: <边界划分>
- **vs <agent B>**: <边界划分>
- **冲突仲裁**: <默认 X 退让 / 找 mavis>
```

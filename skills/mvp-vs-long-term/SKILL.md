---
name: mvp-vs-long-term
description: Different spec density at MVP vs long-term iteration phases. MVP = Project Charter only (what / what NOT). Long-term = Spec + Harness double lock. Trigger keywords: MVP / charter / 宪章 / 长期迭代 / spec density / 收紧 / 项目边界 / scope creep.
---

# MVP vs Long-term — 阶段化 Spec 密度

> 笔记启发 3(MVP 阶段只写 Project Charter;后期才收紧 spec)。
> 适用:spec-miner / mavis / 任何 spec 相关的 agent。

## 1. 为什么分阶段

AI 编程最常见的反模式:
- **MVP 阶段过度规划** → 写大量 spec → 限制模型能力 → 产品奇怪
- **长期迭代不沉淀** → spec 散落 → context 涣散 → 项目烂尾

正确的节奏:
```
MVP 之前:松(只写 charter,放 AI 自由发挥)
  ↓ MVP 验收
MVP 之后:一轮一轮收紧(沉淀 spec + harness)
  ↓ 长期迭代
长期:spec + harness 双锁 + context reset SOP
```

## 2. MVP 阶段(0→1)

### 2.1 原则:**只写 Project Charter**

放 AI 自由发挥,只设**最粗的边界**。理由:
- 早期决定还在变,过度 spec = 给未来枷锁
- 不知道用户真正想要什么,详细 spec = 闭门造车
- 模型在松约束下表现更好

### 2.2 Project Charter 内容(只两件事)

```markdown
# Project Charter: <产品名>

## 这个产品是什么(正向边界)
<一段话,产品做什么 / 解决什么问题>

## 这个产品不是什么(反向边界)
**不是**:
- <不做 1>
- <不做 2>
- <不做 3>
```

**关键**:**反向边界比正向边界更重要**。
- 防止 scope creep(用户野心 + AI 配合 = 越做越大)
- 防止"什么都想做"的个人开发者陷阱

### 2.3 MVP 阶段不写其他 spec

- ❌ 不写详细架构 spec
- ❌ 不写 API spec
- ❌ 不写数据库 schema spec
- ❌ 不写模块划分 spec

**但注意**:不写 spec ≠ 不产生 spec。AI 帮你搭 MVP 时,它在替你做决定:
- 文件怎么组织
- 命名怎么取
- 状态怎么流动

**MVP 项目本身就是一份用代码写出来的 spec 草稿**——你审批它就行。

### 2.4 Charter 放哪

- 写到 `AGENTS.md` 顶部(项目级,所有 agent 都能看)
- 写到 `README.md` 顶部(用户级)

## 3. MVP 之后(过渡期)

### 3.1 触发:"我决定这个东西值得继续"

MVP 跑通,验收通过,你**主观决定**继续做。
这是开始写 spec 的信号。

### 3.2 立刻做的事:重构打地基

MVP 代码是"东拼西凑"的(AI 多人协作 / 自主决策 / 修复开发),必须**立刻重构**:

1. **新开对话**(避免上下文污染)
2. AI 审查 MVP 架构
3. 重构为模块化 / 解耦
4. 实际演示验收(MVP 阶段所有功能无异常)

**为什么立刻重构**:
- MVP 体量不大,重构可控
- 等到乱成一团再重构 = 不可逆灾难
- 重构后的"地基"决定后续 spec 怎么写

### 3.3 沉淀第一波 Spec

重构完成后,**第一次**大量写 spec:
- 模块边界 / 接口契约 → Spec
- 核心业务逻辑 → Spec + Harness
- 不再变的方向 → Spec(写到 ADR / DECISIONS)

## 4. 长期迭代(收紧阶段)

### 4.1 一轮一轮收紧

```
每一轮迭代:
  1. 发现原则性纠正(AI 反复犯的错误)
  2. 自问:"还会再发生吗?"
  3. 是 → 沉淀为 Spec
  4. 核心业务 → 配 Harness
  5. 下一轮迭代
```

### 4.2 Spec 沉淀机制

| 沉淀位置 | 适合 |
|---------|------|
| `AGENTS.md` | 项目级核心 spec(项目边界 / 通用约束) |
| `docs/SPEC-<name>.md` | 单一功能的 spec |
| `docs/ADR-NNN-<decision>.md` | 架构决策类 spec |
| `topic files` | 跨项目的稳定 spec |
| `code comments` | 实现细节级 spec |

### 4.3 Harness 配 vs 不配

| Spec 类型 | 配 Harness? |
|-----------|------------|
| 核心业务边界 | ✅ |
| 架构决策(改起来成本高) | ✅ |
| 一般业务规则(可改) | ❌ |
| UI 细节(经常变) | ❌ |

## 5. 阶段判断清单

| 阶段 | 信号 | 写 spec 密度 |
|------|------|------------|
| **MVP 0→1** | 项目刚启动 / 想法验证期 | 只写 Charter |
| **MVP 之后** | MVP 验收通过 / 决定继续 | 重构 + 第一波 spec |
| **长期迭代** | 项目已上线 / 多次迭代 / 多人协作 | 持续收紧 spec + Harness |

## 6. 反模式

### ❌ 反模式 1:MVP 阶段写大量 spec
```
"项目刚启动,我先写 50 条 spec 把架构定下来"
```
→ 早期决定还会变。**只写 Charter**。

### ❌ 反模式 2:MVP 之后不收紧
```
"MVP 跑通了,继续加功能,spec 等以后再写"
```
→ 后期 context 涣散 = 项目烂尾。**MVP 之后立刻收紧**。

### ❌ 反模式 3:Charter 写"做不到的事"
```markdown
## 这个产品是什么
- 高性能
- 简单易用
- 安全可靠
- 支持所有平台
```
→ Charter 写**具体的产品**,不写形容词。

### ❌ 反模式 4:反向边界写"还做不到的事"
```markdown
## 这个产品不是什么
- 不能太慢(做不到)
```
→ 反向边界写"选择不做",不写"做不到"。

## 7. 不要做

- ❌ 不要在 MVP 阶段写详细 spec
- ❌ 不要在长期迭代阶段不收紧
- ❌ 不要 Charter 写成"产品愿景"(要写"产品边界")
- ❌ 不要 MVP 跑通后不重构(直接加功能 = 烂尾种子)

## 8. 与其他 skill 的关系

- **`spec-vs-harness`**:本 skill 是 spec-vs-harness 的**阶段化调度**
- **`spec-miner` agent**:MVP 阶段不调 spec-miner(直接 mavis 出 Charter);MVP 之后调 spec-miner 出 Spec
- **`meta-writer` agent**:长期迭代阶段,所有 spec 沉淀由 meta-writer 写
- **`hard-constraints`**:Charter 必须用硬词("禁止 X / 必须 Y")

## 9. 模板(可直接复制)

### Project Charter 模板(MVP 阶段)

```markdown
# Project Charter: <产品名>

## 这个产品是什么
<一段话,具体说明产品做什么 / 解决什么问题>

## 这个产品不是什么
**不是**:
- <不做 1>
- <不做 2>
- <不做 3>
```

### 阶段过渡清单

```markdown
## MVP 验收通过 → 长期迭代过渡清单

- [ ] 重构打地基(模块化 / 解耦)
- [ ] 第一波 Spec 沉淀(模块边界 / 接口契约)
- [ ] 核心业务配 Harness
- [ ] 更新 Charter(基于 MVP 实际产物)
- [ ] 启动 spec 生长机制(每轮迭代沉淀)
```

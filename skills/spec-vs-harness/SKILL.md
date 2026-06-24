---
name: spec-vs-harness
description: Distinguish Spec (drawing) vs Harness (workshop). Spec = natural-language contract, Harness = executable test that locks the spec. Spec grows from repeated principle corrections. Trigger keywords: spec / harness / 规格 / 测试 / 决定 / spec 生长 / 契约 / 锁住 / single source of truth.
---

# Spec vs Harness — 规格与测试的二分

> 笔记启发 2(Spec = "已经想清楚、不再决定第二次的事")+ 启发 4(Harness = 把信任外包给测试,不是抓 bug)。
> 适用:coder / meta-writer / spec-miner。

## 1. 为什么需要区分

混淆 Spec 和 Harness = 两个问题:
- **Spec 写得太多**:把想象当决定,后期打脸
- **Harness 写得太多**:覆盖率 KPI 化,跟核心业务脱钩

正确的二分:
- **Spec** = 你和 AI 之间的契约(自然语言)
- **Harness** = AI 不能违反的边界(可执行测试)

## 2. Spec 本体论

### 2.1 定义

**Spec = 你已经想清楚、并且以后不再做第二次决定的那些事**。

不是文档,是"决定"。写 Spec 是**锁定决定**,不是"提前规划"。

### 2.2 写 Spec 的两个触发条件(必须同时满足)

| # | 条件 | 不满足则 |
|---|------|---------|
| 1 | 这个决定已经深思熟虑过 | 不写(还在变) |
| 2 | 这个决定还会再发生 / 反复影响 | 不写(一次性) |

### 2.3 Spec 生长机制(不要预防性写)

```
跟 AI 协作
  ↓
出现原则性纠正(不是一次性 bug,是"以后还会犯"的)
  ↓
自问:"这件事还会再发生吗?"
  ↓
是 → 沉淀为 Spec(写到 AGENTS.md 或 topic file)
否 → 不写(放 PR review 即可)
```

**关键**:Spec **生长**于原则性纠正,**不凭空想出来**。

### 2.4 Spec 的厚度 = 拒绝重复劳动的次数

项目里有多少条 Spec,就有多少次"我不要再让 AI 犯同样错误"的决定。

## 3. Harness 本体论

### 3.1 定义

**Harness = 可执行测试,把 Spec 锁住**。
不是抓 bug(覆盖率 KPI),是**锁住 AI 不能违反的边界**。

### 3.2 类比

| 概念 | 类比 | 作用 |
|------|------|------|
| **Spec** | 图纸 | 定义"想让模型做什么" |
| **Harness** | 车间 | 确保模型"每次都按这个清单办事" |

图纸再精确,车间机床摆乱 = 产品次品。
车间管再好,图纸错 = 把次品做得更快。

**两者缺一不可**。

### 3.3 Harness 配 vs 不配

| Spec 类型 | 配 Harness? |
|-----------|------------|
| **核心业务边界**(AI 不能随意改) | ✅ 必须配 |
| 一般业务规则(可改) | ❌ 不必 |
| 架构决策(改起来成本高) | ✅ 配 |
| UI 细节(经常变) | ❌ 不必 |

**口诀**:Harness 只配"AI 不能违反的硬约束",不配"应当遵守的软规则"。

### 3.4 Harness 的特点

- **可执行脚本**(跑测试有固定流程)
- 只有成功 / 失败两种结果
- 当 AI 修改了相关代码,跑测试**自动**检测是否违反历史决策

## 4. Spec 模板(4 段)

```markdown
# Spec: <名称>

## 是什么
<功能 / 决定的具体定义>

## 为什么
<存在的原因 / 历史决策理由>

## 要实现的效果
<预期效果,可验证>

## 边界
- **禁止**: <不能做的事>
- **必须**: <必须做的事>
```

**关键**:Spec 段必须可被 Harness 测试验证。
"为什么"段允许更长(决策背景),但其他 3 段必须可执行。

## 5. Harness 模板(测试用例)

```python
# tests/test_<spec_name>.py

def test_<核心约束 1>():
    """对应 Spec: 必须满足的核心条件"""
    # given
    <setup>
    # when
    <action>
    # then
    assert <expected>

def test_<边界条件 2>():
    """对应 Spec: 禁止做的事"""
    # given
    <setup that triggers forbidden behavior>
    # when
    <action>
    # then
    assert_raises or assert_not_<forbidden>
```

**核心**:**每个 Harness test case 对应一条 Spec 的"必须 / 禁止"**。

## 6. Spec vs Harness 决策树

```
决定写下来?
├─ 是,还会反复影响 → 写 Spec
│  │
│  └─ 是否核心业务边界 / AI 不能改?
│     ├─ 是 → 配 Harness
│     └─ 否 → 不必配
│
└─ 否 / 一次性 → 不写(放 PR review)
```

## 7. 反模式

### ❌ 反模式 1:预防性写 Spec
```
"项目刚启动,我先写 50 条 Spec 把架构定下来"
```
→ 早期决定还会变,写了 = 给未来的枷锁。**等原则性纠正出现再写**。

### ❌ 反模式 2:Harness 覆盖一切
```
"所有 Spec 都配 Harness,覆盖率 100%"
```
→ 改个需求像乌龟。**只配核心业务**。

### ❌ 反模式 3:Harness 测错东西
```
测试函数: test_something_works_in_some_cases()
```
→ Harness 必须对应一条具体的 Spec("必须 / 禁止")。模糊测试不是 Harness。

### ❌ 反模式 4:Spec 用 AI 腔
```markdown
## 是什么
本规范旨在提供一种灵活可扩展的解决方案……
```
→ 直接说人话。"X 模块必须走 Y 入口。"

## 8. 不要做

- ❌ 不要预防性写 Spec(等纠正再写)
- ❌ 不要所有 Spec 都配 Harness(只配核心)
- ❌ 不要让 Spec 描述"未来可能"(只描述"已经定下来")
- ❌ 不要让 Harness 测"运行没问题"(必须测"违反 Spec 会被抓")

## 9. 与其他 skill 的关系

- **`spec-miner` agent**:挖需求 → 输出 Spec
- **`meta-writer` agent**:沉淀 Spec 到 docs/SPEC.md / topic files
- **`coder` agent**:实现 Spec + 写 Harness
- **`verifier` agent**:用 Harness 验证 coder 的实现
- **`hard-constraints`**:Spec/Harness 段本身必须用硬词

## 10. 模板(可直接复制)

### Spec 模板

```markdown
# Spec: <名称>

## 是什么
<一句话定义>

## 为什么
<历史决策理由,1-3 段>

## 要实现的效果
<可验证的预期效果>

## 边界
- **禁止**: <不能做>
- **必须**: <必须做>
```

### Harness 模板

```python
# tests/test_<spec>.py
# 对应 Spec: docs/SPEC-<name>.md

def test_spec_must_<核心约束>():
    """对应 Spec 必须段"""
    # ...

def test_spec_must_not_<禁止行为>():
    """对应 Spec 禁止段"""
    # ...
```

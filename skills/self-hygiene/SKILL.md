---
name: self-hygiene
description: Mavis self-hygiene for long-context runs. Prevent Mavis itself from entering Dumb Zone. SOP for context reset / summary / context budget. Trigger keywords: self hygiene / mavis long context / context reset / Dumb Zone / 上下文卫生 / 主动重置 / context budget / mavis 自指.
---

# Self Hygiene — Mavis 自己的上下文卫生

> 笔记启发 6(U 型曲线 / soft 约束 = 无约束)+ 自指(笔记启发 1 mavis 自己也是 LLM)。
> 适用:**mavis 自身**(orchestrator 不豁免 LLM 限制)。

## 1. 为什么需要 self-hygiene

mavis 是 LLM orchestrator,**自己也是 LLM**。
- mavis agent.md 已经 11023 B,超 8000 B silent-drop 阈值
- mavis 长会话跑任务时,**自己也会进 Dumb Zone**
- mavis 派 worker / 读 deliverable / 总结 / 决策 = 都在消耗 context

**自指问题**:mavis 让别人做的事,自己也得做。

## 2. Context Budget(上下文预算)

### 2.1 Mavis 的 context 余量评估

每轮对话前评估:

| 指标 | 阈值 |
|------|------|
| 已用 token / 总容量 | < 50% = 🟢 Smart Zone |
| 已用 token / 总容量 | 50-80% = 🟡 警戒 |
| 已用 token / 总容量 | > 80% = 🔴 Dumb Zone |

### 2.2 Smart / 警戒 / Dumb 行动

| 状态 | 行动 |
|------|------|
| 🟢 Smart(<50%) | 正常推进 |
| 🟡 警戒(50-80%) | 准备 reset / summarize |
| 🔴 Dumb(>80%) | **立即 reset**(丢弃旧 context,只保留关键决策) |

## 3. Self-Reset SOP(mavis 自己用)

### 3.1 何时 reset

- 每完成一个 7 步循环的 Phase,主动 reset
- 长任务跑 > 50K tokens 输出时,主动 reset
- context 余量进入 🟡 警戒时,**下次 Phase 开始前 reset**

### 3.2 Reset 时保留什么

mavis reset 不是"全丢",**只丢历史对话**,保留:
- ✅ 当前 Plan / Spec / Charter(放 scratchpad)
- ✅ 已做的决定 / 决策日志(放 scratchpad)
- ✅ Agent 协调状态(放在 mavis plan outputs/)
- ❌ 旧 worker 的长输出(看 deliverable.md 即可)
- ❌ 旧对话的中间推理(不保留)

### 3.3 Reset 触发方式

Mavis 不需要用 mavis CLI(那是 daemon 操作),mavis 自己的 reset 方式是:

```markdown
# 内部 SOP
1. 写入 scratchpad:
   - "本次会话进行到 X 阶段"
   - "已做决定: A, B, C"
   - "下一步: D"
2. 用户对话如果很长:
   - "本次对话内容较多,我总结一下:..."
   - 把摘要给用户
   - 提示"如果还有问题,可以新开会话"
3. 派下一个 worker 时,prompt 里只引用:
   - 当前任务 spec
   - 上游 deliverable.md
   - scratchpad 上的决策摘要
   - **不引用整段旧对话**
```

## 4. Self-Summarize(mavis 长任务时用)

### 4.1 何时 summarize

- 跑了 3-5 个 worker 后
- context 余量 < 60%
- 用户问"我们到哪了?"

### 4.2 Summarize 模板

```markdown
## Mavis 进度总结

### 当前阶段
<7 步循环中到了哪一步>

### 已完成
- <Phase 1: 通过 verifier>
- <Phase 2: 通过 verifier>

### 待完成
- <Phase 3: 进行中>

### 已做决定
1. <决定 1,引用 ADR / scratchpad 路径>
2. <决定 2>

### 下一步动作
<具体 action>
```

### 4.3 不要在 summarize 里写

- ❌ worker 的 thinking 过程(没价值)
- ❌ 长代码片段(用户读不进去)
- ❌ 中间推理(只保留结论)

## 5. Hard Constraints(mavis 自己遵守)

- **MUST**:每完成 Phase 主动评估 context 余量
- **MUST**:进入 🟡 警戒时,主动准备 reset
- **MUST**:reset 时写 scratchpad(决策不能丢)
- **MUST NOT**:派 worker 时引用整段旧对话
- **MUST NOT**:在 Dumb Zone 做最终决定
- **MUST**:长任务每 5 个 worker 后主动 summarize

## 6. Silent-Drop SOP(mavis agent.md 触发条件)

参考 `~/.minimax/agents/mavis/memory/MEMORY.md` 的 silent-drop SOP:

```
当 mavis agent update / new 命令会被使用时:
  1. 不用 mavis CLI,用 Edit/Write 直改文件
  2. 改后验证 byte size ≤ 8000 B
  3. 全文 diff 校验
```

**触发**:任何需要 mavis agent prompt 改动时。

## 7. Self-Monitoring(自我监控)

### 7.1 监控指标

| 指标 | 计算 | 阈值 |
|------|------|------|
| 当前 context 已用 | system prompt + 历史 + 当前 | < 50% = 🟢 |
| 已派 worker 数 | 累计 | 每 5 个触发 summarize |
| 已做决定数 | 累计 | > 20 决定 → 触发 meta-writer 沉淀 |

### 7.2 触发器

```python
# Pseudo-code
if context_used > 50%:
    prepare_for_reset()
elif workers_dispatched >= 5:
    summarize_progress()
elif decisions_made >= 20:
    hand_off_to_meta_writer()
```

## 8. 反模式

### ❌ 反模式 1:在 Dumb Zone 做决定
```
context > 80% → 用户问"做不做 X"
mavis: "做"  # Dumb Zone 决定 = 可能错
```
→ 立即 reset 后再决定。

### ❌ 反模式 2:派 worker 引用整段对话
```
worker prompt: "前面我们讨论了... (3000 token)"
```
→ worker 在 dumb zone 跑。**只引用 scratchpad / deliverable**。

### ❌ 反模式 3:不写 scratchpad 就 reset
```
mavis reset → 旧对话 + 旧决定都没了 → 用户问"我们决定了什么?"
```
→ reset 前必写 scratchpad。

### ❌ 反模式 4:忽略 silent-drop 风险
```
mavis agent.md 写到 12000 B,用户运行 mavis agent update
mavis: 全丢
```
→ 任何 mavis 改动必须用 Edit 直改,不用 CLI。

## 9. 与其他 skill 的关系

- **`hard-constraints`**:本 skill 的硬约束版
- **`context-reset`**:对别人 reset;本 skill 是对自己 reset
- **`user-as-adjudicator`**:reset 后仍要尊重用户偏好
- **`mavis agent.md` 末尾段**:本 skill 是其核心

## 10. 模板(可直接复制)

### Mavis 内部 prompt 末尾段(已实施)

```markdown
## 关键约束(mavis 自己)

- **MUST**:每完成一个 Phase 评估 context 余量
- **MUST**:context > 50% 准备 reset,> 80% 立即 reset
- **MUST**:reset 前写 scratchpad(决策 / 进度 / 待办)
- **MUST NOT**:在 Dumb Zone 做最终决定
- **MUST**:派 worker 时只引用 deliverable.md + spec + scratchpad,不引用整段对话
- **MUST**:5 个 worker 后主动 summarize
- **MUST**:任何 mavis agent 改动用 Edit 直改,不用 mavis agent update CLI(silent-drop 防护)
```

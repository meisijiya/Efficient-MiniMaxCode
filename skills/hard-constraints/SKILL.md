---
name: hard-constraints
description: Write strong agent prompts / SKILL.md with hard-constraint vocabulary (must / never / 禁止 / 务必). Use when creating or refactoring agent.md / SKILL.md / system prompts where adherence matters. Trigger keywords: hard constraint / 硬约束 / 软约束 / U 型曲线 / must / never / 禁止 / 务必 / 强 prompt / 注意力涣散.
---

# Hard Constraints — 强约束 Prompt 元技能

> 笔记启发 6(AI 模型注意力涣散):软约束("建议/尽量")= 无约束。必须用 `must/never/obvious/absolutely` + 关键约束放尾部。
> 适用:任何创建 / 整改 agent.md / SKILL.md / system prompt 的任务。**13 agent 全用**。

## 1. 为什么需要硬约束

LLM 是**概率模型**,不是逻辑模型。
- 软词("建议"、"尽量"、"推荐")= LLM 把它当成"可选项",**默认忽略**
- 硬词("must"、"never"、"禁止"、"务必")= LLM 当成"硬规则",**默认遵循**
- 词频 / 词位置 / 词强度 = 影响 LLM 注意力的 3 大杠杆

**实验事实**(笔记启发 6):
- "建议删除冗余代码" → LLM 跳过这条的概率 > 70%
- "**必须**删除冗余代码" → LLM 跳过的概率 < 10%
- "**禁止**在 hot path 写阻塞调用" → LLM 几乎 100% 遵守

## 2. 软词 → 硬词 映射表

### 2.1 中文

| 软词(禁止用) | 硬词(必须用) |
|--------------|------------|
| 建议 / 推荐 / 可以考虑 | **必须** / **务必** / **应当** |
| 尽量 / 最好 | **必须** / **绝对** |
| 不要 / 应避免 | **禁止** / **绝对不能** / **不得** |
| 注意 / 小心 / 当心 | **警告** / **必须警惕** / **务必留意** |
| 倾向于 / 偏好 | **强制** / **默认** |
| 必要时 / 有需要时 | **当且仅当 X 时,才** |

### 2.2 英文

| Soft (forbidden) | Hard (required) |
|------------------|----------------|
| should / could / may | **must** / **shall** |
| try to / attempt to | **must** / **do** |
| avoid / be careful | **never** / **do not** / **must not** |
| preferably | **always** / **must** |
| might want to | **must** |
| recommended | **required** / **mandatory** |

### 2.3 强语义关键词(放大注意力)

| 词 | 强度 | 用法 |
|---|------|------|
| `never` | 🔴 极强 | 禁止某事 |
| `must` | 🔴 极强 | 必须做某事 |
| `always` | 🔴 极强 | 总是做某事 |
| `obvious` | 🟠 强 | 强调"显而易见应该做" |
| `absolutely` | 🟠 强 | 绝对 |
| `critical` | 🟠 强 | 关键 |
| `forbidden` | 🟠 强 | 禁止 |
| `mandatory` | 🟠 强 | 强制 |

## 3. U 型注意力曲线

LLM 上下文窗口里 token 越多,**注意力越分散**:

```
context 0-50%  : U 型 → 关注开头 + 结尾
context >50%   : 只关注结尾,头部被遗忘
```

**关键约束必须放尾部**(context 末端),因为:
- LLM 在 long context 下"只关注结尾"
- 关键约束放尾部 = 100% 被注意
- 关键约束放头部 = 中后期 context 时被遗忘

## 4. Skill 文件大小上限

笔记启发 6 实证:**300-500 行 / 8-10 KB 上限**。

| 文件大小 | 效果 |
|---------|------|
| < 200 行 | 🟢 注意力集中,效果强 |
| 300-500 行 | 🟢 可接受,接近上限 |
| 500-800 行 | 🟡 注意力开始分散 |
| > 800 行 | 🔴 严重分散,等于没写 |

**超长处理**:
- 拆 `references/` 子目录
- SKILL.md 只留入口 + 索引
- 实际内容放 references/*.md(按需 load)

## 5. 5 大强约束方案

LLM 注意力涣散是物理事实,5 个方案组合使用:

| 方案 | 原理 | 适用 |
|------|------|------|
| **CLAUDE.md / 启动段** | 系统级注入,启动加载一次 | 短会话 / 全局规则 |
| **Scan / 自检标记** | 让 LLM 主动生成与规则关联的 token(自己生成注意力更强) | 长 prompt 关键规则 |
| **Hooks** | 工具调用前后自动注入规则 | daemon 工具链 |
| **子 Agent 隔离** | 拆任务,主 context 不污染 | 长任务 |
| **策略基代码** | 程序化拦截,兜底 | 高风险动作 |

**当前 mavis 推荐**:1+2+4(CLAUDE.md + Scan + 子 Agent),3+5 是 daemon 层。

## 6. 强约束 Prompt 模板

### 6.1 通用模板

```markdown
[背景一段话]

## 必须做(必读,放尾部)
- 必须 X
- 必须 Y

## 必须不做(必读,放尾部)
- 禁止 X
- 禁止 Y

## 关键约束(放最尾部,context 末端)
- **MUST**: <关键约束 1>
- **MUST NOT**: <关键约束 2>
```

### 6.2 agent.md 尾部段(放最末端)

每个 agent.md **必须有尾部段**,放最关键的 1-2 条 hard rule:

```markdown
---

## 关键约束(必读)

- **MUST NOT**: <最关键禁止>
- **MUST**: <最关键必须>
```

**为什么放最末端**:U 型曲线下,context 末端注意力最高。

### 6.3 SKILL.md 模板(已含 hard-constraints)

```markdown
## 必须做
- [硬词描述]

## 必须不做
- [硬词描述]

## 关键约束
- **MUST**: <1-2 条>
```

## 7. 自检清单(写完后跑)

| # | 问题 | 不通过则 |
|---|------|---------|
| 1 | 关键约束放末尾了吗? | 移到末尾 |
| 2 | "建议/尽量" 这种软词还有吗? | 全替换为必须/禁止 |
| 3 | "不要做 X" 而不是 "禁止 X"? | 替换为"禁止" |
| 4 | 关键约束有 **MUST** / **MUST NOT** 标记吗? | 加 |
| 5 | skill 文件 ≤ 500 行? | 超长则拆 references/ |
| 6 | 关键规则重复 2 次(头部 + 尾部)? | 重复是 hard-constraints 的关键 |
| 7 | 反例有吗(易错的反模式)? | 加,LLM 看到反例会强化 |

## 8. 反模式(Forbidden Patterns)

### ❌ 反模式 1:软词
```markdown
建议在测试前先理解需求。
```
→ 替换:`必须**在测试前理解需求。`

### ❌ 反模式 2:关键约束放头部
```markdown
# My Agent
**禁止跳过 review**

(后面 500 行其他内容)
```
→ 关键约束放最末尾,不是头部。

### ❌ 反模式 3:文件超长(> 800 行)
→ 拆 `references/` 子目录。

### ❌ 反模式 4:"绝对不要" vs "必须不要"
→ "必须不" / "禁止" / "never" 是硬词,LLM 注意力高。
"绝对不要" 强度低于 "禁止"(LLM 内部词频统计)。

### ❌ 反模式 5:重复规则放在多处
```markdown
## 不要做 X
(中间 200 行其他内容)
## 不要做 X  # 又一次
```
→ 重复 1 次(头部 + 尾部)= OK,不要重复 3+ 次(浪费 token)。

## 9. 不要做

- ❌ 不要把"建议" / "推荐" 留在 prompt 里(LLM 会忽略)
- ❌ 不要把关键约束放头部(U 型曲线,头部会被遗忘)
- ❌ 不要写 > 800 行的 SKILL.md
- ❌ 不要用 emoji 替代硬词(emoji 不是硬词,是装饰)
- ❌ 不要假设 LLM 会"理解你意思"(必须字面硬词)

## 10. 模板(可直接复制)

```markdown
# <Agent/Skill 名称>

<背景说明>

## 必须做
- <硬词描述>

## 必须不做
- <硬词描述>

---

## 关键约束(放最末端)

- **MUST NOT**: <最关键禁止>
- **MUST**: <最关键必须>
```

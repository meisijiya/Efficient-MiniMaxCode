---
name: search-first
description: "编码前先调研。先查文档、源码、惯例，再动手。源自 karpathy 原则 1 (Think Before Coding)。触发词：search, 调研, 查文档, 找惯例, research"
---

# Search First — 编码前先调研

> 源自 karpathy 原则 1：**Think Before Coding**。在写任何代码前，先把"已有的是什么"摸清楚。避免重复造轮子、避免猜 API、避免错路径。

## 核心思想

> **"Don't assume. Don't hide confusion. Surface tradeoffs."**
> 在动手前**先确认**而不是**先猜**。

**5 分钟的搜索**可能省下 5 小时的写错返工。

---

## 何时用

**任何** 写代码任务都该先 search。特别是：
- 用到新库 / 新框架
- 不熟悉的标准库 API
- 已有代码里有相似功能
- 团队有"惯例"（编码规范 / 库选择 / 文件结构）
- Bug 修复前（搜 issue / PR / commit 历史）

---

## 5 步调研流程

### Step 1 — 查官方文档（**5-10 分钟**）
- **核心 API 是什么？** —— 别看示例就开干，看一遍类型签名
- **默认值是什么？** —— 大多数 bug 来自"我不知道它默认是 None"
- **错误怎么处理？** —— 抛什么 / 返什么 / 何时
- **当前版本是否支持？** —— `package.json` / `pyproject.toml` / `pom.xml` 里看实际版本
- **有没有 breaking change？** —— 看 CHANGELOG

```bash
# 工具
# Python
python -c "help(module.function)"
python -c "import inspect; print(inspect.getsource(fn))"

# TypeScript / JS
# 看 node_modules/<lib>/README.md
# 看 .d.ts 类型定义

# Java
javadoc <class>
```

### Step 2 — 查已有代码（**5 分钟**）
- 项目里**有没有**类似功能？**怎么实现的**？
- 命名约定？文件结构？包路径？

```bash
# 在仓库内搜
rg "similar_keyword" src/
grep -r "pattern" --include="*.ts" .
```

### Step 3 — 查 git 历史（**5 分钟**）
- 这个文件 / 这个函数**谁写的**、**为什么这么写**？
- 有没有过相关 PR / 讨论？

```bash
git log --all --oneline -- path/to/file
git log -p --all -- path/to/file | head -100
git blame path/to/file
```

### Step 4 — 查团队 / 项目惯例
- 读 `CLAUDE.md` / `AGENTS.md` / `CONTRIBUTING.md` / `STYLE_GUIDE.md`
- 读 `package.json` 的 `scripts`（看团队怎么跑测试 / lint）
- 读 CI 配置（`.github/workflows/`）—— 知道什么会 block merge

### Step 5 — 列"我现在的理解"
调研完，**用 2-3 句话**写出来：
- 我打算用 X 库 / X 模式，原因是 Y
- 项目里类似场景是这么处理的：[引用具体文件]
- 我假设 Z（用户可纠正）

**然后再开始写**。

---

## 反模式（**不要**）

### 1. 不查文档就开干
```
❌ "我记得 Python 的 json.load 是这样用的..."（其实它有别的参数）
✅ "我看了 docs.python.org/3/library/json.html，json.load(fp, *, ...) "
```

### 2. 复制 stackoverflow 不看官方
```
❌ "这个 SO 答案说用 .get('key')"（但你的库版本可能不一样）
✅ "我去翻 changelog，3.11 之后加了 .get(key, default)，旧版会 KeyError"
```

### 3. 凭"印象"用 API
```python
# ❌ "我记得 os.path.join 这样用"
import os.path
os.path.join("a", "b", "c")  # 其实 pathlib.Path 更现代

# ✅ 调研后
from pathlib import Path
Path("a") / "b" / "c"
```

### 4. 跳过 git history
```
❌ 直接改 `function foo`，不查为什么这么写
✅ git log -p -- function_foo 看历史——可能前人已经讨论过
```

### 5. 不读团队规范
```
❌ 写自己的 lint 习惯（项目用 ruff 你用 black）
✅ 读 pyproject.toml 看 [tool.ruff] / [tool.black]
```

---

## 高频搜索目标

| 你要做 | 查什么 |
|--------|--------|
| 用新库 | 官方文档、API 参考、CHANGELOG |
| 加 API 端点 | 项目里现有 routes / 错误响应模式 |
| 改 schema | 项目 migration 历史、是否有人讨论过 |
| 修 bug | issue tracker、相关 PR、stack trace 搜全网 |
| 选技术栈 | 团队现有栈 + 维护活跃度 + 体积 |
| 加测试 | 现有测试结构、test fixture 模式 |

---

## 调研输出模板

```markdown
## 调研记录：[任务名]

### 文档调研
- [库/框架名] v[版本] 官方文档
- 关键 API: [signature + 默认值]
- 关键限制: [什么不支持 / 什么会触发异常]

### 已有代码参考
- [file:line] 已有类似实现，模式是 [描述]
- 命名约定: [下划线 / 驼峰 / 包名风格]

### Git 历史
- [commit hash] [作者] 改了 [文件]，原因 [commit message]
- 相关 issue: [link]

### 团队惯例
- 测试：`pytest -v`（from pyproject.toml）
- Lint：`ruff check`（CI 必跑）
- 错误响应：统一格式 [引用]

### 我的方案
- 用 [方案 A]，原因 [3 句]
- 假设：[用户可纠正]
- 风险：[可能什么会出错]
```

---

## 时间分配

**简单任务**（明确 API）：2-3 分钟调研  
**中等任务**（新库）：10-15 分钟  
**复杂任务**（架构 / 选型）：30+ 分钟，写成 mini-PR 描述

**反直觉**：花在调研的时间**永远**比花在返工的时间少。

---

## 跟 mavis 工作流的对接

- **spec-miner** → 调研"用户/场景/约束"
- **planner** → 调研"架构选型/已有模式"
- **coder** → 调研"库 API / 项目惯例"
- **build-error-resolver** → 调研"错误信息"（搜 issue / SO）
- **silent-failure-hunter** → 调研"为什么会静默失败"

**每个角色在动手前**都应该走 search-first。

---

## 自检清单

- [ ] 查了官方文档（不是只靠记忆）
- [ ] 查了项目内类似实现
- [ ] 看了 git history（特别是改的文件）
- [ ] 读了团队规范
- [ ] 写了"我的方案 + 假设"（用户可纠正）
- [ ] 调研时间 ≥ 5 分钟（不要太短）

---

**怎么算"在工作"**：用户看到"调研记录"时觉得"这个 agent 真懂我项目"，而不是"这写的啥也不像我们代码"。

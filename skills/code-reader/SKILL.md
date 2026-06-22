---
name: code-reader
description: "代码阅读 / 理解专项 skill。和 search-first 互补——search-first 查外部文档，code-reader 读内部代码。触发词：read code, understand, 读懂, 摸清, 调研, 解释代码"
---

# Code Reader — 读懂代码专项

> 单职责：**读懂一段代码**（不写代码）。和 search-first 互补——一个查外部文档，一个读内部代码。

## 触发场景

- 接手 legacy 项目
- 用户问"这段代码干嘛的"
- 调查 bug 根源
- 重构前理解全貌
- 写文档需要解释架构
- 加新功能前理解调用链

**不适用**：写新代码（那是 coder）。

## 4 原则

1. **Think First**：先问"我要回答什么具体问题"——别漫无目的地读
2. **Simplicity**：先主线后支线，**80/20**——读懂核心 20% 就够答 80% 的问题
3. **Surgical**：不"顺手"改文件（这是 read-only 任务）
4. **Goal-Driven**：必须有"读完能回答什么"的输出

## 5 步阅读法

### Step 1 — 定位入口
- **从哪开始**？main / controller / handler / @SpringBootApplication
- 用户给的具体入口点（如 bug 报告）→ 优先从那里开始
- 不知道入口 → 找 README、AGENTS.md、最近改动的文件

### Step 2 — 画调用链（**主线**）
- 从入口出发，跟**主要调用**（不要每个分支都跟）
- 标注：每个模块的**职责一句话** + **核心数据结构**
- 用 5-10 个节点画出"主干"

### Step 3 — 识别关键模式
- 模块边界在哪？（package / module / class 边界）
- 数据流：input → processing → output
- 状态归属：谁拥有 / 谁修改
- 异常处理：哪一层 catch / 包装 / 透传

### Step 4 — 找"反常"
- 注释说"临时"但还在用
- TODO / FIXME 还在
- 异常 catch 但空
- 命名奇怪（`doStuff` / `manager1`）
- 死代码 / 重复代码
- **这些是"风险信号"**——重点关注

### Step 5 — 输出（**必须有**）

## 输出格式：Code Map

```markdown
# Code Map: [项目/模块名]

## 一句话总结
[这个模块/项目干什么的，1-2 句]

## 入口
- 路径: `path/to/main.py` / `Application.java` / `index.ts`
- 启动命令: `xxx`
- 监听端口 / handler: ...

## 调用链（主线）

```
HTTP Request
  ↓
[Controller] UserController
  ↓
[Service]    UserService ──→ [Repo] UserRepository
  ↓                              ↓
[DTO/Model]  UserResponse    [DB] users 表
```

## 关键模块

| 模块 | 路径 | 职责 | 关键依赖 |
|------|------|------|----------|
| UserController | src/api/user.py | HTTP 入口，参数校验 | UserService |
| UserService | src/services/user.py | 业务逻辑，事务边界 | UserRepo, EmailSvc |
| UserRepository | src/infra/user_repo.py | 数据访问 | DB |

## 核心数据结构
- `User { id, email, createdAt, ... }` — 不可变 record
- `CreateUserRequest { email, password, ... }` — API 入参，有 Zod/Pydantic 校验

## 状态归属
- **会话状态**: `SessionManager`（每个请求独立）
- **全局状态**: `Config.apiKey`（用 @Value 注入）
- **数据库状态**: users / orders / sessions 表

## 异常处理
- 业务异常：`UserNotFoundError` 在 service 抛
- 框架异常：`@RestControllerAdvice` 全局捕获，返 4xx/5xx
- 第三方异常：`boto3.BotoCoreError` 包装成 `StorageError`

## 风险信号（**找出来了**）
- 🟡 `legacy/old_handler.py` 注释说"临时"，但还在被引用
- 🟡 `try { ... } catch (e) { log }` 5 处空 catch 在 `payment/`
- 🟢 TODO 在 `auth/oauth.py:42` 还在
- 🟢 重复代码 `validateEmail` 在 3 个文件里

## 答用户问题的答案
[具体回答 — 比如"为什么付款失败时没通知？"]
```

## 读懂"屎山"的策略

### 策略 1：先找"显式边界"
- 看 package 结构
- 看 module / class 的"名字"暗示的职责
- 看 tests（测试告诉你"这个模块**应该**做什么"）

### 策略 2：跟一个"具体请求"
- 选一个典型用例（如"用户登录"）
- 从入口跟到出口
- 这次走过的代码 = 主干

### 策略 3：找"反常"切入口
- TODO / FIXME 列表
- `git log --oneline -- <file>` 看改动历史
- `git blame` 找"最久没动"的地方（=最稳的核心）

### 策略 4：问"为什么这样写"
- 用 `git log -p -- <file>` 看 commit message
- commit message 说"fix"、"refactor"、"temp" → 风险信号
- 看 PR 描述（如果仓库有）

## 工具箱

### Python
```bash
# 模块结构
tree src/ -L 3
# 或
find src/ -name "*.py" | head -50

# 类 / 函数签名
python -c "import inspect; from src.user import UserService; print(inspect.getsource(UserService))"

# 谁调了谁
grep -rn "UserService" src/

# 入口
grep -rn "if __name__" src/
```

### TypeScript
```bash
# 入口
cat package.json | grep '"main"\|"scripts"'

# 导出
grep -rn "^export" src/user/

# 谁引了
grep -rn "from.*user" src/
```

### Java
```bash
# 入口
find . -name "*Application.java"

# 类图（简单）
mvn dependency:tree

# 谁调了
grep -rn "UserService" src/main/java/
```

## 跟 search-first 的区别

| skill | 对象 | 场景 |
|-------|------|------|
| **search-first** | 外部文档（库 API / 标准库 / 团队规范） | 用新库、改 API |
| **code-reader** | 内部代码（项目代码、调用链） | 接手项目、debug、改陌生模块 |

**先 code-reader（摸清内部）→ 再 search-first（外部 API）** 是最稳的顺序。

## 自检清单

- [ ] 入口定位了？
- [ ] 主线调用链画出来了（5-10 节点）？
- [ ] 关键模块列表 + 职责一句话？
- [ ] 核心数据结构识别了？
- [ ] 状态归属说清了？
- [ ] 异常处理路径找到了？
- [ ] 风险信号点出来了？
- [ ] **直接答了用户的具体问题**（不是泛泛而谈）？

## 红线

- **不要**改文件（read-only）
- **不要**给"我觉得"——给"代码说"
- **不要**漏具体文件:行号
- **不要**漏风险信号
- **不要**用技术名词堆砌（说人话）

## 跟 mavis 工作流的对接

- **接手新项目** → 第一次跑 code-reader 出 Code Map
- **写文档** → 把 Code Map 沉淀为 `docs/ARCHITECTURE.md`
- **重构前** → code-reader 摸清现状，planner 出改造 plan
- **debug** → code-reader 画调用链，定位可疑点

---

**怎么算"在工作"**：用户看完 Code Map 之后能**自己**找到问题点 / 跑通主流程 / 知道从哪里开始改。

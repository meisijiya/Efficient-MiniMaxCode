---
name: verification-loop
description: "目标驱动 + 验证循环。把模糊任务转成可验证的成功标准，循环到过为止。源自 karpathy 原则 4。触发词：verify, test, tdd, 验证, 循环, 目标"
---

# Verification Loop — 目标驱动 + 验证循环

> 源自 karpathy 4 原则之 4：**Goal-Driven Execution**。把命令式任务转成可验证的成功标准，循环到通过。

## 核心思想

> **"LLM 擅长循环到满足具体目标——别告诉它做什么，给它成功标准看它走"**
> — Andrej Karpathy

**强成功标准 → LLM 能独立循环**  
**弱成功标准（"弄好就行"）→ 反复回来问**

---

## 何时用

任何**有明确"完成"定义**的任务：
- 编程（测试通过 = 完成）
- Bug 修复（复现测试失败 → 修 → 测试通过 = 完成）
- 重构（前后测试都过 = 完成）
- 文档（过 link check / spell check = 完成）
- 任何有"测试 / 校验"步骤的任务

**不适用**：开放式探索、设计讨论、用户研究。

---

## 模式：可验证目标三要素

每个任务必须能转成这三要素：

```
1. [动作] → 2. [可观察的指标] → 3. [可重复的验证命令]
```

### 例子

| 模糊任务 | 强目标 |
|---------|--------|
| "加个验证" | 写无效输入的测试，让它通过：`pytest tests/test_x.py -k invalid -v` |
| "修这个 bug" | 写复现测试，让它通过：`pytest tests/test_bug_repro.py::test_x` |
| "重构 X" | 前后测试都过：`pytest tests/test_x.py && mypy src/x` |
| "加个 API" | 启动服务、curl 200：`curl -X POST localhost:8000/api/x -d '{}' \| jq .status` |
| "修这个 lint" | 跑 lint 0 error：`ruff check src/ \| grep -c error` |
| "加索引" | EXPLAIN 显示用新索引：`EXPLAIN ANALYZE ... \| grep "Index Scan"` |

---

## 完整工作流

### Step 1 — 写失败测试 / 验证（**先写**）
- 在写实现前，先写一个**会失败**的验证
- 失败原因 = 实现还没写（或没修）
- 失败要"具体"：报错指出**缺什么**而不是"undefined"

### Step 2 — 跑一次确认它真的失败
- 验证失败本身也可能是错的
- 跑一次确认"红的"

### Step 3 — 写实现 / 修复
- 写最小实现让测试绿
- **不要**写超出测试范围的代码（karpathy 原则 2）

### Step 4 — 跑测试确认绿
- 修完跑测试，确认绿
- **不要**只跑这一个测试——跑相关测试集

### Step 5 — 如果还是红，**循环**
- 看错误信息
- 改实现
- 回到 Step 4
- **最多循环 N 次**（如 5 次）——之后停下来问用户

### Step 6 — 全套验证
- 测试过了 → 跑全套：`lint` / `type check` / `format`
- 跑全测试套件（避免改 A 坏 B）

### Step 7 — 报告
- 报告做了什么
- 跑过的验证命令
- 没动的部分

---

## 验证手段的层次

### 1. 单元测试（**必跑**）
```bash
pytest tests/test_x.py
vitest run src/x.test.ts
go test ./internal/x/...
mvn test -Dtest=XTest
```

### 2. 类型检查
```bash
mypy src/
tsc --noEmit
```

### 3. Lint
```bash
ruff check src/
eslint src/
```

### 4. 集成测试
```bash
pytest tests/integration/
# 启动服务、调 API、kill
```

### 5. 端到端（**E2E**）
```bash
playwright test
# 真实浏览器
```

### 6. 手动验证
```bash
# 启动服务，手 curl
curl -X POST http://localhost:8000/api/x -d '{}'
```

### 7. 业务验证
```sql
-- 查数据库看效果
SELECT count(*) FROM orders WHERE created_at > now() - interval '1 hour';
```

---

## 强成功标准的特征

| 弱 | 强 |
|----|----|
| "修好 bug" | "测试 `test_repro` 通过，且 `test_related` 没回归" |
| "加个 API" | "启动服务后 `curl /api/x` 返 200 且 body 含 `id` 字段" |
| "优化 X" | "p95 latency < 200ms（k6 测）" |
| "改对风格" | "`ruff check` 0 error，" |
| "加文档" | "`mkdocs build` 成功，所有内部链接无 404" |

---

## 反模式（**不要**）

### 1. 没验证就宣布完成
```
❌ "我改了 X"（没跑测试）
✅ "我改了 X，`pytest tests/test_x.py -v` 全绿"
```

### 2. 测试"装样子"通过
```python
# ❌ 测试永远过
def test_something():
    assert True

# ✅ 测试真在测
def test_user_validation_rejects_bad_email():
    with pytest.raises(ValidationError):
        create_user(email="not-an-email")
```

### 3. 改测试让红的变绿
```python
# ❌ 修 bug 时把测试断言改了
def test_order_total():
    # 业务说 total 应该是 100，但测试断言改成 99
    assert order.total == 99
```

### 4. 用"应该过了"代替验证
```
❌ "代码看起来对，应该过了"
✅ "我跑了 `pytest -v`，10/10 通过"
```

### 5. 跳过失败的测试
```
❌ "skip 这个测试，下个 PR 修"
✅ "这个测试失败，问题是 X，**现在**修"
```

### 6. 不循环就放弃
```
❌ "测试 3 次都失败，我去问用户"（用户也不知道）
✅ "第 N 次失败，错误是 X，我怀疑 Y，下次改 Z"
```

---

## TDD 黄金流程

```
1. 写失败测试
2. 跑：❌ 红
3. 写最小实现
4. 跑：✅ 绿
5. 重构（保持绿）
6. 跑：✅ 还绿
7. 重复
```

**TDD 优势**：
- 测试先写 → 实现有清晰边界
- 测试红→绿→重构 → 实现是收敛的
- 测试是文档（说"这个功能应该这样"）
- 测试是安全网（重构不怕破）

---

## 循环上限

**5 次循环失败 → 停下来**：
- 写明第 N 次失败、错误是什么
- 列出尝试过的方向
- **问用户**（不是默默拍板）

```
已循环 5 次未通过：
- 错误：`TypeError: cannot unpack non-iterable NoneType object`
- 尝试：1) 修 None check 2) 加 Optional 3) 改函数签名 ...
- 当前猜测：业务逻辑在某处返回 None 而不是抛错
- 需用户确认：[具体问题]
```

---

## 工具

### Python
```bash
pytest -v                  # 详细输出
pytest -k test_x           # 匹配名字
pytest --co                # 列出所有测试（不跑）
pytest -x                  # 第一个失败就停
pytest --lf                # 只跑上次失败
```

### TypeScript
```bash
vitest run
vitest run --coverage
vitest --ui
```

### Java
```bash
mvn test
mvn -Dtest=XTest test
```

### 数据库
```bash
EXPLAIN ANALYZE SELECT ...
```

---

## 跟 mavis 工作流的对接

- **planner** → 把"成功标准"列在 plan 里
- **coder** → 写测试 + 写实现 + 循环到绿
- **verifier** → 用 verification-loop 的方法审查
- **build-error-resolver** → 修到 build 全绿

---

## 自检清单

- [ ] 任务有"可验证的成功标准"？
- [ ] 测试 / 验证**先写**了？
- [ ] 跑了一次确认红（不是先写实现）？
- [ ] 跑全套测试没破其他东西？
- [ ] lint / type check 都过？
- [ ] 失败 5 次后停下来问用户了？
- [ ] 报告了"跑过哪些验证命令"？

---

**怎么算"在工作"**：每个任务都有"跑过的命令 + 看到的结果"作为交付物的一部分。

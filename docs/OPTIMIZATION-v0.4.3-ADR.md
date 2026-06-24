# Backlog: Mavis 工具链注册流程可靠性 (v0.4.3 候选)

> **Status**: Proposed (backlog,未启动)
> **Date**: 2026-06-24
> **Authors**: mavis orchestrator (基于 2026-06-24 silent-drop 实战教训)
> **Deciders**: 用户
> **Related**:
> - 实战教训 transcript:`mvs_d3ca9eb263b4475a959cd163381ef127` (2026-06-24 19:34 - 21:55)
> - mavis memory:`C:\Users\22923\.mavis\agents\mavis\memory\MEMORY.md`
>   - "mavis agent new/update >8000 bytes silent drop"
>   - "mavis agent new/update 不会保留 agent.md 全文"
>   - "mavis agent update --system-prompt DAEMON BUG"
>   - "mavis agent update silent-drop SOP"
> - 前序 ADR:`OPTIMIZATION-v0.4.0-ADR.md` / `OPTIMIZATION-v0.4.1-ADR.md` / `OPTIMIZATION-v0.4.2-ADR.md`

---

## 1. Context(为什么排这个 backlog)

### 1.1 触发

2026-06-24 19:34-21:55 用户注册 4 个新 agent(planner / scout / incident-responder / doc-writer)时,**反复栽在 daemon 注册流程上**。完整时间线:

| 时刻 | 动作 | 表面结果 | 实际结果 |
|------|------|---------|---------|
| 19:34-35 | `mavis agent new <name>` × 4 次 | 退出码 0, 4 个 agent.md 写入磁盘 | sqlite `agents` 表**未插入**, daemon 不知道这 4 个文件存在 |
| 19:50 | 重启 daemon | `mavis agent list` 仍返回 12 个 | 重启只重读 sqlite, 不扫磁盘 |
| 20:00+ | 多次"重启 + 验证"循环, 怀疑 cache / config / workdir | 全部失败 | 方向错了 — 真正原因是没注册, 不是没 cache |
| 21:50 | 用 `spawnSync('cmd.exe', ['mavis agent new', ...])` 不传 `--system-prompt`, 让 daemon 自动读 on-disk agent.md | 16 个 agent ✓ | mavis 工具链**只在显式不传 --system-prompt 时才走"读磁盘 overlay"分支** |

**根因**:`mavis agent new` 的设计假设 = 传 `--system-prompt` 就用 CLI 入参, 不传就读磁盘 overlay。**两个分支对 sqlite 写入的处理不一致**:
- 传 `--system-prompt` → 写 sqlite + 写磁盘 stub(覆盖已有 agent.md)
- 不传 `--system-prompt` → 写 sqlite(读磁盘 overlay 作为 systemPrompt 注入)
- 直接放文件(0 步骤 CLI) → 只写磁盘, **不写 sqlite** ← 这次的坑

### 1.2 受影响的 issue 范围

今天发现的 silent-drop 系列 bug 都源于这个根因家族:

| # | Issue | 优先级 | 影响 |
|---|-------|--------|------|
| B-1 | `mavis agent new` 失败时 silent(0 退出码 + 无错误) | **P0** | 用户无法判断成功/失败, 反复 "重启验证" 浪费 1h+ |
| B-2 | 启动时 daemon 不对比磁盘 vs sqlite, 缺哪个不补 | **P0** | 手动放文件注册的 agent 永远不被 daemon 发现 |
| B-3 | `mavis agent list` 不显示磁盘与注册表差异 | **P1** | 用户没法看到 "磁盘有但没注册" 的孤儿 agent |

### 1.3 不在本 backlog 范围

- **agent.md >8000B silent drop** — 已有 work-around(`mavis agent update silent-drop SOP`), 等 MiniMax Code 团队修
- **`mavis agent update --system-prompt` daemon bug** — 走 Edit/Write 工具绕开
- **mavis 工具链其他 silent failure** — 等下次复发再排

---

## 2. Issue B-1: `mavis agent new` 失败时返回明确错误

### 2.1 问题描述

`mavis agent new <name> --engine X --persona Y --display-name Z --description W` 在以下场景**返回退出码 0 但实际失败**:
- `--system-prompt` 内容 >8000B(daemon silent drop)
- 磁盘已有同名 `agent.md`, CLI 入参与磁盘不一致时, 不报错而是**覆盖磁盘 stub**
- sqlite 写入失败但磁盘写入成功时, 不报错

### 2.2 验收标准

```
1. mavis agent new --system-prompt "x" (x > 8000 chars)
   → 退出码 1 + stderr "agent.md content exceeds 8000 byte limit (got X bytes), use on-disk overlay instead"

2. mavis agent new <name> --persona "Y"
   when on-disk agent.md already exists with persona "Z"
   → 退出码 1 + stderr "agent.md already exists at <path> with different persona, use --force or mavis agent update"

3. mavis agent new <name>
   when sqlite write fails (e.g. db locked)
   → 退出码 1 + stderr "sqlite insert failed: <err>, disk file written but agent not registered, run mavis agent list --all to diagnose"
```

### 2.3 工作量

S (1-2h, 单文件 fix)

---

## 3. Issue B-2: daemon 启动时自动注册磁盘上的孤儿 agent

### 3.1 问题描述

用户在 `~/.mavis/agents/<name>/agent.md` 直接放文件时, daemon 启动**不扫描这个目录**, sqlite 也**不自动插入**。结果: 文件存在但 daemon 不认识, 用户必须显式跑一次 `mavis agent new`。

### 3.2 验收标准

```
1. daemon 启动时, 对比 sqlite.agents 表 vs ~/.mavis/agents/*/agent.md
   - 磁盘有 + sqlite 没 → 自动注册(同 mavis agent new 不传 --system-prompt 的行为)
   - 磁盘没 + sqlite 有 → 警告日志, 不自动删除(防止误删)
   - 两边都有但 persona/display-name 不一致 → 警告日志, sqlite 是 source of truth

2. 注册行为要 idempotent — 多次重启 daemon, 不会重复 insert 或覆盖用户修改

3. 提供 mavis agent reconcile 命令手动触发(测试用)
```

### 3.3 工作量

M (3-5h, daemon 启动流程 + sqlite check + idempotency)

---

## 4. Issue B-3: `mavis agent list --all` 显示磁盘与注册表差异

### 4.1 问题描述

`mavis agent list` 只显示 sqlite 里的 agent, 用户看不到 "磁盘上有但没注册" 的孤儿文件。诊断 "为什么我的 agent 不出现" 时, 没有工具能直接看到差异。

### 4.2 验收标准

```
1. mavis agent list --all
   → 表格列: name | in_sqlite | on_disk | systemPrompt_bytes | last_modified
   → 标黄 in_sqlite=false / on_disk=true 的孤儿 agent

2. mavis agent list --orphans
   → 只列磁盘上有但 sqlite 没注册的 agent

3. mavis agent diff <name>
   → 显示 sqlite 的 systemPrompt vs 磁盘 agent.md 的 diff(>0 行差异时输出)
```

### 4.3 工作量

S (1-2h, CLI 命令 + 格式化输出)

---

## 5. 实施建议

### 5.1 优先级排序

```
P0: B-1 (silent failure 修复) → B-2 (启动自愈)
P1: B-3 (诊断工具, 依赖 B-1/B-2 之后的 schema)
```

### 5.2 拆分方案

- **Phase 1** (B-1): 1 PR, 单文件 fix, mavis 工具链立即可发版
- **Phase 2** (B-2): 1 PR, daemon 启动逻辑改动, 需要回归测试覆盖多 agent 启动场景
- **Phase 3** (B-3): 1 PR, 纯 CLI 加命令, 依赖 Phase 1/2 的稳定 schema

### 5.3 验证策略

每条 issue 必须:
1. **写失败测试** — 复现当前 silent failure 行为
2. **写修复后测试** — 验证退出码 / stderr / 行为符合 §2.2 / §3.2 / §4.2 验收标准
3. **跑 mini-Mavis 回归** — 16 个 agent 全注册 + `mavis agent list --all` 一致

### 5.4 不做的事

- **不做 agent.md 自动迁移 / schema 版本控制** — 超出工具链 bug 修复 scope
- **不做 mavis agent 自检 / 健康 dashboard** — 留给 v0.5.0+
- **不强制 daemon 启动时清磁盘孤儿** — 用户可能手动放文件调试, 不能自动删

---

## 6. 风险与回滚

| 风险 | 缓解 |
|------|------|
| B-2 daemon 启动自愈导致现有 sqlite 数据被磁盘 stub 覆盖 | 启动时只 INSERT, 不 UPDATE; 两边不一致只警告不覆盖 |
| B-1 退出码变更破坏依赖 mavis agent new 退出码 0 的脚本 | 文档 changelog 标 BREAKING, 给出 `--force-silent` 兼容 flag |
| B-3 加命令后 CLI help 文本变长 | 放子命令 `mavis agent diag --all`, 主 `mavis agent list` 保持简洁 |

---

## 7. 决策点(用户拍板)

1. **B-1/B-2 是否并入 v0.4.3,还是推到 v0.5.0?**
   - v0.4.3 = hotfix 窗口(快速修 P0, 1-2 周内)
   - v0.5.0 = 下一个 feature 周期(2-4 周)

2. **B-3 是否需要?**
   - 有了 B-1/B-2, B-3 主要是诊断便利性, 可选

3. **谁来修?**
   - 选项 A: mavis 工具链 PR 给 MiniMax Code 团队
   - 选项 B: fork mavis 本地改 + 写 patch
   - 选项 C: 用户提 issue, 等官方修

---

## 8. 排期占位(用户确认后填)

```
v0.4.3 (待定):
- [ ] B-1: mavis agent new silent failure → exit code
- [ ] B-2: daemon startup auto-register orphan agents
- [ ] B-3: mavis agent list --all / --orphans / diff

v0.5.0 (候选, 不在本 backlog):
- [ ] agent.md schema 版本控制
- [ ] mavis agent 自检 / 健康 dashboard

---

## 9. Self-test 反向证据 (2026-06-24 23:24)

### 9.1 验证目标

确认 **work-around(plan engine 委派 + on-disk overlay + daemon 自动读)** 在实战中稳定,**B-1/B-2 担心的 silent-drop 在新 agent 注册路径下不复现**。

### 9.2 测试设计

- **Plan**:`plan_67dba0c9` — v0.4.2 新加 4 agent 自检(planner / scout / incident-responder / doc-writer)
- **路由**:走 `mavis team plan run <yaml>`(plan engine),prompt **hardcode 进 YAML**(不走 `--content` 字符串)
- **委派链**:plan engine → daemon spawn worker → worker 读 on-disk `agent.md` overlay → 任务执行 → verifier 审 → cycle auto-accept
- **每个 task 都是独立的 hello-world self-test**:planner 出 spec-miner brief 的 plan、scout 探索 agents/ 目录、ir 跑 mock SEV3、doc-writer 精简 243 行 SKILL.md。

### 9.3 结果(2026-06-24 23:24 cycle-1-auto-accept)

| Agent | Self-test | 关键产出 | Verifier |
|-------|-----------|---------|----------|
| `planner` | ✅ PASS | 2 phase / 2 issue vertical-slice plan(non-goals + risks + verification 全套),172 行 deliverable | ✅ PASS |
| `scout` | ✅ PASS | 盘点 13 repo overlay + 17 runtime,事实披露 3 个 v0.4.2 新 agent sync gap | ✅ PASS |
| `incident-responder` | ✅ PASS | mock SEV3 incident 走完 4 阶段(报警/定位/缓解/复盘),边界清晰 | ✅ PASS |
| `doc-writer` | ✅ PASS | 243 行 SKILL.md 精简成 248 字 README 段,3 个必保留章节全在 | ✅ PASS |

**成本**:8 sessions / 472k tokens(input 413k + output 58k) / **$1.01**(1 个 plan cycle 全包)
**完整记录**:`C:\Users\22923\.mavis\plans\plan_67dba0c9\notes\cycle-1-auto-accept.md`

### 9.4 反向证据 — B-1 / B-2 状态澄清

**B-1(`mavis agent new` silent failure → 0 退出码)** 担心的现象:注册新 agent 时 CLI 静默失败 / sqlite 未写入。
- **本次测试路径**:plan engine YAML → daemon 内部 spawn worker。**未直接调用 `mavis agent new`**,所以本次**不能证明 B-1 已修**。
- **结论**:B-1 仍是 open。优先级 P0 不变。

**B-2(daemon 启动不自检磁盘 vs sqlite)** 担心的现象:手动放 agent.md,daemon 不知道。
- **本次测试路径**:4 个 v0.4.2 新 agent 已通过 `spawnSync('cmd.exe', ['mavis', 'agent', 'new', ...])` **不传 --system-prompt** 路径注册过(2026-06-24 19:34-21:55 work-around),daemon sqlite 写入成功,plan engine 能正常 spawn 这 4 个 agent。
- **结论**:**work-around 路径稳定**,但根因(daemon 启动不自检磁盘)仍是 open。优先级 P0 不变。

### 9.5 综合判断

- ✅ **work-around SOP 实战有效**:`plan engine yaml hardcode` + `agent.md on-disk overlay` 这条组合链路在 4 个新 agent 上 100% 稳定。
- ⚠️ **B-1 / B-2 仍是真 bug**,需要在 mavis 工具链上游修复,**不接受"work-around 通了就算修好"** 的偷换概念。
- 📌 **下次复发条件**:用户再次直接放文件注册 agent(不调 `mavis agent new`) → daemon 启动不认 → 重新栽在 B-2 上。work-around 只能挡 plan engine 路径,挡不住"裸放文件"。

### 9.6 同步缺口修复(2026-06-24)

本次 self-test **额外暴露 sync gap**:scout 报告 `D:\...\Efficient-MiniMaxCode\agents\` 缺 3 个 v0.4.2 新 agent overlay(`scout` / `incident-responder` / `doc-writer`)。
- **影响**:下次跑 `install.ps1` 时,这 3 个 agent 会被覆盖回 runtime 现有版本,**目前无害**;但如果有人清理 runtime(重装 / 迁移),repo 无法恢复这 3 个 agent。
- **修复**:已将 3 个 runtime `agent.md` 同步进 repo overlay(同 commit 提交)。
- **验证**:`Get-ChildItem agents/` 从 13 → 16,与 runtime 一致。
```
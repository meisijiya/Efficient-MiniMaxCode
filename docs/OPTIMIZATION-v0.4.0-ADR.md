# ADR: Mavis 团队协作 v0.4.0 优化方案

> **Status**: Proposed
> **Date**: 2026-06-24
> **Authors**:
> - **meta-writer**（synthesis 单一作者，本 ADR 的 single-writer）
> - 输入: 3 个 v0.3.0 升级后 adversarial 审查报告（verifier / architect / silent-failure-hunter）
> - 前置 ADR: `OPTIMIZATION-v0.3.0-ADR.md`（已 Proposed, 33 决策）
> - 目标版本: Mavis v0.4.0
> **Deciders**: 用户（最终拍板）+ parent session
> **Related**:
> - `C:\Users\22923\.mavis\plans\plan_0ee903db\outputs\review-verifier-v030\deliverable.md` (315 行 / 10 check / 9 finding)
> - `C:\Users\22923\.mavis\plans\plan_0ee903db\outputs\review-architect-v030\deliverable.md` (406 行 / 15 finding)
> - `C:\Users\22923\.mavis\plans\plan_0ee903db\outputs\review-silent-failure-v030\deliverable.md` (392 行 / 7 pattern)
> - `D:\MiniMax_workSpace\default_workSpace\Efficient-MiniMaxCode\docs\OPTIMIZATION-v0.3.0-ADR.md` (595 行 / 22 RC / 33 决策)

---

## 1. Context（背景）

### 1.1 v0.3.0 升级概要

v0.3.0 在 2026-06-24 09:46 完成一次原子 install（14 obra skill LastWriteTime 全部一致），把 mavis 团队从 13 agent + 31 skill 升级到 **13 agent + 43 skill**。具体变更：

| 类别 | 数量 | 详情 |
|------|------|------|
| **新增 obra skill** | 14 | brainstorming / test-driven-development / using-superpowers / writing-plans / executing-plans / subagent-driven-development / dispatching-parallel-agents / systematic-debugging / requesting-code-review / receiving-code-review / using-git-worktrees / finishing-a-development-branch / verification-before-completion / writing-skills |
| **替换/废弃** | 2 | mavis builtin `brainstorming` → obra 版（未清理 builtin）/ `test-writer` skill → obra `test-driven-development` |
| **数字层面** | +25 skill | 31 → 44 user skill；56 总计（含 12 builtin）|
| **总字节** | ~134KB | 14 obra skill 平均 8.6KB，最大 26852B (writing-skills) |

### 1.2 v0.3.0 ADR 33 决策落地进展

v0.3.0 ADR 提出 **7 P0 + 9 P1 + 10 P2 + 5 P3 = 31 决策**。v0.3.0 升级后由 3 视角独立审计，**落地状态如下**：

#### 1.2.1 v0.3.0 ADR 的 P0 落地状态（0/7 完整修复）

| P0 | 主题 | v0.3.0 升级后状态 | 证据 |
|----|------|------------------|------|
| **D-P0-1** | 恢复全局 `planner` agent | ❌ **未修** | `~/.mavis/agents/.bak/planner/` 仍在 .bak；`mavis agent list` 12 个不含 planner |
| **D-P0-2** | 修复 4 个 stub agent | ❌ **未修** | build-error-resolver / code-simplifier / meta-writer / silent-failure-hunter 全部 39B stub |
| **D-P0-3** | 8000B silent drop 防护 | ⚠️ **部分有效** | 14 个新 SKILL.md < 27000B 未触 8000B；但 `mavis/agent.md` = 10090B (>8000B) 仍存隐患 |
| **D-P0-4** | plan engine `failed` 状态 | ❌ **未验** | `mavis team plan list` 命令不存在，无法验证状态机 |
| **D-P0-5** | memory append 写 body | ✅ **已修（局部）** | verifier 自己 memory 验证 OK；mavis 自身未验证 |
| **D-P0-6** | AGENTS.md 编码修复 | ❌ **未修** | 整个文件 CJK 仍是 GBK-mojibake（"鍋?XX" / "鍔犲姛鑳" / "鏀逛唬鐮"）|
| **D-P0-7** | `mavis agent health` 命令 | ❌ **未修** | `mavis agent health` → `unknown command 'health'` |

**结论**: v0.3.0 ADR 自己列的 7 条 P0 中 **0 条完整修复，1 条局部修复（D-P0-5 仅 verifier 验证）**。这意味着 v0.3.0 升级"通过 P0 修复"是**假象**——只动了数字（skill count），没动系统行为。

#### 1.2.2 v0.3.0 ADR 的 P1 落地状态（0/9 落地）

v0.3.0 ADR 的 9 条 P1 全部未实施。SKILLS.md "Loading Map" 表仍存在（声明式空气契约）；`mavis agent show --full`、`mavis notify owner`、`mavis metric report` 等命令均未实现。

### 1.3 3 视角对 v0.3.0 升级后状态的独立审查

3 视角**互不串通**，但**独立得出高度一致的结论**——v0.3.0 是"数字升级，不是真升级"。

| 视角 | 审查方法 | 关键 finding 数 | 整体判断 |
|------|----------|----------------|----------|
| **verifier** | 实跑命令 + 字节数 + `mavis agent info` 解析 + 路由表 probe | 9 finding (4 PASS + 5 FAIL + 1 CRITICAL regression) | **VERDICT: FAIL**, 4.2/10 |
| **architect** | 6 维度架构审查（模块/契约/数据流/状态/依赖/5 实践）| 15 finding (5 CRITICAL + 6 HIGH + 4 MEDIUM) | **B-/C+ (60-65/100)**, 与上轮持平 |
| **silent-failure-hunter** | 7 个 silent failure pattern 穷举 | 4 个 v0.3.0 新引入 (2 CRITICAL + 1 HIGH + 1 MEDIUM) | **CRITICAL: 14 skill 装上但 0 主动 load** |

**3 视角核心共识**：
1. **v0.3.0 升级对系统行为 0 修缮**——v0.3.0 ADR 的 7 条 P0 0/7 完整修复
2. **v0.3.0 引入 4 个新 silent failure**（silent-failure-hunter 视角），其中 2 个 CRITICAL
3. **v0.3.0 引入 1 个 CRITICAL regression**（verifier 视角）——daemon systemPrompt 把 CJK 替换为 `??`

### 1.4 v0.4.0 必须现在做的理由

- **v0.3.0 自己列的 P0 没修**——意味着 v0.3.0 release 就是"假 release"，v0.4.0 必须补上
- **daemon CJK 损坏** 影响 12 个 live agent 的所有中文 user overlay——**用户视角下整个 mavis 团队的 CJK 知识体系已失效**
- **14 个 obra skill 装上但 0 主动 load**——v0.3.0 升级最大的投入（+25 skill）实际价值 = 0
- **obra 替换未做迁移**——mavis builtin `brainstorming` 还在 + obra 版装上 = 路由模糊
- **obra skill ↔ mavis 路由表 5/14 重复/冲突**——需要显式分层

### 1.5 本 ADR 范围

- ✅ **IN**: P0/P1 决策（必做 + 应该做），涉及 daemon 改动 + agent overlay 修正 + obra 迁移 + 路由表治理
- ✅ **IN**: P2 backlog（写下来给未来，不在 v0.4.0 scope）
- ✅ **IN**: P3 anti-pattern（不做了 + 监控）
- ❌ **OUT**: 新功能设计（v0.5+ scope）
- ❌ **OUT**: 任何"加注释 / 加文档"占位（违反 meta-writer 不写空头契约原则）

---

## 2. 3 视角发现合并去重（Consolidated Findings）

### 2.1 合并原则

- **跨视角收敛的 finding**（2+ 视角独立发现）= 高置信，提升优先级
- **单视角独有 finding** = 中置信，按本视角严重度保留
- **同义 finding**（描述不同但指向同一根因）= 合并成一条 root cause + 多个 manifestation
- **不添加新 finding**——meta-writer 只综合，不创造
- **保留 v0.3.0 ADR 已修的项**作为历史（标 ✅ Resolved），不重写

### 2.2 v0.3.0 ADR 已 Resolved 项（不重写）

| ID | v0.3.0 P0 | Resolved 状态 | 证据 |
|----|-----------|---------------|------|
| ✅ R-1 | (D-P0-5 部分) memory append 写 body | verifier 验证 PASS | `Get-Content ~/.mavis/agents/verifier/memory/MEMORY.md` line 38 是新条目 body |
| ✅ R-2 | (D-P0-3 部分) 14 obra skill 未触 8000B | verifier Check 1 PASS | 14 skill 全部 < 30000B |
| ✅ R-3 | obra 升级带来 brainstorming 替换 | verifier Check 2 PASS | `display_name="superpowers"`, obra 风格强约束 |
| ✅ R-4 | obra 升级带来 TDD 替换 | verifier Check 3 PASS | test-driven-development frontmatter 严格 TDD |
| ✅ R-5 | using-superpowers 的 SUBAGENT-STOP 机制 | verifier Check 4 PASS | sub-agent 启动有 escape hatch |
| ✅ R-6 | total skill 数量 31 → 44 数字层面 | verifier Check 5 PASS | `mavis skill list` 返回 56 |

**v0.3.0 ADR 没修的 6 条 P0**（仍待修）——进入 v0.4.0 P0-1 ~ P0-7。

### 2.3 v0.4.0 Root cause 矩阵

**合并后：17 个 root cause（28 raw finding 去重）**——meta-writer 单一作者铁律贯彻。

| Root cause | 视角覆盖 | manifestation 数 | 严重度 | 跨 v0.3.0 链接 |
|------------|----------|------------------|--------|---------------|
| **RC-v4-1** | v0.3.0 升级对系统行为 0 修缮（v0.3.0 ADR 7 P0 中 0 完整修复） | verifier (5 FAIL check) + architect (F-1/F-2 验证) + silent-failure (F4-1 meta-irony) | 3 | 🔴 CRITICAL | 继承 v0.3.0 RC-1~RC-7 |
| **RC-v4-2** | **NEW: daemon systemPrompt 把 CJK 全部替换为 `??`**（12 agent × ~100 CJK 损坏）| verifier (Check 9 + 维度 3.1) + silent-failure (F2-1 间接 + F3-2 联动) | 2 | 🔴 CRITICAL | v0.3.0 引入的 REGRESSION |
| **RC-v4-3** | **NEW: 14 个 obra skill 装上但 0 主动 load**（4 个核心 agent systemPrompt 0 引用 obra skill）| silent-failure (F4-1) + architect (F-4) + verifier (维度 3.4 间接) | 3 | 🔴 CRITICAL | v0.3.0 引入的 SILENT FAILURE |
| **RC-v4-4** | **NEW: `mavis skill list` 输出无效 JSON**（CRLF 在 string 里）| silent-failure (F2-1) | 1 | 🔴 CRITICAL | v0.3.0 引入的 silent failure |
| **RC-v4-5** | 7 个老 skill YAML frontmatter 解析失败（daemon 269 次/天 WARN）| silent-failure (F2-2) | 1 | 🟠 HIGH | pre-existing, v0.3.0 暴露更明显 |
| **RC-v4-6** | obra 替换 mavis builtin 迁移未做（brainstorming 重复）| architect (F-5) | 1 | 🟠 HIGH | v0.3.0 引入的 DUPLICATE |
| **RC-v4-7** | coder/agent.md L142 引用已删的 `test-writer` skill | architect (F-3) | 1 | 🟠 HIGH | v0.3.0 引入的 BROKEN LINK |
| **RC-v4-8** | obra 源目录 install 后被清空（无独立 SHA-256 校验）| silent-failure (F3-1 + F7-1) | 2 | 🟠 HIGH | v0.3.0 引入的 SILENT ROLLBACK 风险 |
| **RC-v4-9** | obra skill ↔ mavis 路由表冲突（5/14 重复/冲突）| architect (F-6/F-7/F-8/F-9/F-10) | 5 | 🟠 HIGH | v0.3.0 引入的 ARCHITECTURE DRIFT |
| **RC-v4-10** | SKILLS.md Loading Map vs agent.md 实际声明严重漂移（5 项 🔴）| architect (F-11) | 1 | 🟠 HIGH | 继承 v0.3.0 RC-7 (SKILLS.md 空气契约) |
| **RC-v4-11** | mavis skill list CJK 双重编码 mojibake | silent-failure (F3-2) | 1 | 🟡 MEDIUM | v0.3.0 引入的 CLI UX 损坏 |
| **RC-v4-12** | 14 obra skill 一次全装, 违反增量式（5/14 跟现有重复/冲突）| architect (F-12) | 1 | 🟡 MEDIUM | v0.3.0 引入的 SCOPE CREEP |
| **RC-v4-13** | using-superpowers 4 职合一（违反单一职责）| architect (F-13) | 1 | 🟡 MEDIUM | v0.3.0 引入的 SRP VIOLATION |
| **RC-v4-14** | obra skill 英文 description vs mavis builtin 中文 description 路由不一致 | verifier (维度 3.3) | 1 | 🟡 MEDIUM | v0.3.0 引入的 ROUTING INCONSISTENCY |
| **RC-v4-15** | obra skill 大小未触 8000B drop 但 context window 占用风险 | verifier (维度 3.4) | 1 | 🟡 MEDIUM | v0.3.0 引入的 ATTENTION BUDGET 风险 |
| **RC-v4-16** | daemon WARN 不 dedup（269 次/天噪声放大器）| silent-failure (F6-2) | 1 | 🟡 MEDIUM | pre-existing, v0.3.0 暴露更明显 |
| **RC-v4-17** | mavis skill audit / verify / diff 子命令缺失 | silent-failure (F4-1 + F7-1 + F3-1) | 1 | 🟢 LOW | 跨多次提及 |

### 2.4 v0.4.0 关键 Finding 按视角汇总

#### verifier 视角 9 finding → v0.4.0 关联
- Check 1~5 PASS: 数字层面对位（✅ 不入 v0.4.0）
- Check 6~10 FAIL: 7 P0 没修（→ RC-v4-1）
- 维度 3.1 CRITICAL: daemon CJK 损坏（→ RC-v4-2, **v0.4.0 P0-NEW-1**）
- 维度 3.2 HIGH: using-superpowers 路由冲突（→ RC-v4-3 联动）
- 维度 3.3 MEDIUM: 中英 description 路由不一致（→ RC-v4-14）
- 维度 3.4 HIGH: context window 风险（→ RC-v4-15）

#### architect 视角 15 finding → v0.4.0 关联
- F-1~F-5 CRITICAL: 5 个, 全入 v0.4.0 P0/P1
- F-6~F-11 HIGH: 6 个, 5 个入 v0.4.0 P1, F-11 入 v0.4.0 P1-v4-8 (frontmatter)
- F-12~F-15 MEDIUM: 4 个, F-12 → RC-v4-12, F-13 → RC-v4-13, F-14 → RC-v4-9 联动, F-15 → 顺序敏感标注

#### silent-failure-hunter 视角 → v0.4.0 关联
- F2-1 CRITICAL: JSON CRLF in string（→ RC-v4-4, **v0.4.0 P0-NEW-2**）
- F2-2 HIGH: 7 老 skill YAML（→ RC-v4-5）
- F3-1 + F7-1 HIGH: obra 源目录清空（→ RC-v4-8）
- F3-2 MEDIUM: CLI CJK mojibake（→ RC-v4-11）
- F4-1 CRITICAL: 14 obra 0 主动 load（→ RC-v4-3, **v0.4.0 P0-NEW-3**）
- F6-2 MEDIUM: WARN 不 dedup（→ RC-v4-16）

---

## 3. Decision（决策）

### 3.1 P0 — 必做，v0.4.0 release 阻塞

> **原则**：P0 是"不修就别发 v0.4.0"。每条都是 critical path 必修。
> **结构**: 7 条继承 v0.3.0 P0（修 0 完整修复的债）+ 3 条 v0.4.0 NEW P0（修 v0.3.0 升级暴露的新 critical）。

#### 继承 v0.3.0 P0（修 v0.3.0 升级没修的债）

#### **D-P0-1** [继承 v0.3.0 D-P0-1]：恢复全局 `planner` agent，删项目级 `agents/planner/`（修 RC-v4-1）

- **目标**: `/plan` 工作流能在全局 mavis 上下文跑通
- **步骤**:
  1. 把 `~/.mavis/agents/.bak/planner/` 移到 `~/.mavis/agents/planner/`（恢复全局）
  2. 删 `D:\MiniMax_workSpace\default_workSpace\Efficient-MiniMaxCode\agents/planner/`（避免 source-of-truth 分裂）
  3. `mavis agent info planner` 验证 systemPrompt 完整（≥ 2000B）
- **Owner**: release-manager
- **验收**:
  - `mavis agent info planner` 返回完整 agent.md 内容
  - `mavis agent list` 12 → 13 个 agent
  - plan-workflow skill L29-30 流水线 step[2] 可正常 spawn
- **风险**: 删除项目级可能让项目本地 plan 失败（init skill 加 disclaimer）

#### **D-P0-2** [继承 v0.3.0 D-P0-2]：修复 4 个 stub agent 的 agent.md（修 RC-v4-1）

- **目标**: 4 个空 stub agent 重新有完整 persona
- **范围**: `build-error-resolver` / `code-simplifier` / `meta-writer` / `silent-failure-hunter`（每个 39B）
- **步骤**:
  1. 从 `D:\MiniMax_workSpace\default_workSpace\Efficient-MiniMaxCode\agents/<同名>/` 拷贝完整 agent.md
  2. **必须用 Write 工具直接写文件**（不用 `mavis agent update --system-prompt`，8000B silent drop 风险）
  3. 写完后跑 `mavis agent info <name>` 验证 systemPrompt 长度 ≥ 2000B
- **Owner**: release-manager
- **验收**:
  - 4 个 agent.md 字节数 ≥ 2000
  - `mavis agent list` 不再有任何 39B 文件
  - SKILLS.md Loading Map 5 项 🔴 漂移中 1 项（silent-fh）变绿
- **meta-irony 提示**: 本 ADR 的作者（meta-writer）自己的 agent.md 是 39B stub——**本 ADR 在自我修的范围内**
- **顺序敏感**: D-P0-2 必须**先于** D-P1-v4-8 (frontmatter requires_skills)

#### **D-P0-3** [继承 v0.3.0 D-P0-3]：修 mavis CLI 8000-byte silent drop（修 RC-v4-1）

- **目标**: `mavis agent update --system-prompt "..."` 大于 8000 字节时**返回明确错误而非静默 drop**
- **步骤**:
  1. 定位 mavis CLI 源码（daemon 内）
  2. 在 size 校验处返回 `Error: system-prompt exceeds 8000 bytes (got N). Use --from-file <path> instead.`
  3. 退出码非 0
- **Owner**: daemon maintainer
- **验收**:
  - 传 8001 字节 → 返回明确错误 + 退出码 1
  - 传 8000 字节 → OK
  - 没有任何 `agent.md` 退化成 stub
- **配套**: **D-P0-3b** 必须配套（加 `mavis agent update --from-file <path>` 强制走 on-disk overlay 路径），分 2 release

#### **D-P0-4** [继承 v0.3.0 D-P0-4]：plan engine 状态机加 `failed` 状态（修 RC-v4-1）

- **目标**: 区分"用户主动 cancel" vs "任务失败被掩盖"
- **步骤**:
  1. plan state 加 `status: failed` 状态值
  2. spawn 失败 / verifier FAIL / agent not found / 8000B drop 等场景从 `cancelled` 改为 `failed`
  3. `mavis team plan status <id>` 输出明确区分
  4. `failed` 状态自动触发 D-P1-5 (v0.3.0 ADR) / D-P1-v4-15 (本 ADR)（owner notification）
- **Owner**: daemon maintainer
- **验收**:
  - 历史 plan_6534a4bc / plan_c994728c 重新跑一遍 status 检查能区分
  - 新 plan 失败时 status = `failed`
- **影响**: 2/5 历史 plan 从 `cancelled` 升格为 `failed`——用户回头看会发现 40% 失败率

#### **D-P0-5** [继承 v0.3.0 D-P0-5]：修 mavis orchestrator 自身 memory append（修 RC-v4-1）

- **目标**: `mavis memory append` 真的把 body 写入 MEMORY.md
- **步骤**:
  1. 排查 `mavis memory append` 实现（daemon 内）——是不是 markdown 特殊字符 / 超长行 truncate
  2. 强制 schema 校验：append 的 content 必须含 `### <title>` + `Type: <type>` + body
  3. 写完后 `mavis memory show mavis` 验证 body 真的存在
- **Owner**: daemon maintainer
- **验收**:
  - `~/.mavis/agents/mavis/memory/MEMORY.md` ≥ 2000B（含 ≥ 5 条 Type+body 完整 memory）
  - 历史 8 条 stub 标题自动迁移到新格式
- **重要**: 这是 Mavis 能"反思"的最低基础设施——**不修这条，团队永远学不会**

#### **D-P0-6** [继承 v0.3.0 D-P0-6]：用 UTF-8 重写 AGENTS.md（修 RC-v4-1）

- **目标**: `Efficient-MiniMaxCode/AGENTS.md` 编码正常（中文不乱码）
- **步骤**:
  1. 用 Edit / Write 工具（**不**用 PowerShell `Set-Content`，避免 BOM）重写 AGENTS.md
  2. 头部加 `Last verified: 2026-06-24 | Total: 13 agents (mavis agent list | wc -l)`
  3. 同步把 init skill 加 `AGENTS.md 自动生成` 步骤
- **Owner**: release-manager
- **验收**:
  - 任何 agent 启动项目时 Read AGENTS.md 看到正确中文
  - `grep "鐪" / "鏀" / "鍋" / "鍔" / "鏋" / "浠" / "鐮" / "鐪" / "鎻" / "鏂" / "閲" / "杩" / "鐐" / "鍑" / "鐧" / "鐧" / "鏍" / "鏂" / "鍗" / "鍑" / "宸" / "閮" / "鏄" / "鍛" / "鐮" / "鏄" / "鏂" / "璁" / "鍋" / "閮" / "鏂" / "瀹" / "璁" / "鍋" / "閮" / "鏂" / "瀹" / "璁" / "鍋" / "瀹"` 等乱码特征字符串 0 命中
- **meta-irony 提示**: 本 ADR 引用的 AGENTS.md 内容**就是 mojibake**——本 ADR 不重写 AGENTS.md,只标待修

#### **D-P0-7** [继承 v0.3.0 D-P0-7]：加 `mavis agent health` 命令（修 RC-v4-1 可观测性）

- **目标**: 系统性发现 stub agent / missing agent
- **步骤**:
  1. daemon 暴露 `mavis agent health` 命令
  2. 输出表：`agent_name | overlay_size_bytes | is_stub | daemon_can_spawn | registered_description | actual_persona_match`
  3. 健康分 = `(overlay≥1000B ? 1 : 0) × 0.5 + (can_spawn ? 1 : 0) × 0.5`
  4. 健康分 < 0.7 触发 warning
- **Owner**: daemon maintainer
- **验收**:
  - `mavis agent health` 输出 12 行（live agents）
  - 4 个 stub agent 标注 `is_stub: true`
  - planner 标注 `not_found: true`

#### v0.4.0 NEW P0（修 v0.3.0 升级暴露的新 critical）

#### **D-P0-NEW-1** [v0.4.0 NEW]：修 daemon systemPrompt CJK 替换为 `??` 的 bug（修 RC-v4-2）

- **目标**: daemon 加载 agent.md 时保留 CJK 字符，不替换为 `??`
- **背景**: verifier 实测 12 个 live agent × `mavis agent info` 输出 systemPrompt 的 CJK count = 0，`??` count 平均 100+（mavis:160, verifier:76）。这意味着用户花 5+ 周写的所有 CJK 覆盖层在 daemon 视角下全是 ASCII-only 残骸。
- **步骤**:
  1. 定位 daemon 加载 agent.md 的代码路径（`mavis agent info` → systemPrompt 字段）
  2. 字节级检查 CJK 字符被替换为 `??` 的位置
  3. 修复字符编码处理（疑似 PowerShell / Node.js stdout buffer 截断或 latin-1 转换）
  4. 修复后跑 `mavis agent info <name>` 验证 CJK count > 50，`??` count = 0
- **Owner**: daemon maintainer
- **验收**:
  - 抽样 5 个有 CJK 覆盖层的 agent（mavis / coder / verifier / architect / meta-writer），CJK count > 50，`??` count = 0
  - 用户用中文 query 调 mavis 时不再有"半 CJK 半乱码"的 mix
  - silent-failure-hunter 自己的 agent.md (39B stub) D-P0-2 修完后也要 verify CJK 保留
- **严重度理由**: **v0.3.0 升级引入的最严重 regression**——影响所有 CJK 覆盖层 agent 的 systemPrompt,等效于"v0.3.0 之前的所有中文工作全部被 daemon 静默丢弃"
- **修复路径**: 必走 daemon 源码——meta-writer 不接实现,只标 owner

#### **D-P0-NEW-2** [v0.4.0 NEW]：修 `mavis skill list` JSON escape（CRLF in string）（修 RC-v4-4）

- **目标**: `mavis skill list` 输出是合法 strict-parseable JSON
- **背景**: silent-failure-hunter 实测 `mavis skill list` 输出 562 行 JSON,`json.loads()` 失败在 `line 6 col 199: Invalid control character`——Windows CRLF (`\r\n`) 直接写在 JSON string 内部。同源问题让 `mavis agent info <name>` 解析也失败。
- **步骤**:
  1. 定位 daemon 序列化 JSON 的代码
  2. 在 `JSON.stringify()` 之前对 string 做 escape: `\r` → `\\r`,`\n` → `\\n` (或剥离)
  3. 或在序列化前统一 sanitize
- **Owner**: daemon maintainer
- **验收**:
  - `mavis skill list 2>&1 | python -c "import json,sys; json.load(sys.stdin)"` 成功
  - `mavis agent info <name>` 同样 strict-parseable
  - 所有依赖 `mavis skill list` JSON 输出的下游 agent 不再走 fallback
- **严重度理由**: **v0.3.0 升级引入的 silent failure**——daemon 重写后才埋进去,所有 sub-agent 解析失败都走 fallback → 静默
- **消费者临时方案**: `json.JSONDecoder(strict=False)` 或 `text.replace('\r', '\\r')` (本 ADR 不推荐作为永久方案)

#### **D-P0-NEW-3** [v0.4.0 NEW]：在 4 个核心 agent.md overlay 显式声明 14 obra skill 联动（修 RC-v4-3）

- **目标**: 14 个 obra skill 从"装上但 0 主动 load"变"显式联动"
- **背景**: silent-failure-hunter 实测 4 个核心 agent (mavis / coder / verifier / silent-failure-hunter) 的 systemPrompt / agent.md overlay **0 引用 14 个 obra skill 任何一个**。obra `using-superpowers` 设计的"必先 load skill"哲学对 mavis 团队**完全无效**。
- **步骤**:
  1. **mavis/agent.md** Skill 联动表最上方加:
     ```
     任何 task → 先 load `using-superpowers`（"Use when starting any conversation"）→ 决定哪些 skill 适用
     ```
  2. **coder/agent.md** 联动表加:
     ```
     - test-driven-development (obra, 严格 TDD)
     - verification-before-completion (obra, evidence before claim)
     - systematic-debugging (obra, debug 前先想 hypothesis)
     ```
  3. **verifier/agent.md** 联动表加:
     ```
     - using-superpowers (meta, 先 load)
     - verification-before-completion (obra)
     - receiving-code-review (obra, 防表演性同意)
     - requesting-code-review (obra, 4-step SOP)
     ```
  4. **silent-failure-hunter/agent.md** (D-P0-2 修完 stub 后) 联动表加:
     ```
     - systematic-debugging (obra, 7 pattern 互补)
     - using-superpowers (meta)
     ```
  5. 5 个其他完整 agent (architect / spec-miner / auditor / release-manager / general) 同步更新
- **Owner**: meta-writer + architect (审稿)
- **验收**:
  - `mavis agent info <name>` systemPrompt 含 14 obra skill 至少 3 个的字面引用
  - 用户用中文 query "写个 todo app" 触发后,`mavis agent info mavis` 的 log 显示 brainstorming 加载
- **严重度理由**: **v0.3.0 升级最大的投入（+25 skill）实际价值 = 0**——修了等于没修
- **替代方案失败案例**: 靠 `mavis skill list` description-keyword matching 已被证伪 (RC-v4-3 证据)

### 3.2 P1 — 应该做，v0.4.0 scope（不阻塞 release，但强烈建议做）

> **原则**: P1 是"不修会持续发作的工程债 + v0.3.0 升级暴露的架构债"。

#### **D-P1-v4-1** [v0.4.0 NEW]：修 7 个老 skill YAML frontmatter（修 RC-v4-5）

- **目标**: 7 个老 skill 不被 daemon YAML parser 丢弃
- **范围**: `api-design` (L181) / `context-engineering` (L106) / `frontend-patterns` (L119) / `grill-me` (L120) / `observability-and-instrumentation` (L114) / `project-context` (L136) / `search-first` (L96) —— 全部是 CJK description 里包含英文冒号 `:` + 制表符导致 YAML 解析失败
- **步骤**:
  1. 短期: 7 个 SKILL.md 的 description 字段用引号包起来（YAML 标准做法）
  2. 中期: daemon 在 SKILL skip 时直接 ERROR 一次 + 在 `mavis skill list` 里标 `[broken]`
  3. 长期: `mavis skill install` / `mavis skill update` 加 frontmatter 校验
- **Owner**: release-manager
- **验收**:
  - 7 个 skill 的 daemon SKIP WARN 降到 0
  - daemon-20260624*log 的 "Skipping skill" WARN 数从 269 降到 ≤ 10/天
  - `mavis skill list` 不再混"实际可加载"和"文件存在"
- **影响**: 7/29 = 24% 老 skill 恢复可用 = 29 → 36 可用 skill

#### **D-P1-v4-2** [v0.4.0 NEW]：删 mavis builtin `brainstorming`，obra 版优先（修 RC-v4-6）

- **目标**: `brainstorming` skill 只有 1 个明确权威版（obra）
- **背景**: SKILLS.md L173 写 "REPLACES mavis builtin brainstorming",但 mavis builtin 还在 `~/.mavis/.builtin-skills/` (12 builtin 列表第 4 行)。两个同名 skill 优先级未明。
- **步骤**:
  1. 把 `~/.mavis/.builtin-skills/brainstorming/` 移到 `~/.mavis/.builtin-skills/.bak/brainstorming/`
  2. 在 SKILLS.md 显式标: "brainstorming = obra 版 (user-mavis), builtin 已废弃"
  3. `mavis skill list brainstorming` 验证只有 1 条
- **Owner**: release-manager
- **验收**:
  - `mavis skill list | grep brainstorming` 只有 1 条记录
  - 4 步链路 (D-P0-NEW-3 修后) 触发 brainstorming 加载走 obra 版

#### **D-P1-v4-3** [v0.4.0 NEW]：coder/agent.md L142 改 `test-driven-development`（修 RC-v4-7）

- **目标**: coder 写测试时调 obra TDD skill,不是已删的 test-writer
- **步骤**:
  1. `Read D:\MiniMax_workSpace\default_workSpace\Efficient-MiniMaxCode\agents\coder\agent.md` L142
  2. 把 "涉及测试 → test-writer" 改为 "涉及测试 → test-driven-development (obra) + verification-before-completion"
  3. 同步在 Skill 联动表加 `test-driven-development`
- **Owner**: release-manager
- **验收**:
  - coder 写测试时不再调已删的 test-writer
  - 严格 TDD 流程生效 (写测试 → watch fail → minimal pass)

#### **D-P1-v4-4** [v0.4.0 NEW]：保留 obra install 源 (.source.json + SHA-256)（修 RC-v4-8）

- **目标**: 14 个 obra skill 永久可独立校验 + 防止 silent rollback
- **背景**: `D:\...\obra-superpowers-temp\skills\` install 后被清空,只剩 `.git`,无法做独立 SHA-256 校验。silent-failure-hunter 只能靠 `mavis skill list` 的 `source_kind=user-mavis` 字段做权威性证明,而这个字段本身在 F3-2 中是 mojibake 损坏的。
- **步骤**:
  1. 修改 `mavis skill install` 完成后,自动写 `~/.mavis/skills/<name>/.source.json`:
     ```json
     {
       "source_path": "...",
       "sha256": "...",
       "install_time": "...",
       "install_command": "..."
     }
     ```
  2. 加 `mavis skill verify` 子命令: 返回 `{file_exists, sha256_match, frontmatter_valid, daemon_loaded}`
  3. deploy 脚本改造: `xcopy → verify SHA-256 → rm -rf temp`(verify 在前)
- **Owner**: daemon maintainer
- **验收**:
  - 14 个 obra skill 都有 `.source.json`
  - `mavis skill verify using-superpowers` 返回 sha256_match=true
  - deploy 脚本被 kill 时不会留下半个 install

#### **D-P1-v4-5** [v0.4.0 NEW]：显式分层 mavis 路由 vs obra `subagent-driven-development`（修 RC-v4-9）

- **目标**: plan engine 不再纠结"mavis 路由派 specialist"还是"obra 派 fresh subagent"
- **背景**: mavis 路由 (orchestrator 派命名 agent 池) vs obra subagent-driven-development (每 task fresh subagent) —— 两种并行模型冲突
- **步骤**:
  1. **mavis/agent.md** 路由表加注解: "走 mavis 路由 = 派命名 specialist (coder / verifier / architect);走 obra subagent = 每 task fresh implementer"
  2. **plan-workflow skill** 文档加: "plan engine = mavis 路由, task 内子步骤可调 obra subagent-driven-development"
  3. `mavis agent info mavis` systemPrompt 含两个 skill 的优先级注解
- **Owner**: architect + meta-writer
- **验收**:
  - plan engine 跑 plan_58090e16 重放时,mavis 路由清晰不混用
  - 文档化分层: mavis 路由 = 命名 specialist, obra subagent = fresh task implementer

#### **D-P1-v4-6** [v0.4.0 NEW]：合并 `verification-loop` (mavis) + `verification-before-completion` (obra)（修 RC-v4-9）

- **目标**: 不再两个 skill 同主题 ("evidence before claim")
- **步骤**:
  1. `verification-loop` (mavis 自有) 调 `verification-before-completion` (obra) 作为 gate
  2. 或: 删除 `verification-loop`, coder/verifier 只 load obra 版
  3. SKILLS.md 显式标: "verification = obra version, verification-loop deprecated"
- **Owner**: meta-writer (改 SKILLS.md) + coder/verifier (改 agent.md)
- **验收**:
  - coder/verifier agent.md 不再 load 重复 skill
  - 路由冲突清单 (RC-v4-9) 减 1 项

#### **D-P1-v4-7** [v0.4.0 NEW]：显式分层 obra `finishing-a-development-branch` vs mavis `release-manager`（修 RC-v4-9）

- **目标**: PR 时调哪个, release 时调哪个——明确边界
- **步骤**:
  1. `release-manager/agent.md` L31-141 加注解: "release = 版本发布 (7 步流程);开发分支收尾 = 调 obra `finishing-a-development-branch` (4 选项菜单)"
  2. SKILLS.md 显式标分层
- **Owner**: release-manager + meta-writer
- **验收**:
  - PR 收尾走 finishing-a-development-branch (4 选项: merge/PR/keep/discard)
  - 版本发布走 release-manager (7 步: pre-flight/changelog/tag/push/deploy/verify/notify)
  - 路由冲突清单 (RC-v4-9) 减 1 项

#### **D-P1-v4-8** [继承 v0.3.0 D-P1-7]：Skill Loading 改用 agent.md frontmatter `requires_skills:`（修 RC-v4-10）

- **目标**: Loading Map 从"手写空气契约"变"daemon 强制"
- **顺序敏感**: **必须 D-P0-2 完成后才能启用**（否则 4 stub agent 缺省值 = `[]` 不 load 任何 skill）
- **步骤**:
  1. 修 agent.md schema 支持 frontmatter:
     ```yaml
     ---
     requires_skills:
       - vibecoding-discipline
       - verification-loop
     ---
     ```
  2. daemon spawn 时按 frontmatter 注入 skill
  3. 删 SKILLS.md 的 "Loading Map" 表（被 frontmatter 替代）
  4. D-P0-NEW-3 修完后,把 14 obra skill 也加入对应 agent 的 frontmatter
- **Owner**: daemon maintainer + meta-writer
- **验收**:
  - 4 个 stub agent 修完后 (先做 D-P0-2) 能正确 load declared skills
  - `mavis agent info silent-failure-hunter` systemPrompt 含 vibecoding-discipline + observability-and-instrumentation 注入痕迹
  - SKILLS.md Loading Map 5 项 🔴 漂移全部变绿

#### **D-P1-v4-9** [v0.4.0 NEW]：修 mavis CLI CJK mojibake（修 RC-v4-11）

- **目标**: `mavis skill list` / `mavis agent info` 的 CJK description 在 console 不再双重编码损坏
- **背景**: silent-failure-hunter 实测 "PRD to Prototype" description 输出 `浠庝骇鍝侀渶姹傚埌鍙氦浜掑師鍨嬬殑瀹屾暣宸ヤ綔娴併€�` —— 经典 UTF-8 → GBK → Latin-1 → UTF-8 双重编码链
- **步骤**:
  1. daemon 输出 JSON 时把 description 字段按 UTF-8 严格编码
  2. CLI 输出 `process.stdout.write` 用 `'utf8'` encoding (Node 端) + Windows terminal 切到 UTF-8 codepage (`chcp 65001`)
  3. 加契约自检: "输出 description 应该是中文/英文/混排,编码应是 UTF-8"
- **Owner**: daemon maintainer
- **验收**:
  - `mavis skill list` console 输出 description CJK 正常
  - LLM 用 description 触发 skill 不再被 mojibake 误导
- **优先级降级理由**: SKILL.md 文件本身没坏,平台加载路径可能走 file 不走 CLI,严重度 HIGH 而非 CRITICAL

#### **D-P1-v4-10** [继承 v0.3.0 D-P1-1]：定义 `deliverable.md` schema + plan engine 自动 validate（修 RC-v4-10 联动）

- **目标**: 跨 agent 的 deliverable 有统一结构,便于 meta-writer 合并去重
- **步骤**:
  1. 写 `references/deliverable.schema.md`（必填 Summary / Changed files / Notes / Findings[] + Finding 结构）
  2. plan engine 跑 task 完成时自动 lint deliverable.md
  3. 不符合 schema → task status = `needs_format_fix`（非 `failed`,非 `cancelled`）
- **Owner**: architect + plan engine maintainer
- **验收**:
  - plan_0ee903db 的 4 个 deliverable.md (3 review + 1 synthesis) 全部通过 schema lint
  - meta-writer 不需要"先读后猜格式"

#### **D-P1-v4-11** [继承 v0.3.0 D-P1-2]：定义 `verify_prompt` schema（修 RC-v4-10 联动）

- **目标**: orchestrator 派 verifier 任务时用统一 prompt 格式
- **schema**:
  ```yaml
  verify_prompt:
    diff: string              # 必填
    pr_url?: string
    related_spec?: string
    related_plan?: string
    severity_floor: 'LOW'|'MEDIUM|'HIGH'  # 默认 MEDIUM
  ```
- **Owner**: architect
- **验收**: plan-workflow skill 文档含 schema,verifier agent.md 引用

#### **D-P1-v4-12** [继承 v0.3.0 D-P1-3]：plan engine 加 `agent_health_gate`（修 RC-v4-1 + RC-v4-8 联动）

- **目标**: dispatch 前校验 `assigned_to` agent.md 健康
- **步骤**:
  1. plan engine 在 spawn 前调 `mavis agent health <name>`
  2. 健康分 < 0.5 → 任务 status = `paused` + 自动通知 owner（走 D-P1-v4-14 通道）
  3. 健康分 0.5-0.8 → 加 warning 到 plan log 但允许 spawn
  4. 健康分 ≥ 0.8 → OK
- **Owner**: daemon maintainer
- **验收**:
  - 当前 plan 4 个 task 全部通过 gate
  - 假设 D-P0-2 未修时:plan_0ee903db 立即 paused + owner 收到 notification

#### **D-P1-v4-13** [继承 v0.3.0 D-P1-4]：plan engine spawn 失败时自动 fallback + log（修 RC-v4-1 联动）

- **目标**: Spawn blocked 不再"engine paused, owner notified"假阳性
- **步骤**:
  1. spawn 失败自动 fallback 到 `general`（带 warning 写进 plan log）
  2. plan log 明确: "assigned_to 'X' not found, fell back to 'general', reason: ..."
  3. 错误信息加 "Did you mean: <top 3 candidates>"
- **Owner**: daemon maintainer
- **验收**:
  - `mavis agent info non-existent` 后 plan engine 不暂停
  - plan log 有 fallback 记录
  - 用户 grep `Spawn blocked` 在 plan_0ee903db+ 之后的所有 plan 看到 fallback 路径

#### **D-P1-v4-14** [继承 v0.3.0 D-P1-5]：真实 owner notification（修 RC-v4-1 + RC-v4-4 联动）

- **目标**: "owner notified" 不再是假阳性
- **步骤**:
  1. daemon 暴露 `mavis notify owner --message "..." --severity <low|med|high|critical>`
  2. 默认 channel = 写文件到 `~/.mavis/owner-inbox.md`（用户能 grep / Watch）
  3. 可选 channel = Feishu / Telegram（IM 路由已有,需 expose CLI）
  4. plan engine 在 status=failed / spawn blocked / agent_health_gate fail 时自动 trigger
- **Owner**: daemon maintainer
- **验收**:
  - plan_6534a4bc 重放时 owner-inbox.md 有 1 条 critical 通知
  - 用户 IM 收到 notification

#### **D-P1-v4-15** [继承 v0.3.0 D-P1-6]：暴露 `mavis agent show <name> --full` 显示合并后完整 prompt（修 RC-v4-2 联动）

- **目标**: 用户能看 built-in + overlay 合并后的完整 systemPrompt
- **步骤**:
  1. daemon 合并 built-in base + user overlay
  2. `--full` flag 打印完整内容（含分节标注 `[BUILTIN]` vs `[USER OVERLAY]`）
- **Owner**: daemon maintainer
- **验收**: `mavis agent show meta-writer --full` 输出 ≥ 6000B（含 builtin + overlay 合并）

#### **D-P1-v4-16** [继承 v0.3.0 D-P1-8]：引入客观 metric 替换 self-evaluation 5.7/10（修 RC-v4-1 联动）

- **目标**: self-evaluation 从"LLM 主观打分"变"可量化 metric"
- **metric 集**:
  - `task_completion_rate` = done / total_tasks
  - `verifier_first_pass_rate` = passed_attempt_1 / total_verifier_runs
  - `plan_failure_rate` = failed / total_plans
  - `user_revert_rate` = reverted / merged
  - `skill_load_success_rate` = skill_runtime_loaded / skill_declared
  - `memory_write_success_rate` = memory_body_written / memory_appends
- **Owner**: silent-failure-hunter + daemon maintainer
- **验收**:
  - `mavis metric report` 输出 6 个 metric 当前值 + 历史趋势
  - self-evaluation 必须**引用**这 6 个 metric（不能再"5.7/10 凭感觉"）
- **v0.4.0 必填**: 替换 v0.3.0 5.7/10 评估为 v0.4.0 0/10 baseline（v0.3.0 真实 4.2/10 已被 3 视角证伪）

#### **D-P1-v4-17** [继承 v0.3.0 D-P1-9]：明确 3 agent 5 实践审查分工（修 RC-v4-9 联动）

- **目标**: 不再 3 agent 都跑 5 实践 = 重复劳动
- **新分工**:
  - **architect**: 接口 / 单一职责 / 依赖方向 / 模块边界（5 实践 4 条）
  - **auditor**: 组合 > 继承（5 实践 1 条）+ 安全 / 合规 / 依赖审查
  - **verifier**: 4 层置信度门 + 边界 / 性能 + 代码正确性
  - **code-simplifier**（P2 启用后）: 过度抽象移除（接收 verifier/architect BLOCK）
- **Owner**: architect + meta-writer（改 3 个 agent.md）
- **验收**:
  - verifier agent.md 不再写"5 实践必查"
  - architect agent.md 写明"5 实践 4 条归我管"
  - auditor agent.md 写明"5 实践 1 条 + 安全合规归我管"

### 3.3 P2 — 可做，backlog（v0.4.0 之后）

> **原则**: P2 是"做了更好但不是 critical"——列出来给未来,但不在 v0.4.0 scope。

| ID | 决策 | 修 RC | Owner | 备注 |
|----|------|-------|-------|------|
| D-P2-v4-1 | 启动时只装 5 个高频 obra skill, 其余按需（using-superpowers + test-driven + verification-before-completion + using-git-worktrees + writing-plans = 5 个）| RC-v4-12 | release-manager | 修 v0.3.0 scope creep 后果 |
| D-P2-v4-2 | 拆 using-superpowers 4 职 / 标注"meta-skill 例外"| RC-v4-13 | meta-writer | meta-skill 难拆,先标例外 |
| D-P2-v4-3 | mavis skill list 路由匹配 description 中英混排策略（priority 字段 / LLM 显式 chain）| RC-v4-14 | daemon maintainer | 中英混用 query 路由不可预期 |
| D-P2-v4-4 | obra skill 大小优化 + context window 治理（拆分 writing-skills 26852B 等大文件）| RC-v4-15 | release-manager | 防 U 型注意力曲线中段衰减 |
| D-P2-v4-5 | obra task-reviewer 映射 mavis verifier（消除内嵌 2 重 vs plan-level 2 重冲突）| RC-v4-9 联动 | architect | 跟 D-P1-v4-5 互补 |
| D-P2-v4-6 | ADR 加"顺序敏感"标注（D-P0-2 → D-P1-v4-8 → D-P0-NEW-3）| RC-v4-1 联动 | meta-writer | 本 ADR 已部分标注 |
| D-P2-v4-7 | 加 `mavis skill audit` / `mavis skill verify` / `mavis skill diff` 子命令 | RC-v4-17 | daemon maintainer | 跟 D-P1-v4-4 部分重叠 |
| D-P2-v4-8 | 升级 test-writer 为 agent (D-P2-1 v0.3.0 ADR 继承) | 跨 | architect | 高频使用但 skill 调用路径长 |
| D-P2-v4-9 | 明确项目级 (docs/) vs 全局 (plans/) 输出路径双层（D-P2-2 v0.3.0 ADR 继承）| 跨 | architect | init skill 加项目根检测 |
| D-P2-v4-10 | meta-writer 写完整 single-writer 协议（含写前检查 / 锁 / 冲突处理）（D-P2-3 v0.3.0 ADR 继承）| 跨 | meta-writer | D-P0-5 修完后再做 |
| D-P2-v4-11 | 抽 4 原则到 daemon 内置，user overlay 仅写特殊规则（D-P2-4 v0.3.0 ADR 继承）| 跨 | daemon maintainer | 改 5 个 agent.md |
| D-P2-v4-12 | 7 步循环 → 强制跑完 OR 砍到 4 步（D-P2-5 v0.3.0 ADR 继承）| 跨 | architect + 用户决策 | 历史 5 plan 0 个走完 7 步 |
| D-P2-v4-13 | general 拒绝 specialist 任务, fallback 时升级用户（D-P2-6 v0.3.0 ADR 继承）| 跨 | architect | 改 general agent.md |
| D-P2-v4-14 | `mavis memory append` 加 schema 校验 + markdown sanitize（D-P2-7 v0.3.0 ADR 继承）| 跨 | daemon maintainer | 配套 D-P0-5 |
| D-P2-v4-15 | `mavis skill list --full` / `--no-truncate` (D-P2-8 v0.3.0 ADR 继承) | 跨 | daemon maintainer | CLI UX |
| D-P2-v4-16 | 加 `mavis memory list-topics --all` 不强制要求 agent name (D-P2-9 v0.3.0 ADR 继承) | 跨 | daemon maintainer | CLI UX |
| D-P2-v4-17 | workspace 清理: `.gitignore` 加 `agents/*/workspace/.opencode/node_modules/` (D-P2-10 v0.3.0 ADR 继承) | 跨 | init skill | 13 agent × 100+ locale = 1300 文件 |

### 3.4 P3 — 不做 / 监控（v0.4.0 不动）

> **原则**: P3 是"识别到了但**故意不做**"——避免 scope creep, 明确 anti-pattern。

| ID | 决策 | 修 RC | 理由 |
|----|------|-------|------|
| D-P3-v4-1 | 数字声明 drift 不修, 改成"动态生成 + Last verified"（D-P3-1 v0.3.0 ADR 继承）| 跨 | 比维护数字更可持续 |
| D-P3-v4-2 | `auditor` 默认不挂载的 loading map 不一致, **只加文档 disclaimer** (D-P3-2 v0.3.0 ADR 继承) | 跨 | 行为正确, 文档可以慢一拍 |
| D-P3-v4-3 | 7 步循环的 Reflect 步只产出 lessons——暂时砍到 4 步（Think/Plan/Build/Review）(D-P3-5 v0.3.0 ADR 继承) | 跨 | 历史 0 plan 走完 Reflect, 先砍 |
| D-P3-v4-4 | 监控 daemon WARN 噪声（24h 内同 WARN 一次）| RC-v4-16 | 短期不改 dedup, 监控, 用户量大后再做 |
| D-P3-v4-5 | 监控 obra skill 触发率（`mavis skill audit` 启用后）| RC-v4-3 联动 | D-P0-NEW-3 修后才有 metric |
| D-P3-v4-6 | silent-failure-hunter 自己也是 stub 受害者——已识别, **监控** D-P0-2 修复后是否自动恢复 | 跨 | meta-irony 已记录, 下次会自检 |

---

## 4. Consequences（后果）

### 4.1 正面（doing P0+P1）

- **v0.3.0 ADR 的 7 P0 全部兑现**（0/7 → 7/7）——v0.3.0 release 不再是"假 release"
- **CJK 覆盖层恢复可用**——D-P0-NEW-1 修后, 12 个 live agent 的中文 systemPrompt 全部可读
- **14 obra skill 真正可用**——D-P0-NEW-3 + D-P1-v4-8 修后, obra 升级的 +25 skill 价值从 0 → ≥ 0.7
- **mavis skill list 严格可解析**——D-P0-NEW-2 修后, 所有依赖 JSON 输出的下游 agent 不再走 fallback
- **mavis 团队真正"半残废" → "基本可用"**——3 视角 4.2/10 → v0.4.0 目标 6.0+/10
- **路由冲突清单 (5/14) 减到 ≤ 2/14**——obra ↔ mavis 边界清晰
- **plan failure 真实可见**——D-P0-4 + D-P1-v4-14 修后, 用户能区分主动 cancel vs 任务失败
- **重复审查劳动减少**——D-P1-v4-17 修后, 3 agent 5 实践分工明确, 审查 cycle 缩短
- **user-level contract 正常**——D-P0-6 修好 AGENTS.md, 任何 agent 启动项目能读到索引

### 4.2 负面 / 风险

| 风险 | 影响 | 缓解 |
|------|------|------|
| **D-P0-NEW-1 修 daemon CJK bug 可能 break 现有 12 agent 的 systemPrompt 解析** | 历史 plan 的 agent spawn 失败 | 先在 test 环境验证 5 个 agent, 灰度 rollout |
| **D-P0-3 硬限制可能 break 历史调用方** | 历史 plan 的 deploy agent 流程可能失败 | 先 D-P0-3b (加 `--from-file`) 再做硬限制, 分 2 release |
| **D-P0-NEW-3 改 4 个 agent.md 联动表可能跟 D-P1-v4-8 frontmatter 冲突** | 双轨 loading 协议 | D-P0-NEW-3 用 overlay 描述, D-P1-v4-8 用 frontmatter 字段, 二者合并 |
| **D-P0-5 memory schema 校验可能拒掉历史 append** | 8 条 stub 标题 memory 写不进去 | 加 migration: 自动给历史 stub 标题补 `Type: unknown` + empty body |
| **D-P1-v4-3 删 builtin brainstorming 可能让 4 stub agent 启动时找不到 skill** | silent-failure-hunter 自己加载失败 | D-P0-2 必须在 D-P1-v4-3 前完成 |
| **D-P1-v4-8 frontmatter 改 agent.md schema** | 老 agent.md 解析失败 | 加 `requires_skills` 缺省值 = `[]` (不破坏老 agent.md), 顺序: D-P0-2 → D-P1-v4-8 |
| **D-P1-v4-12 agent_health_gate 让当前 plan 暴露问题** | plan_0ee903db 跑时立即被 paused | 修完 D-P0-2 + D-P0-7 再开 gate |
| **D-P1-v4-14 owner notification 可能噪音过多** | critical 通知太多用户会关掉 | severity 阈值: critical 必发, high 聚合 (5min 内合并), med/low 写 inbox 不推送 |
| **D-P1-v4-17 改 3 agent 分工可能引发其他 agent 重新理解** | orchestrator 路由表需要重对一遍 | 同步更新 mavis/agent.md 路由表 |
| **D-P0-1 删项目级 planner 可能让项目本地 plan 失败** | repo 内 plan 不再能用 planner | 在 init skill 里说"项目级 plan 由项目内 rein/planner 处理, 全局 plan 用全局 planner" |

### 4.3 不做的代价（如果不修）

- **不修 D-P0-1**: `/plan` 工作流在全局 mavis 上**永远跑不通**
- **不修 D-P0-2**: 4/12 (33%) advertised 路由**永远断**
- **不修 D-P0-3**: 任何 `mavis agent update --system-prompt > 8000B` 静默失败——4 个 stub 可能再产生
- **不修 D-P0-4**: 40% 失败 plan 永远被标 `cancelled`, 用户无法识别
- **不修 D-P0-5**: mavis **永远学不会教训**——每次踩同样的坑
- **不修 D-P0-6**: 任何 agent 启动项目读 AGENTS.md **读不到索引**
- **不修 D-P0-7**: stub agent **永远不会被发现**——新产生的 stub 没人知道
- **不修 D-P0-NEW-1**: **12 个 live agent 的所有 CJK 覆盖层在 daemon 视角下全是乱码**——5+ 周中文工作白做
- **不修 D-P0-NEW-2**: 所有依赖 `mavis skill list` JSON 的下游 agent **永久走 fallback → silent**
- **不修 D-P0-NEW-3**: **14 个 obra skill 价值 = 0**, v0.3.0 升级对用户报的核心问题 0 修缮

### 4.4 顺序敏感图（critical path）

```
D-P0-2 (修 stub) ──────┐
                        ├──→ D-P1-v4-8 (frontmatter) ──→ D-P0-NEW-3 (overlay 联动)
D-P0-7 (agent health) ─┤
                        ├──→ D-P1-v4-12 (health gate)
D-P0-1 (恢复 planner) ─┘

D-P0-3b (--from-file) ──→ D-P0-3 (硬限制)

D-P0-NEW-1 (CJK 修复) ──→ D-P1-v4-15 (mavis agent show --full)
                        ──→ D-P1-v4-16 (metric 报告含 CJK count)
```

---

## 5. Alternatives Considered（替代方案）

> 每个 v0.4.0 P0/P1 决策考虑过哪些替代方案 + 为什么最终没选
> **v0.4.0 是新决策, alternatives 独立**——不抄 v0.3.0 ADR 的 alternatives

### D-P0-NEW-1 替代方案（修 daemon CJK 损坏）

| 方案 | 描述 | 不选理由 |
|------|------|----------|
| **A. 用户层用纯 ASCII 写 agent.md** | 强制所有 CJK 改用拼音/英文 | 损失可读性 + 用户用中文写覆盖层是合理需求, 强行改是 workaround |
| **B. 在 mavis agent info 出口做 CJK 替换回写** | daemon 输出前用 Python 做 GBK→UTF-8 修复 | 治标不治本, 真实问题是 daemon 加载 agent.md 时已经损坏 |
| **C. 改用 base64 存 agent.md 避免编码问题** | 编码无关方案 | 不可读, 失去 "agent.md 是用户可读文件" 的核心特性 |
| ✅ **D. 修 daemon 加载 agent.md 的字符编码路径 (已选)** | 找根因 (疑似 latin-1 / buffer 截断), 修源码 | — |

### D-P0-NEW-2 替代方案（修 mavis skill list JSON escape）

| 方案 | 描述 | 不选理由 |
|------|------|----------|
| **A. 消费者用 `json.JSONDecoder(strict=False)`** | 消费端兜底 | 治标不治本, 治标扩散到所有下游 agent |
| **B. daemon 改用 YAML 不用 JSON** | 换协议 | 破坏性变更, 所有现有消费者要改 |
| **C. 加中间层"safe parse" wrapper** | 套壳 | 隐藏问题, 新 bug 累积 |
| ✅ **D. daemon 序列化前 sanitize 控制字符 (已选)** | 修根因 | — |

### D-P0-NEW-3 替代方案（4 核心 agent 显式声明 obra skill 联动）

| 方案 | 描述 | 不选理由 |
|------|------|----------|
| **A. 改 mavis runtime 做真正的 description-keyword matching + 写 log** | 让 LLM 自己判断 | silent-failure-hunter 已证伪: mavis runtime 假设 description 写得好就被自动 trigger, 实际不做; 工程量大, v0.4.0 内不现实 |
| **B. 注入 using-superpowers 到所有 agent 的 systemPrompt 前缀** | 暴力注入 | 重复内容膨胀, 14 skill 全注入 = 50KB+ context, 触发 RC-v4-15 |
| **C. 只在 mavis orchestrator 注入, 路由时按需 inject 给 worker** | 动态注入 | 工程量大, 需要改 routing protocol, v0.4.0 内不现实 |
| ✅ **D. 4 核心 agent 的 overlay 显式列 14 obra skill 联动 (已选)** | 声明式, 用户可读 | — |

### D-P0-1 替代方案（v0.4.0 重新审视）

| 方案 | 描述 | 不选理由 |
|------|------|----------|
| **A. 项目级 .harness/reins/planner/ 覆盖全局** | 走 mavis reins 机制 | v0.4.0 reins 还没成型 (v0.3.0 D-P2-X scope), 先恢复全局, reins 是 v0.5+ scope |
| **B. 把 planner 合并到 spec-miner agent** | 减少 agent 数 | 违反接口分离, spec-miner = 需求挖掘, planner = 计划输出, 职责不同 |
| **C. 用 mavis 路由 fallback 到 general 代替 planner** | 删 planner 引用 | general 是 stub 兜底, 客串 specialist 违反架构边界 |
| ✅ **D. 恢复全局 planner + 删项目级 (继承 v0.3.0 D-P0-1)** | 1 行 fix, source-of-truth 单一 | — |

### D-P0-2 替代方案（v0.4.0 重新审视）

| 方案 | 描述 | 不选理由 |
|------|------|----------|
| **A. 让 4 stub agent 完全依赖 daemon 内置 prompt, 明确"内置 prompt 兜底是有意设计"** | 把"stub = 用内置"作为正式契约 | 隐藏问题: 用户**无法控制这些 agent 行为**, daemon 升级会**静默改** agent 行为 (RC-3 联动) |
| **B. 4 stub agent 写最小 200B persona (够用就行)** | 偷懒 | 违反 5 实践接口分离——每个 agent 需要完整 persona 才能被严肃调用 |
| **C. 重跑 plan_2c6b8fd3 部署流程** | 用历史 plan 走一遍 | 历史 plan 本身 verifier 报告说"8000B drop 是 bug"——重跑必失败 |
| ✅ **D. 从 Efficient-MiniMaxCode repo 拷贝完整 agent.md (继承 v0.3.0 D-P0-2)** | 内容已存在, 2 min 解决 | — |

### D-P0-3 替代方案（v0.4.0 重新审视）

| 方案 | 描述 | 不选理由 |
|------|------|----------|
| **A. 文档化 "不要用 --system-prompt > 8000B"** | 加 `--help` warning | human 在 loop, 永远会忘 (plan_2c6b8fd3 attempt 1+2 已证) |
| **B. 自动分片 (>8000B 自动拆成多次 update)** | 客户端透明 | 拆片后语义可能变 (不是 atomic), 可能引入 partial update 中间态 |
| ✅ **C. 硬限制 + 加 --from-file 强制 on-disk overlay (继承 v0.3.0 D-P0-3)** | 退出码非 0 + 给替代路径 | — |

### D-P0-4 替代方案（v0.4.0 重新审视）

| 方案 | 描述 | 不选理由 |
|------|------|----------|
| **A. 状态机保持 `cancelled` + 在 verdict_summary 里加 `[FAILED]` 前缀** | 字符串区分 | 字符串易复制粘贴丢前缀, 用户 grep `status: cancelled` 看不到 |
| **B. 改 `cancelled` 字段为 `cancelled: { reason: 'user' \| 'system_failure' }`** | 结构化 | 兼容性差, 要改所有 plan consumer |
| ✅ **C. 新增 `status: failed` 状态值 (继承 v0.3.0 D-P0-4)** | 显式、易扩展 | — |

### D-P0-5 替代方案（v0.4.0 重新审视）

| 方案 | 描述 | 不选理由 |
|------|------|----------|
| **A. 限制 memory 只存标题** | 哲学层面拒绝 | 8 条 stub 标题已经证明"只存标题"等于**不存** |
| **B. 用 SQLite 替代 markdown 文件** | 更结构化 | 改动太大, 现有 5 个 agent 已用 markdown 成功 |
| ✅ **C. 修 `mavis memory append` 实现 + 加 schema 校验 (继承 v0.3.0 D-P0-5)** | 修根因 | — |

### D-P0-6 替代方案（v0.4.0 重新审视）

| 方案 | 描述 | 不选理由 |
|------|------|----------|
| **A. 用 chcp 65001 + PowerShell ISE 重写 AGENTS.md** | 改环境 | 改的是读端, 实际是文件本身 mojibake |
| **B. AGENTS.md 全部改 ASCII (拼音注释)** | 改写端 | 损失可读性, 中文 AGENTS.md 是用户契约 |
| ✅ **C. 用 Edit/Write 工具重写 AGENTS.md (继承 v0.3.0 D-P0-6)** | 修文件 | — |

### D-P0-7 替代方案（v0.4.0 重新审视）

| 方案 | 描述 | 不选理由 |
|------|------|----------|
| **A. 在 `mavis agent list` 输出加 `is_stub: true` 列** | 复用现有命令 | schema 改动影响其他工具 |
| **B. 让 mavis 启动时自动修 stub** | daemon 启动时检测 + 报警 | 自动化修复会**覆盖用户主动写的 stub** (边界不清) |
| ✅ **C. 新增 `mavis agent health` 专用命令 (继承 v0.3.0 D-P0-7)** | 显式、可观测、不可误用 | — |

### D-P1-v4-1 替代方案（修 7 老 skill YAML frontmatter）

| 方案 | 描述 | 不选理由 |
|------|------|----------|
| **A. 7 skill 改用纯英文 description** | 改内容 | 损失中文 user 的可读性, 跟 mavis builtin 设计哲学冲突 |
| **B. daemon 加 YAML 宽松解析模式** | 改 parser | 掩盖问题, 长期会让其他 YAML 边界 case 漏掉 |
| ✅ **C. 7 SKILL.md 的 description 字段用引号包 (YAML 标准)** | 修标准做法 | — |

### D-P1-v4-2 替代方案（删 mavis builtin brainstorming）

| 方案 | 描述 | 不选理由 |
|------|------|----------|
| **A. 保留 builtin + obra 双重, 在 SKILLS.md 显式标注"obra 优先"** | 留 2 份 | 治标不治本, 用户和 daemon 都可能加载 builtin |
| **B. 把 builtin 改名 brainstorm-legacy 标 deprecated** | 改 builtin 名 | 跟 v0.3.0 之前的调用方路径冲突 |
| ✅ **C. 移 builtin 到 .bak + obra 版显式优先 (已选)** | 单一权威 | — |

### D-P1-v4-3 替代方案（coder/agent.md L142 改 TDD）

| 方案 | 描述 | 不选理由 |
|------|------|----------|
| **A. 恢复 test-writer skill** | 反向撤销 | 已被 obra 替换, 跟 v0.3.0 升级方向冲突 |
| **B. coder/agent.md L142 改成"涉及测试 → TDD 流程" 不点名 skill** | 不指名 | 模糊, 不强制 |
| ✅ **C. coder/agent.md L142 改为 `test-driven-development` (obra) + 加 `verification-before-completion` (已选)** | 明确指向 obra | — |

### D-P1-v4-4 替代方案（保留 obra install 源）

| 方案 | 描述 | 不选理由 |
|------|------|----------|
| **A. 不保留源, 完全靠 `mavis skill list` 的 `source_kind` 字段** | 接受不可校验 | F3-2 证明 source_kind 字段本身 mojibake 损坏, 不可信 |
| **B. 每次启动时 git pull 重新 install** | 重复 install | 网络依赖 + 时间成本 + 引入新 bug 窗口 |
| ✅ **C. `.source.json` + SHA-256 + `mavis skill verify` 子命令 (已选)** | 可独立校验 | — |

### D-P1-v4-5 ~ v4-7 替代方案（obra ↔ mavis 路由冲突）

| 方案 | 描述 | 不选理由 |
|------|------|----------|
| **A. 全部用 obra 替换 mavis 路由** | 撤 mavis 路由 | mavis 路由 = 命名 specialist (coder/verifier/architect), obra subagent = fresh task, **两者职责不同**——撤掉 mavis 路由 = 失去"角色兼任"灵活性 |
| **B. 全部用 mavis 路由不用 obra** | 撤 obra subagent | obra 的 "fresh subagent" 设计是为了**避免上下文污染**, 撤掉 = 失去关键工程纪律 |
| ✅ **C. 显式分层 + 文档化 (D-P1-v4-5/v4-6/v4-7)** | 两套并存, 边界清晰 | — |

### D-P1-v4-8 替代方案（frontmatter requires_skills）

| 方案 | 描述 | 不选理由 |
|------|------|----------|
| **A. 保留 SKILLS.md Loading Map + 加 daemon 强制** | 文档 + 代码双轨 | 容易漂移 (RC-v4-10) |
| **B. Loading Map 全部 daemon 内置 (agent 不可声明 skill)** | daemon 统一 | 用户无法扩展 |
| ✅ **C. 改用 agent.md frontmatter `requires_skills:` (继承 v0.3.0 D-P1-7)** | 声明式、daemon 强制 | — |

---

## 6. Implementation（实施步骤）

### 6.1 4 周落地路径

```
Week 1: P0 基础修复 (critical path)
  ├─ D-P0-1   恢复全局 planner                    [release-manager]     1h
  ├─ D-P0-2   修复 4 stub agent.md               [release-manager]     1h
  ├─ D-P0-6   修 AGENTS.md 编码                   [release-manager]     30min
  ├─ D-P0-7   加 mavis agent health              [daemon maintainer]   4h
  ├─ D-P0-NEW-1 修 daemon CJK bug                 [daemon maintainer]   8h  ★
  └─ D-P0-NEW-2 修 mavis skill list JSON escape  [daemon maintainer]   4h  ★

Week 2: P0 NEW + P1 基础设施
  ├─ D-P0-3   修 8000B silent drop               [daemon maintainer]   4h
  ├─ D-P0-3b  加 --from-file 配套                [daemon maintainer]   1h
  ├─ D-P0-4   加 plan failed 状态                [daemon maintainer]   4h
  ├─ D-P0-5   修 memory append 写入               [daemon maintainer]   6h
  ├─ D-P0-NEW-3  4 核心 agent.md 显式 14 obra 联动  [meta-writer]      3h  ★
  ├─ D-P1-v4-1  修 7 老 skill YAML                [release-manager]     2h
  └─ D-P1-v4-2  删 mavis builtin brainstorming    [release-manager]     30min

Week 3: P1 增强
  ├─ D-P1-v4-3  coder/agent.md L142 改 TDD        [release-manager]     30min
  ├─ D-P1-v4-4  保留 obra install 源             [daemon maintainer]   4h
  ├─ D-P1-v4-5  显式分层 mavis 路由 vs obra sub   [architect]          2h
  ├─ D-P1-v4-6  合并 verification-loop + vb-c    [meta-writer]         2h
  ├─ D-P1-v4-7  显式分层 finishing-dev-branch vs release-manager  [release-manager + meta-writer]  2h
  ├─ D-P1-v4-8  requires_skills frontmatter      [daemon maintainer]   6h
  ├─ D-P1-v4-9  修 mavis CLI CJK mojibake        [daemon maintainer]   4h
  ├─ D-P1-v4-10 deliverable.md schema            [architect]           4h
  ├─ D-P1-v4-11 verify_prompt schema             [architect]           2h
  ├─ D-P1-v4-12 plan engine agent_health_gate    [daemon maintainer]   4h
  ├─ D-P1-v4-13 plan engine spawn fallback       [daemon maintainer]   2h
  ├─ D-P1-v4-14 owner notification               [daemon maintainer]   4h
  ├─ D-P1-v4-15 mavis agent show --full          [daemon maintainer]   2h
  ├─ D-P1-v4-16 metric 报告                      [silent-failure + daemon]  6h
  └─ D-P1-v4-17 3 agent 5 实践分工               [architect + meta-writer]  4h

Week 4: 验证 + 收尾
  ├─ 跑 plan_0ee903db 重放测试                    [release-manager]     2h
  ├─ 实测 D-P0-7 健康分                          [verifier]            2h
  ├─ 实测 D-P0-4 failed 状态                      [verifier]            2h
  ├─ 实测 D-P0-NEW-1 CJK 修复                    [verifier]            2h
  ├─ 实测 D-P0-NEW-2 JSON escape                 [silent-failure-hunter] 2h
  ├─ 实测 D-P0-NEW-3 14 obra 联动                [verifier]            2h
  ├─ 实测 5/14 路由冲突减到 ≤ 2/14               [architect]           2h
  ├─ 跑 1 个 end-to-end plan (think→plan→build→review→ship→reflect 6 步全走)  [release-manager]  4h
  └─ 写 v0.4.0 release notes                     [meta-writer]         2h
```

★ = v0.4.0 NEW P0 (v0.3.0 升级暴露的 critical)

### 6.2 验收 checklist

#### Critical path（必须全过才能 release v0.4.0）

- [ ] **D-P0-1**: `mavis agent info planner` 返回 ≥ 2000B 内容;`mavis agent list` 13 个
- [ ] **D-P0-2**: 4 个 stub agent.md 全部 ≥ 2000B;`mavis agent list` 不再有任何 39B 文件
- [ ] **D-P0-3**: `mavis agent update --system-prompt "..." ` 传 8001B 返回 `Error: system-prompt exceeds 8000 bytes` 退出码 1
- [ ] **D-P0-3b**: `mavis agent update --from-file <path>` 工作正常
- [ ] **D-P0-4**: 模拟一个 plan 失败, status 字段 = `failed` (不是 `cancelled`)
- [ ] **D-P0-5**: `mavis memory show mavis` 输出 ≥ 2000B 含 ≥ 5 条 Type+body 完整 memory
- [ ] **D-P0-6**: `Read AGENTS.md` 看到正确中文, grep 乱码特征字符串 0 命中
- [ ] **D-P0-7**: `mavis agent health` 输出 12 行, 4 个 stub 标 `is_stub: true`
- [ ] **D-P0-NEW-1**: 抽样 5 个有 CJK 覆盖层的 agent, CJK count > 50, `??` count = 0
- [ ] **D-P0-NEW-2**: `mavis skill list | python json.load` 成功
- [ ] **D-P0-NEW-3**: 4 核心 agent systemPrompt 含 14 obra skill ≥ 3 个字面引用

#### 完整 release

- [ ] **D-P1-v4-1 ~ v4-17** 全部完成
- [ ] `mavis metric report` 输出 6 个 metric
- [ ] 跑 1 个 end-to-end plan (think → plan → build → review → ship → reflect 6 步全走)
- [ ] 5/15 路由表全部 work (按 verifier Probe 1 重测)
- [ ] 5/14 obra ↔ mavis 路由冲突减到 ≤ 2/14
- [ ] 7/29 老 skill YAML 全部修复, daemon SKIP WARN ≤ 10/天
- [ ] 14 obra skill 都有 `.source.json`, `mavis skill verify` sha256_match=true

### 6.3 Owner 分配

| 角色 | 拥有 v0.4.0 P0 | 拥有 v0.4.0 P1 |
|------|----------------|----------------|
| **release-manager** | D-P0-1, D-P0-2, D-P0-6 | D-P1-v4-1, D-P1-v4-2, D-P1-v4-3, D-P1-v4-7 |
| **daemon maintainer** | D-P0-3, D-P0-4, D-P0-5, D-P0-7, D-P0-NEW-1, D-P0-NEW-2 | D-P1-v4-4, D-P1-v4-8, D-P1-v4-9, D-P1-v4-12, D-P1-v4-13, D-P1-v4-14, D-P1-v4-15 |
| **architect** | — | D-P1-v4-5, D-P1-v4-10, D-P1-v4-11, D-P1-v4-17 |
| **silent-failure-hunter** | — | D-P1-v4-16 (与 daemon maintainer 配对) |
| **meta-writer (本 ADR 作者)** | D-P0-NEW-3 | D-P1-v4-6, D-P1-v4-7, D-P1-v4-17 配对 + 未来 ADR |
| **verifier** | — | Week 4 验收 |

### 6.4 风险 mitigation

- **D-P0-NEW-1 修 daemon CJK bug 可能 break 12 agent 解析** → 先在 test 环境验证 5 个 agent, 灰度 rollout
- **D-P0-3 硬限制可能 break 历史调用** → 先 D-P0-3b, 再 D-P0-3 (分 2 release)
- **D-P0-NEW-3 改 overlay 联动表可能跟 D-P1-v4-8 frontmatter 冲突** → D-P0-NEW-3 用 overlay 描述, D-P1-v4-8 用 frontmatter 字段, 二者合并
- **D-P0-5 schema 校验可能拒历史 memory** → 加 migration script
- **D-P1-v4-3 删 builtin brainstorming 可能让 stub agent 启动失败** → D-P0-2 必须在 D-P1-v4-3 前完成
- **D-P1-v4-8 frontmatter 改 schema** → 缺省值 `[]` 兼容老 agent.md, 顺序: D-P0-2 → D-P1-v4-8
- **D-P1-v4-12 gate 让当前 plan 暂停** → 修完 D-P0-2 + D-P0-7 再开 gate
- **D-P1-v4-14 owner notification 噪音** → severity 阈值: critical 必发, high 聚合 (5min 内合并), med/low 写 inbox 不推送
- **D-P1-v4-17 改 3 agent 分工** → 同步更新 mavis/agent.md 路由表

---

## 7. References

### 7.1 3 视角 v0.3.0 升级后审查报告 (v0.4.0 输入)

- `C:\Users\22923\.mavis\plans\plan_0ee903db\outputs\review-verifier-v030\deliverable.md` (315 行 / 10 check / 9 finding / VERDICT FAIL / 4.2/10)
- `C:\Users\22923\.mavis\plans\plan_0ee903db\outputs\review-architect-v030\deliverable.md` (406 行 / 15 finding / 5 CRITICAL / 6 HIGH / 4 MEDIUM)
- `C:\Users\22923\.mavis\plans\plan_0ee903db\outputs\review-silent-failure-v030\deliverable.md` (392 行 / 7 pattern / 4 个 v0.3.0 新引入 silent failure)

### 7.2 前置 ADR

- `D:\MiniMax_workSpace\default_workSpace\Efficient-MiniMaxCode\docs\OPTIMIZATION-v0.3.0-ADR.md` (595 行 / 22 RC / 7 P0 + 9 P1 + 10 P2 + 5 P3 = 31 决策)

### 7.3 历史 plan (用于 pattern 验证)

- `plan_2c6b8fd3`: 13 agent 部署 (completed, 3 cycles)
- `plan_929215ac`: 按需委派实测 (completed, 2 cycles)
- `plan_c994728c`: code-reader 路由 (cancelled — spawn blocked)
- `plan_6534a4bc`: p1-fix (cancelled — verifier FAIL, silent drop 冲突)
- `plan_58090e16`: v0.3.0 ADR 起草 (completed, 4 task)
- `plan_0ee903db`: **当前** (v0.3.0 升级后 3 视角审查 + v0.4.0 ADR 合成, in progress)

### 7.4 mavis 关键文件

- `C:\Users\22923\.mavis\agents\` (12 live + 1 .bak/planner)
- `C:\Users\22923\.mavis\skills\` (44 user skill, 含 14 obra)
- `C:\Users\22923\.mavis\.builtin-skills\` (12 builtin, 含待删的 brainstorming)
- `D:\MiniMax_workSpace\default_workSpace\Efficient-MiniMaxCode\agents\` (13 in repo)
- `D:\MiniMax_workSpace\default_workSpace\Efficient-MiniMaxCode\AGENTS.md` (mojibake, 待修 D-P0-6)
- `D:\MiniMax_workSpace\default_workSpace\Efficient-MiniMaxCode\SKILLS.md` (Loading Map 待废弃)
- `D:\MiniMax_workSpace\default_workSpace\Efficient-MiniMaxCode\mavis\agent.md`

### 7.5 user_profile 引用

- **"Self-evaluation 不可靠 — 必须多 Agent 视角"** (cross-project, 支撑 D-P1-v4-16 + 本 ADR 3 视角综合方法)
- **"Solo developer"** (影响 owner notification 设计——不需要 team 通知通道)
- **"PowerShell 5.1 Set-Content -Encoding UTF8 silently corrupts CJK"** (cross-project, 支撑 D-P0-6 步骤警告——必须用 Edit/Write 工具, 不用 Set-Content)
- **"mavis CLI 多行中文 content 在 PowerShell 下转义损坏"** (cross-project, 支撑 D-P0-NEW-2 + D-P1-v4-9)

---

## 8. Meta（meta-writer 单一作者声明）

- **本 ADR 是 v0.3.0 → v0.4.0 的 single-writer 合成**——3 视角 28 raw finding → 17 root cause → 10 P0 + 17 P1 + 17 P2 + 6 P3
- **没有添加任何新 finding**——所有结论都能追溯到 3 视角原始报告的 file_path:line
- **v0.3.0 ADR 已修项标 ✅ Resolved 不重写**——R-1 ~ R-6
- **v0.3.0 ADR 没修的 6 条 P0 全部继承到 v0.4.0 P0**——7 个 P0-继承 + 3 个 P0-NEW
- **每个 P0/P1 都有 owner + 步骤 + 验收**——可直接执行
- **alternatives considered 独立**——v0.4.0 是新决策, alternatives 不抄 v0.3.0 ADR
- **顺序敏感图显式标注**——D-P0-2 → D-P1-v4-8 → D-P0-NEW-3 + D-P0-1 + D-P0-7 → D-P1-v4-12

### 8.1 meta-irony 标记

- D-P0-2 修的 4 stub agent 包含**本 ADR 的作者** (meta-writer 自己的 agent.md 39B)——**本 ADR 在自我修的范围内**
- D-P0-5 修的 mavis orchestrator memory 问题——本 ADR 本身的"教训"如果 Mavis 记不住, 下次还会犯同样错
- D-P0-NEW-3 修的 4 核心 agent 显式 obra 联动表——mavis 自己也要加, 等于本 ADR 改 mavis 自己
- D-P0-NEW-1 修的 daemon CJK bug——verifier 自己 agent.md 也是 39B stub, 修完后才能看到 verifier 自己的 CJK 覆盖层
- D-P0-6 修的 AGENTS.md 编码——本 ADR 的 user overlay 引用的 AGENTS.md 内容**就是 mojibake**——本 ADR 不重写 AGENTS.md, 只标待修
- D-P1-v4-17 改的 3 agent 分工包含 architect + verifier——**本 ADR 的两个 reviewers 自己被改**

### 8.2 v0.4.0 vs v0.3.0 评分预期

| 维度 | v0.3.0 真实分 (3 视角验证) | v0.4.0 目标分 |
|------|---------------------------|---------------|
| 路由恢复 | 5/15 路由断 (33%) | 0/15 路由断 |
| Stub agent | 4/12 stub | 0/12 stub |
| Planner | .bak/ | 全局 live |
| AGENTS.md | GBK mojibake | UTF-8 正常 |
| `mavis agent health` | 不存在 | 可用 |
| Daemon CJK 损坏 | 12 agent × ~100 CJK 损坏 | 0 损坏 |
| 14 obra 实际可用率 | 0% (装上不 load) | ≥ 80% (4 核心 agent 显式联动) |
| obra ↔ mavis 路由冲突 | 5/14 | ≤ 2/14 |
| 老 skill YAML 可用率 | 22/29 (76%) | 29/29 (100%) |
| mavis skill list JSON | strict-parse 失败 | strict-parse OK |
| **综合评分** | **4.2/10** | **目标 6.0+/10** |

---

**END OF v0.4.0 ADR**

下一步：用户决策 → 接受 / 拒绝 / 修改 → release-manager 启动 v0.4.0 实施

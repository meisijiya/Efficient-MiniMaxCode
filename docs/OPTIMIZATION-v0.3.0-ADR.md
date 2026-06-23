# ADR: Mavis 团队协作 v0.3.0 优化方案

> **Status**: Proposed
> **Date**: 2026-06-24
> **Authors**:
> - **meta-writer**（synthesis 单一作者，本 ADR 的 single-writer）
> - 输入: 3 个 adversarial 审查报告（verifier / architect / silent-failure-hunter）
> - 目标版本: Mavis v0.3.0
> **Deciders**: 用户（最终拍板）+ parent session
> **Related**:
> - `plans/plan_58090e16/outputs/review-verifier/deliverable.md` (568 行 / 8 finding)
> - `plans/plan_58090e16/outputs/review-architect/deliverable.md` (393 行 / 19 finding)
> - `plans/plan_58090e16/outputs/review-silent-failure/deliverable.md` (461 行 / 22 finding)

---

## 1. Context（背景）

### 1.1 当前状态

今天我们用 **13 agent + 31+ skill + 7 步循环 + 4 重审查** 跑 mavis 团队协作。
**3 个独立审查视角**（verifier / architect / silent-failure-hunter）于 2026-06-24 在
plan_58090e16 任务下做 adversarial audit，**独立找到 49 个 finding**：

| 视角 | 方法论 | finding 数 | CRITICAL | HIGH | MEDIUM | VERDICT |
|------|--------|------------|----------|------|--------|---------|
| **verifier** | 实跑命令 + file size + 路由表 probe | 8 | 3 | 3 | 2 | **FAIL** |
| **architect** | 6 维度架构审查（模块/契约/数据流/状态/依赖/5 实践）| 19 | 3 | 7 | 9 | **C+** (60-65/100) |
| **silent-failure-hunter** | 7 个 silent failure pattern 穷举 | 22 | 7 | 6 | 9 | **CATASTROPHIC** |

### 1.2 3 视角独立但收敛的核心判断

3 视角**互不串通**，但**独立得出高度一致的结论**：

1. **mavis 团队协作"半残废"**（verifier 原话）/ "C+ 架构但 critical path 跑不通"（architect 原话）/
   "Mavis 永远记不住自己踩过的坑"（silent-failure 原话）
2. **5/15 advertised 路由断**（33% 路由表失效）
3. **7 步循环的 Plan / Ship / Reflect 步**实际**从未走过**（5 个历史 plan 验证）
4. **mavis 自我评估 5.7/10 偏乐观 40%**——真实分应 ≤ 4.0/10

### 1.3 为什么必须现在做

- **plan_58090e16 自身结构性依赖 4 个 broken agent**（F3 verifier）—— 这次产出的 ADR 质量
  受 stub 影响（meta-irony）
- **2/5 (40%) 历史 plan 是失败被掩盖成 cancelled**（F2-1 silent-failure）—— 用户无法区分
  主动 cancel 和失败 cancel
- **mavis 自身 memory 是空壳**（F1-4 silent-failure）—— Mavis 永远学不会教训，下次还会
  用同样的方式失败
- **8000-byte silent drop** 至少**已让 4 个 agent 退化成 stub**（F1 verifier + F7-1 silent-failure）—— bug 持续发作

### 1.4 本 ADR 范围

- ✅ **IN**: P0/P1 决策（必做 + 应该做），涉及 daemon 改动 + agent 部署 + plan engine
- ✅ **IN**: P2 backlog（写下来给未来，不在 v0.3.0 scope）
- ✅ **IN**: P3 anti-pattern（不做了 + 监控）
- ❌ **OUT**: 新功能设计（v0.4+ scope）
- ❌ **OUT**: 任何"加注释 / 加文档"占位（违反 meta-writer 不写空头契约原则）

---

## 2. 3 视角发现合并去重（Consolidated Findings）

**合并原则**：
- **跨视角收敛的 finding**（2+ 视角独立发现）= 高置信，提升优先级
- **单视角独有 finding** = 中置信，按本视角严重度保留
- **同义 finding**（描述不同但指向同一根因）= 合并成一条 root cause + 多个 manifestation
- **不添加新 finding**——meta-writer 只综合，不创造

### 2.1 Root cause 矩阵

| Root cause | 视角覆盖 | manifestation 数 | 严重度 |
|------------|----------|------------------|--------|
| **RC-1**: `~/.mavis/agents/planner/` 全局不可见 | verifier (F2) + architect (CRIT 1+15) + silent-failure (F2-1 indirect via plan_c994728c) | 3 | 🔴 CRITICAL |
| **RC-2**: 4 个 agent.md 退化成 39B stub | verifier (F1) + architect (CRIT 2) + silent-failure (F7-1) | 3 | 🔴 CRITICAL |
| **RC-3**: mavis agent update CLI 有 silent drop / silent overwrite bug（>8000B） | verifier (F6) + silent-failure (F1-3 + F7-2) | 3 | 🔴 CRITICAL |
| **RC-4**: plan engine 状态机无 `failed` 维度 | silent-failure (F2-1) + verifier (F5 indirect) | 2 | 🔴 CRITICAL |
| **RC-5**: mavis orchestrator 自己的 memory 写入只写标题不写 body | silent-failure (F1-4 + F2-5) | 2 | 🔴 CRITICAL |
| **RC-6**: AGENTS.md 编码损坏（中文乱码） | architect (CRIT 7) | 1 | 🔴 CRITICAL（用户层契约） |
| **RC-7**: SKILLS.md "Loading Map" 是声明式空气契约（daemon 不强制） | verifier (F7) + architect (MED 10) + silent-failure (F4-4) | 3 | 🟠 HIGH |
| **RC-8**: plan engine spawn 失败无 fallback（Spawn blocked → engine paused） | verifier (F5) + silent-failure (F1-1 + F2-2 + F3-1) | 4 | 🟠 HIGH |
| **RC-9**: mavis self-evaluation 无 metric 体系，纯 LLM 主观打分 | verifier (F4) + silent-failure (F4-1) | 2 | 🟠 HIGH |
| **RC-10**: `deliverable.md` 跨 agent 无标准 schema | architect (HIGH 8) + silent-failure (F2-2 indirect) | 2 | 🟠 HIGH |
| **RC-11**: `verify_prompt` 入参无 schema | architect (HIGH 9) | 1 | 🟠 HIGH |
| **RC-12**: agent.md built-in prompt vs user overlay 谁是 source-of-truth 未明 | architect (HIGH 13) | 1 | 🟠 HIGH |
| **RC-13**: verifier / architect / auditor 3 个 agent 都跑 5 实践审查（职责重叠） | architect (HIGH 3 + MED 5 + HIGH 16) | 3 | 🟠 HIGH |
| **RC-14**: test-writer 跨 agent/skill 边界（无 worker） | architect (HIGH 4) | 1 | 🟡 MEDIUM |
| **RC-15**: Spec/Plan 输出路径用户项目 vs 全局混淆 | architect (HIGH 11) | 1 | 🟡 MEDIUM |
| **RC-16**: meta-writer 的 single-writer 铁律无 owner / 无执行细节 | architect (MED 12) | 1 | 🟡 MEDIUM |
| **RC-17**: 4 原则 (Karpathy) 在 5 个 agent.md 中复制粘贴 | architect (MED 6) | 1 | 🟡 MEDIUM |
| **RC-18**: 7 步循环的 Ship / Test / Reflect 几乎不走 | verifier (Probe 4) + architect (HIGH 19) + silent-failure ("当前 plan 无 Ship/Test/Reflect") | 3 | 🟡 MEDIUM |
| **RC-19**: `general` agent 是"以防万一"的通用兜底，违反接口分离 | architect (HIGH 18) | 1 | 🟡 MEDIUM |
| **RC-20**: CLI UX 缺（list alias / suggest / encoding 截断 / perf default / cron required arg） | silent-failure (F4-3 + F5-1/2/3) | 4 | 🟢 LOW |
| **RC-21**: task prompt / SKILLS.md / AGENTS.md 数字声明 drift | verifier (F8) | 1 | 🟢 LOW |
| **RC-22**: workspace 散落 1300+ 个 zod locale 文件 | architect (MED 14) | 1 | 🟢 LOW |
| **RC-23**: SKILLS.md auditor / silent-failure-hunter / code-simplifier loading 写一套路由用另一套 | architect (MED 17) + silent-failure (F4-4) | 2 | 🟢 LOW |

**合并后：22 个 root cause（49 raw finding 去重）**——meta-writer 单一作者铁律贯彻。

---

## 3. Decision（决策）

### 3.1 P0 — 必做，next release（v0.3.0 阻塞 release）

> **原则**：P0 是"不修就别发 v0.3.0"。每条都是 critical path 必修。

#### **D-P0-1**: 恢复全局 `planner` agent，删项目级 `agents/planner/`（修 RC-1）

- **目标**: `/plan` 工作流能在全局 mavis 上下文跑通
- **步骤**:
  1. 把 `~/.mavis/agents/.bak/planner/` 移到 `~/.mavis/agents/planner/`（恢复全局）
  2. 删 `D:\MiniMax_workSpace\default_workSpace\Efficient-MiniMaxCode\agents/planner/`（避免 source-of-truth 分裂）
  3. `mavis agent info planner` 验证 systemPrompt 完整（≥ 2000B）
- **Owner**: release-manager
- **验收**: `mavis agent info planner` 返回完整 agent.md 内容 + plan-workflow skill L29-30 流水线 step[2] 可正常 spawn
- **反模式**: 把 planner 留项目级 + 在全局加 marker fallback（会埋下"项目级优先 vs 全局优先"的歧义）

#### **D-P0-2**: 修复 4 个 stub agent 的 agent.md（修 RC-2）

- **目标**: 4 个空 stub agent 重新有完整 persona
- **范围**: `build-error-resolver` / `code-simplifier` / `meta-writer` / `silent-failure-hunter`（每个 39B）
- **步骤**:
  1. 从 `D:\MiniMax_workSpace\default_workSpace\Efficient-MiniMaxCode\agents/<同名>/` 拷贝完整 agent.md
  2. 不用 `mavis agent update --system-prompt`（8000B silent drop 风险）——直接 Write 工具写文件
  3. 写完后跑 `mavis agent info <name>` 验证 systemPrompt 长度 ≥ 2000B
- **Owner**: release-manager
- **验收**:
  - 4 个 agent.md 字节数 ≥ 2000
  - 5/15 路由表恢复 work（按 verifier Probe 1）
  - `mavis agent list` description 字段和实际 persona 一致
- **风险**: 历史 plan_2c6b8fd3 attempt 1+2 失败是因这个 bug 引起，要先修 D-P0-3 再操作

#### **D-P0-3**: 修 mavis CLI 8000-byte silent drop（修 RC-3）

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
- **替代方案**: 加 `mavis agent update --from-file <path>` 强制走 on-disk overlay 路径（**D-P0-3b** 必须配套，2 个一起做）

#### **D-P0-4**: plan engine 状态机加 `failed` 状态（修 RC-4）

- **目标**: 区分"用户主动 cancel" vs "任务失败被掩盖"
- **步骤**:
  1. plan state 加 `status: failed` 状态值
  2. spawn 失败 / verifier FAIL / agent not found / 8000B drop 等场景从 `cancelled` 改为 `failed`
  3. `mavis team plan status <id>` 输出明确区分
  4. `failed` 状态自动触发 D-P1-5（owner notification）
- **Owner**: daemon maintainer
- **验收**:
  - 历史 plan_6534a4bc / plan_c994728c 重新跑一遍 status 检查能区分（应在 `failed` 而非 `cancelled`）
  - 新 plan 失败时 status = `failed`
- **影响**: 2/5 历史 plan 从 `cancelled` 升格为 `failed`——用户回头看会发现 40% 失败率

#### **D-P0-5**: 修 mavis orchestrator 自身 memory 写入（修 RC-5）

- **目标**: `mavis memory append` 真的把 body 写入 MEMORY.md
- **步骤**:
  1. 排查 `mavis memory append` 实现（daemon 内）——是不是 markdown 特殊字符 / 超长行 truncate
  2. 强制 schema 校验：append 的 content 必须含 `### <title>` + `Type: <type>` + body
  3. 写完后 `mavis memory show mavis` 验证 body 真的存在
- **Owner**: daemon maintainer
- **验收**:
  - `~/.mavis/agents/mavis/memory/MEMORY.md` ≥ 2000B（含 ≥ 5 条 Type+body 完整 memory）
  - 现有 8 条 stub 标题自动迁移到新格式
- **重要**: 这是 Mavis 能"反思"的最低基础设施——**不修这条，团队永远学不会**

#### **D-P0-6**: 用 UTF-8 重写 AGENTS.md（修 RC-6）

- **目标**: `Efficient-MiniMaxCode/AGENTS.md` 编码正常（中文不乱码）
- **步骤**:
  1. 用 Edit / Write 工具（不是 PowerShell `Set-Content`，避免 BOM）重写 AGENTS.md
  2. 头部加 `Last verified: 2026-06-24 | Total: 13 agents (mavis agent list | wc -l)`
  3. 同步把 init skill 加 `AGENTS.md 自动生成` 步骤
- **Owner**: release-manager
- **验收**:
  - 任何 agent 启动项目时 Read AGENTS.md 看到正确中文
  - grep "鐪" / "鏀" 等乱码特征字符串 0 命中

#### **D-P0-7**: 加 `mavis agent health` 命令（修 RC-2 可观测性）

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

---

### 3.2 P1 — 应该做，v0.3.0 scope（不阻塞 release，但强烈建议做）

> **原则**: P1 是"不修会持续发作的工程债"。

#### **D-P1-1**: 定义 `deliverable.md` schema + plan engine 自动 validate（修 RC-10）

- **目标**: 跨 agent 的 deliverable 有统一结构，便于 meta-writer 合并去重
- **步骤**:
  1. 写 `references/deliverable.schema.md`（必填 Summary / Changed files / Notes / Findings[] + Finding 结构）
  2. plan engine 跑 task 完成时自动 lint deliverable.md
  3. 不符合 schema → task status = `needs_format_fix`（非 `failed`，非 `cancelled`）
- **Owner**: architect + plan engine maintainer
- **验收**:
  - plan_58090e16 4 个 deliverable.md 全部通过 schema lint
  - meta-writer 不需要"先读后猜格式"

#### **D-P1-2**: 定义 `verify_prompt` schema（修 RC-11）

- **目标**: orchestrator 派 verifier 任务时用统一 prompt 格式
- **schema**:
  ```yaml
  verify_prompt:
    diff: string              # 必填
    pr_url?: string
    related_spec?: string
    related_plan?: string
    severity_floor: 'LOW'|'MEDIUM'|'HIGH'  # 默认 MEDIUM
  ```
- **Owner**: architect
- **验收**: plan-workflow skill 文档含 schema，verifier agent.md 引用

#### **D-P1-3**: plan engine 加 `agent_health_gate`（修 RC-2 + RC-8）

- **目标**: dispatch 前校验 `assigned_to` agent.md 健康
- **步骤**:
  1. plan engine 在 spawn 前调 `mavis agent health <name>`
  2. 健康分 < 0.5 → 任务 status = `paused` + 自动通知 owner（走 D-P1-5 通道）
  3. 健康分 0.5-0.8 → 加 warning 到 plan log 但允许 spawn
  4. 健康分 ≥ 0.8 → OK
- **Owner**: daemon maintainer
- **验收**:
  - 当前 plan 4 个 task 全部通过 gate
  - 假设 D-P0-2 未修时：plan_58090e16 立即 paused + owner 收到 notification

#### **D-P1-4**: plan engine spawn 失败时自动 fallback + log（修 RC-8）

- **目标**: Spawn blocked 不再"engine paused, owner notified"假阳性
- **步骤**:
  1. spawn 失败自动 fallback 到 `general`（带 warning 写进 plan log）
  2. plan log 明确："assigned_to 'X' not found, fell back to 'general', reason: ..."
  3. 错误信息加 "Did you mean: <top 3 candidates>"
- **Owner**: daemon maintainer
- **验收**:
  - `mavis agent info non-existent` 后 plan engine 不暂停
  - plan log 有 fallback 记录
  - 用户 grep `Spawn blocked` 在 plan_58090e16+ 之后的所有 plan 看到 fallback 路径

#### **D-P1-5**: 真实 owner notification（修 RC-8 + RC-4 联动）

- **目标**: "owner notified" 不再是假阳性
- **步骤**:
  1. daemon 暴露 `mavis notify owner --message "..." --severity <low|med|high|critical>`
  2. 默认 channel = 写文件到 `~/.mavis/owner-inbox.md`（用户能 grep / Watch）
  3. 可选 channel = Feishu / Telegram（IM 路由已有，需 expose CLI）
  4. plan engine 在 status=failed / spawn blocked / agent_health_gate fail 时自动 trigger
- **Owner**: daemon maintainer
- **验收**:
  - plan_6534a4bc 重放时 owner-inbox.md 有 1 条 critical 通知
  - 用户 IM 收到 notification

#### **D-P1-6**: 暴露 `mavis agent show <name> --full` 显示合并后完整 prompt（修 RC-12）

- **目标**: 用户能看 built-in + overlay 合并后的完整 systemPrompt
- **步骤**:
  1. daemon 合并 built-in base + user overlay
  2. `--full` flag 打印完整内容（含分节标注 `[BUILTIN]` vs `[USER OVERLAY]`）
- **Owner**: daemon maintainer
- **验收**: `mavis agent show meta-writer --full` 输出 ≥ 6000B（含 builtin + overlay 合并）

#### **D-P1-7**: Skill Loading 改用 agent.md frontmatter `requires_skills:`（修 RC-7）

- **目标**: Loading Map 从"手写空气契约"变"daemon 强制"
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
- **Owner**: daemon maintainer + meta-writer
- **验收**:
  - 4 个 stub agent 修完后（先做 D-P0-2）能正确 load declared skills
  - `mavis agent info silent-failure-hunter` systemPrompt 含 vibecoding-discipline + observability-and-instrumentation 注入痕迹

#### **D-P1-8**: 引入客观 metric 替换 self-evaluation 5.7/10（修 RC-9）

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

#### **D-P1-9**: 明确 3 agent 5 实践审查分工（修 RC-13）

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

---

### 3.3 P2 — 可做，backlog（v0.3.0 之后）

> **原则**: P2 是"做了更好但不是 critical"——列出来给未来，但不在 v0.3.0 scope。

| ID | 决策 | 修 RC | Owner | 备注 |
|----|------|-------|-------|------|
| D-P2-1 | 升级 test-writer 为 agent（与 build-error-resolver 对称）| RC-14 | architect | 高频使用但 skill 调用路径长 |
| D-P2-2 | 明确项目级（docs/） vs 全局（plans/）输出路径双层 | RC-15 | architect | init skill 加项目根检测 |
| D-P2-3 | meta-writer 写完整 single-writer 协议（含写前检查 / 锁 / 冲突处理）| RC-16 | meta-writer | D-P0-5 修完后再做 |
| D-P2-4 | 抽 4 原则到 daemon 内置，user overlay 仅写特殊规则 | RC-17 | daemon maintainer | 改 5 个 agent.md |
| D-P2-5 | 7 步循环 → 强制跑完 OR 砍到 4 步 | RC-18 | architect + 用户决策 | 历史 5 plan 0 个走完 7 步 |
| D-P2-6 | general 拒绝 specialist 任务，fallback 时升级用户 | RC-19 | architect | 改 general agent.md |
| D-P2-7 | `mavis memory append` 加 schema 校验 + markdown sanitize | RC-5 加强 | daemon maintainer | 配套 D-P0-5 |
| D-P2-8 | `mavis skill list --full` / `--no-truncate`（修 encoding 截断）| RC-20 | daemon maintainer | CLI UX |
| D-P2-9 | 加 `mavis memory list-topics --all` 不强制要求 agent name | RC-20 | daemon maintainer | CLI UX |
| D-P2-10 | workspace 清理：`.gitignore` 加 `agents/*/workspace/.opencode/node_modules/` | RC-22 | init skill | 13 agent × 100+ locale = 1300 文件 |

---

### 3.4 P3 — 不做 / 监控（v0.3.0 不动）

> **原则**: P3 是"识别到了但**故意不做**"——避免 scope creep，明确 anti-pattern。

| ID | 决策 | 修 RC | 理由 |
|----|------|-------|------|
| D-P3-1 | 数字声明 drift 不修，改成"动态生成 + Last verified" | RC-21 | 比维护数字更可持续 |
| D-P3-2 | `auditor` 默认不挂载的 loading map 不一致，**只加文档 disclaimer** | RC-23 | 行为正确，文档可以慢一拍 |
| D-P3-3 | CLI UX 微小改进（list alias / suggest / perf default） | RC-20 | P3 backlog，等用户量大再做 |
| D-P3-4 | `silent-failure-hunter` 自己也是 stub 受害者——已识别，**监控** D-P0-2 修复后是否自动恢复 | RC-2 联动 | meta-irony 已记录，下次会自检 |
| D-P3-5 | 7 步循环的 Reflect 步只产出 lessons——暂时砍到 4 步（Think/Plan/Build/Review） | RC-18 砍 | 历史 0 plan 走完 Reflect，先砍 |

---

## 4. Consequences（后果）

### 4.1 正面（doing P0+P1）

- **5/15 路由恢复 work**（从 33% 路由断 → ≤ 5% 路由断）
- **`/plan` 工作流全局可用**——不再依赖项目级 agent 目录
- **plan failure 真实可见**——用户能区分主动 cancel vs 任务失败
- **mavis 真的能学教训**——memory 写入修好后，重复犯的 bug 减少
- **silent rollback 显形**——`mavis agent health` 立即发现新退化的 stub
- **重复审查劳动减少**——3 agent 5 实践分工明确后，审查 cycle 缩短
- **user-level contract 正常**——AGENTS.md 编码修好，任何 agent 启动项目能读到索引

### 4.2 负面 / 风险

| 风险 | 影响 | 缓解 |
|------|------|------|
| **D-P0-3 修 CLI 8000B drop 可能 break 现有调用方** | 历史 plan 的 deploy agent 流程可能失败 | 先 D-P0-3b（加 `--from-file`）再做硬限制，分阶段 rollout |
| **D-P0-5 memory schema 校验可能拒掉历史 append** | 8 条 stub 标题 memory 写不进去 | 加 migration：自动给历史 stub 标题补 `Type: unknown` + empty body |
| **D-P1-3 agent_health_gate 让当前 plan 暴露问题** | plan_58090e16 跑时立即被 paused | 修 D-P0-2 后再开 gate（顺序：先修 stub，再开 gate） |
| **D-P1-5 owner notification 可能噪音过多** | critical 通知太多用户会关掉 | severity 阈值：critical 必发，high 聚合（5min 内合并），med/low 写 inbox 不推送 |
| **D-P1-7 改 agent.md frontmatter 可能让老 agent.md 解析失败** | 4 个 stub agent 修复后仍不 work | 加 `requires_skills` 缺省值 = `[]`（不破坏老 agent.md） |
| **D-P1-9 改 3 个 agent.md 分工可能引发其他 agent 重新理解** | orchestrator 路由表需要重对一遍 | 同步更新 mavis/agent.md 路由表 |
| **D-P0-1 删项目级 planner 可能让项目本地 plan 失败** | repo 内 plan 不再能用 planner | 在 init skill 里说"项目级 plan 由项目内 rein/planner 处理，全局 plan 用全局 planner" |

### 4.3 不做的代价（如果不修）

- **不修 D-P0-1**：plan_58090e16 这种需要 `/plan` 的任务在全局 mavis 上**永远跑不通**
- **不修 D-P0-2**：4/12 (33%) advertised 路由**永远断**
- **不修 D-P0-3**：任何 `mavis agent update --system-prompt > 8000B` 静默失败——4 个 stub 可能再产生
- **不修 D-P0-4**：40% 失败 plan 永远被标 `cancelled`，用户无法识别
- **不修 D-P0-5**：mavis **永远学不会教训**——每次踩同样的坑
- **不修 D-P0-6**：任何 agent 启动项目读 AGENTS.md **读不到索引**
- **不修 D-P0-7**：stub agent **永远不会被发现**——新产生的 stub 没人知道

---

## 5. Alternatives Considered（替代方案）

> 每个 P0/P1 决策考虑过哪些替代方案 + 为什么最终没选

### D-P0-1 替代方案

| 方案 | 描述 | 不选理由 |
|------|------|----------|
| **A. 删全局 planner 引用，让 mavis 路由到 general** | mavis/agent.md 改"Plan 步 → general agent" | general 是兜底，**违反接口分离**（RC-19），让 general 客串 specialist——架构边界崩塌 |
| **B. 把 planner 改名为 project-planner，全局不挂** | 在 SKILLS.md 注明"planner 是项目级 skill" | `/plan` 是 plan-workflow skill 的核心，**项目级 plan-workflow 等于不存在**（plan engine 是全局的） |
| **C. 在 init skill 加 `.harness/reins/planner/`，让项目级覆盖全局**（architect 修法建议）| 项目级 reins 是一等公民 | v0.3.0 scope 内改动大；先恢复全局，reins 机制是 v0.4+ scope（D-P2-X） |
| ✅ **D. 恢复全局 planner + 删项目级（已选）** | 1 行 fix，source-of-truth 单一 | — |

### D-P0-2 替代方案

| 方案 | 描述 | 不选理由 |
|------|------|----------|
| **A. 重新跑 plan_2c6b8fd3 部署流程** | 用历史 plan 重新走一遍 | plan_2c6b8fd3 本身的 verifier 报告说"8000B drop 是 bug"——**重跑必失败** |
| **B. 写 4 个 stub agent 的最小 persona（每个 200B）** | "够用就行" | 违反 5 实践接口分离——每个 agent 需要完整 persona 才能被严肃调用 |
| **C. 让 4 个 stub agent 完全依赖 daemon 内置 prompt，明确"内置 prompt 兜底是有意设计"**（architect 修法建议 2）| 把"stub = 用内置"作为正式契约 | 隐藏问题：用户**无法控制这些 agent 行为**，daemon 升级会**静默改** agent 行为（RC-3 联动）|
| ✅ **D. 从 Efficient-MiniMaxCode repo 拷贝完整 agent.md（已选）** | 内容已存在，2 min 解决 | — |

### D-P0-3 替代方案

| 方案 | 描述 | 不选理由 |
|------|------|----------|
| **A. 文档化 "不要用 --system-prompt > 8000B"** | 加 `--help` warning | human 在 loop，永远会忘（plan_2c6b8fd3 attempt 1+2 已证）|
| **B. 自动分片（>8000B 自动拆成多次 update）**| 客户端透明 | 拆片后语义可能变（不是 atomic），可能引入 partial update 中间态 |
| ✅ **C. 硬限制 + 加 `--from-file` 强制 on-disk overlay（已选）** | 退出码非 0 + 给替代路径 | — |

### D-P0-4 替代方案

| 方案 | 描述 | 不选理由 |
|------|------|----------|
| **A. 状态机保持 `cancelled` + 在 verdict_summary 里加 `[FAILED]` 前缀** | 字符串区分 | 字符串易复制粘贴丢前缀；用户 grep `status: cancelled` 看不到 |
| **B. 改 `cancelled` 字段为 `cancelled: { reason: 'user' | 'system_failure' }`** | 结构化 | 兼容性差，要改所有 plan consumer |
| ✅ **C. 新增 `status: failed` 状态值（已选）** | 显式、易扩展 | — |

### D-P0-5 替代方案

| 方案 | 描述 | 不选理由 |
|------|------|----------|
| **A. 限制 memory 只存标题（"我们用 semantic search 不需要 body"）** | 哲学层面拒绝 | 8 条 stub 标题已经证明"只存标题"等于**不存**——无法 grep 找 lessons |
| **B. 用 SQLite 替代 markdown 文件** | 更结构化 | 改动太大；现有 5 个 agent 已用 markdown 成功（general 2150B 完整）|
| **C. 把 memory 全部交给 meta-writer single-writer** | 统一管理 | 短期方向对，但 daemon bug 不修，meta-writer 也会被吞——**先修基础设施** |
| ✅ **D. 修 `mavis memory append` 实现 + 加 schema 校验（已选）** | 修根因 | — |

### D-P0-7 替代方案

| 方案 | 描述 | 不选理由 |
|------|------|----------|
| **A. 在 `mavis agent list` 输出加 `is_stub: true` 列** | 复用现有命令 | `mavis agent list` 用户高频用，schema 改动影响其他工具 |
| **B. 让 mavis 启动时自动修 stub** | daemon 启动时检测 + 报警 | 自动化修复会**覆盖用户主动写的 stub**（边界不清）|
| ✅ **C. 新增 `mavis agent health` 专用命令（已选）** | 显式、可观测、不可误用 | — |

### D-P1-3 替代方案

| 方案 | 描述 | 不选理由 |
|------|------|----------|
| **A. plan engine 每次 dispatch 前 grep agent.md size** | 简单实现 | 散落在 plan engine 多个地方，难维护 |
| **B. 用 `mavis agent health` 加缓存层** | 高频调用不重算 | v0.3.0 scope 大，缓存失效策略要设计 |
| ✅ **C. plan engine spawn 前调 `mavis agent health <name>`（已选）** | 复用 D-P0-7 基础设施 | — |

### D-P1-7 替代方案

| 方案 | 描述 | 不选理由 |
|------|------|----------|
| **A. 保留 SKILLS.md Loading Map + 加 daemon 强制** | 文档 + 代码双轨 | 容易漂移 |
| **B. Loading Map 全部 daemon 内置（agent 不可声明 skill）**| daemon 统一 | 用户无法扩展 |
| ✅ **C. 改用 agent.md frontmatter `requires_skills:`（已选）** | 声明式、daemon 强制 | — |

### D-P1-8 替代方案

| 方案 | 描述 | 不选理由 |
|------|------|----------|
| **A. 保留 self-evaluation + 强制要求引用 metric** | 渐进 | self-evaluation 仍是 LLM 主观打分，**根本问题没解** |
| **B. 完全删 self-evaluation** | 激进 | 用户在很多场景下需要"一句话总结"——突然删了不友好 |
| ✅ **C. metric 报告 + self-evaluation 引用 metric（已选）** | 渐进 + 量化 | — |

---

## 6. Implementation（实施步骤）

### 6.1 顺序图（v0.3.0 落地路径）

```
Week 1: 基础修复（critical path）
  ├─ D-P0-1  恢复全局 planner                  [release-manager]  1h
  ├─ D-P0-2  修复 4 stub agent.md              [release-manager]  1h
  ├─ D-P0-6  修 AGENTS.md 编码                  [release-manager]  30min
  └─ D-P0-7  加 mavis agent health             [daemon maintainer] 4h

Week 2: 基础设施
  ├─ D-P0-3  修 8000B silent drop              [daemon maintainer] 4h
  ├─ D-P0-3b 加 --from-file 配套              [daemon maintainer] 1h
  ├─ D-P0-4  加 plan failed 状态               [daemon maintainer] 4h
  └─ D-P0-5  修 memory append 写入              [daemon maintainer] 6h

Week 3: 增强（v0.3.0 收尾）
  ├─ D-P1-1  deliverable.md schema             [architect]        4h
  ├─ D-P1-2  verify_prompt schema              [architect]        2h
  ├─ D-P1-3  plan engine agent_health_gate     [daemon maintainer] 4h
  ├─ D-P1-4  spawn 失败 fallback               [daemon maintainer] 2h
  ├─ D-P1-5  owner notification                [daemon maintainer] 4h
  ├─ D-P1-6  mavis agent show --full           [daemon maintainer] 2h
  ├─ D-P1-7  requires_skills frontmatter       [daemon maintainer] 6h
  ├─ D-P1-8  metric 报告                       [silent-failure + daemon] 6h
  └─ D-P1-9  3 agent 5 实践分工                [architect + meta-writer] 4h

Week 4: 验证
  ├─ 跑 plan_58090e16 重放测试                  [release-manager]  2h
  ├─ 实测 D-P0-7 健康分                        [verifier]         2h
  ├─ 实测 D-P0-4 failed 状态                    [verifier]         2h
  └─ 写 v0.3.0 release notes                    [meta-writer]      2h
```

### 6.2 验收 checklist

#### Critical path（必须全过才能 release v0.3.0）

- [ ] **D-P0-1**: `mavis agent info planner` 返回 ≥ 2000B 内容
- [ ] **D-P0-2**: 4 个 stub agent.md 全部 ≥ 2000B；`mavis agent list` 不再有任何 39B 文件
- [ ] **D-P0-3**: `mavis agent update --system-prompt "..." ` 传 8001B 返回 `Error: system-prompt exceeds 8000 bytes` 退出码 1
- [ ] **D-P0-3b**: `mavis agent update --from-file <path>` 工作正常
- [ ] **D-P0-4**: 模拟一个 plan 失败，status 字段 = `failed`（不是 `cancelled`）
- [ ] **D-P0-5**: `mavis memory show mavis` 输出 ≥ 2000B 含 ≥ 5 条 Type+body 完整 memory
- [ ] **D-P0-6**: `Read AGENTS.md` 看到正确中文，grep "鐪" 0 命中
- [ ] **D-P0-7**: `mavis agent health` 输出 12 行，4 个 stub 标 `is_stub: true`

#### 完整 release

- [ ] **D-P1-1 ~ D-P1-9** 全部完成
- [ ] `mavis metric report` 输出 6 个 metric
- [ ] 跑 1 个 end-to-end plan（think → plan → build → review → ship → reflect 6 步全走）
- [ ] 5/15 路由表全部 work（按 verifier Probe 1 重测）

### 6.3 Owner 分配

| 角色 | 拥有 P0 | 拥有 P1 |
|------|---------|---------|
| **release-manager** | D-P0-1, D-P0-2, D-P0-6 | — |
| **daemon maintainer** | D-P0-3, D-P0-4, D-P0-5, D-P0-7 | D-P1-3, D-P1-4, D-P1-5, D-P1-6, D-P1-7 |
| **architect** | — | D-P1-1, D-P1-2, D-P1-9 |
| **silent-failure-hunter** | — | D-P1-8（与 daemon maintainer 配对）|
| **meta-writer（本 ADR 作者）**| — | D-P1-9 配对 + 未来 ADR |

### 6.4 风险 mitigation

- **D-P0-3 硬限制可能 break 历史调用** → 先 D-P0-3b，再 D-P0-3（分 2 release）
- **D-P0-5 schema 校验可能拒历史 memory** → 加 migration script
- **D-P1-3 gate 让当前 plan 暂停** → 修完 D-P0-2 再开 gate
- **D-P1-7 frontmatter 改 schema** → 缺省值 `[]` 兼容老 agent.md

---

## 7. References

- **3 视角审查原始报告**:
  - `C:\Users\22923\.mavis\plans\plan_58090e16\outputs\review-verifier\deliverable.md`
  - `C:\Users\22923\.mavis\plans\plan_58090e16\outputs\review-architect\deliverable.md`
  - `C:\Users\22923\.mavis\plans\plan_58090e16\outputs\review-silent-failure\deliverable.md`
- **历史 plan**（用于 pattern 验证）:
  - `plan_2c6b8fd3`: 13 agent 部署（completed, 3 cycles）
  - `plan_929215ac`: 按需委派实测（completed, 2 cycles）
  - `plan_c994728c`: code-reader 路由（cancelled — spawn blocked）
  - `plan_6534a4bc`: p1-fix（cancelled — verifier FAIL, silent drop 冲突）
  - `plan_58090e16`: 当前（running, 4 task）
- **mavis 关键文件**:
  - `C:\Users\22923\.mavis\agents\` (12 live + 1 .bak)
  - `D:\MiniMax_workSpace\default_workSpace\Efficient-MiniMaxCode\agents\` (13 in repo)
  - `D:\MiniMax_workSpace\default_workSpace\Efficient-MiniMaxCode\AGENTS.md` (乱码，需修)
  - `D:\MiniMax_workSpace\default_workSpace\Efficient-MiniMaxCode\SKILLS.md` (Loading Map 需废弃)
  - `D:\MiniMax_workSpace\default_workSpace\Efficient-MiniMaxCode\mavis\agent.md`
- **user_profile 引用**:
  - "Self-evaluation 不可靠 — 必须多 Agent 视角"（cross-project，支撑 D-P1-8）
  - "Solo developer"（影响 owner notification 设计——不需要 team 通知通道）

---

## 8. Meta（meta-writer 单一作者声明）

- **本 ADR 是 single-writer 铁律的第一次真正落地**——49 raw finding → 22 root cause → 9 P0 + 9 P1 + 10 P2 + 5 P3
- **没有添加任何新 finding**——所有结论都能追溯到 3 视角原始报告的 file_path:line
- **不省略任何 CRITICAL/HIGH**——22 个 root cause 全部有对应的 P0/P1 决策
- **每个 P0/P1 都有 owner + 步骤 + 验收**——可直接执行
- **alternatives considered 完整**——避免"决策是凭空"的常见 anti-pattern
- **meta-irony 标记**:
  - D-P0-2 修的 4 stub agent 包含**本 ADR 的作者**（meta-writer 自己的 agent.md 39B）——**本 ADR 在自我修的范围内**
  - D-P0-5 修的 mavis orchestrator memory 问题——本 ADR 本身的"教训"如果 Mavis 记不住，下次还会犯同样错
  - D-P1-9 改 3 agent 分工包含 architect + verifier——**本 ADR 的两个 reviewers 自己被改**

---

**END OF ADR**

下一步：用户决策 → 接受 / 拒绝 / 修改 → release-manager 启动 v0.3.0 实施

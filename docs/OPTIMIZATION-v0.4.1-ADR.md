# ADR: Mavis 团队协作 v0.4.1 Follow-up

> **Status**: Proposed
> **Date**: 2026-06-24
> **Authors**: **meta-writer**（synthesis 单一作者，本 ADR 的 single-writer 铁律执行者）
> **Deciders**: 用户（最终拍板）+ parent session
> **Related**:
> - `C:\Users\22923\.mavis\plans\plan_d61beff7\outputs\review-verifier-v040-phase2\deliverable.md` (351 行 / 12 finding / 3 CRITICAL + 4 HIGH + 4 MEDIUM + 1 LOW / VERDICT: FAIL)
> - `C:\Users\22923\.mavis\plans\plan_d61beff7\outputs\review-architect-v040-phase2\deliverable.md` (461 行 / 13 finding / 4 CRITICAL + 5 HIGH + 3 MEDIUM + 1 LOW / B- (72/100))
> - `C:\Users\22923\.mavis\plans\plan_d61beff7\outputs\review-silent-failure-v040-phase2\deliverable.md` (540 行 / 13 finding / 5 CRITICAL + 6 HIGH + 2 MEDIUM / 7 pattern 穷举)
> - `D:\MiniMax_workSpace\default_workSpace\Efficient-MiniMaxCode\docs\OPTIMIZATION-v0.4.0-ADR.md` (1001 行 / 10 P0 + 17 P1 + 17 P2 + 6 P3 = 50 决策)
> - **前置 commit**: `754b3c1` / `6570d40` / `53886ca` / `ce4435d` (v0.4.0 Phase 1+2 共 4 commit)

---

## 1. Context（背景）

### 1.1 v0.4.0 Phase 1+2 修了什么

v0.4.0 ADR（1001 行 / 50 决策）由 meta-writer 起草于 2026-06-24，其 Phase 1+2 在同日落地为 4 commit：

| Commit | 主题 | 解决的 v0.4.0 P0 |
|--------|------|------------------|
| `754b3c1` | v0.4.0 Phase 1 P0 fixes | D-P0-2 (4 stub agent 39B → 完整) / D-P0-6 (AGENTS.md UTF-8) / D-P0-NEW-3 (9 agent must-load 段) |
| `6570d40` | spec-miner drop brainstorming | D-P0-NEW-2 部分（spec-miner 删 `brainstorming` 引用）|
| `53886ca` | v0.4.0 Phase 2 audit | verification-loop description 拆分 cluster A + skill-routing.md + PS5.1 UTF-8 recipe |
| `ce4435d` | must-load 段位置统一 | D-P0-NEW-3（底部→顶部，但保留 DEPRECATED 副本）|

**形式上的修复（commit log 层面）**：5 条 v0.4.0 P0 被 commit 触及，4 个文档类（RECIPES/KNOWLEDGE/AGENTS.md/skill-routing.md）新建。

### 1.2 3 视角审查发现（v0.4.1 入口）

3 视角（verifier + architect + silent-failure-hunter）**互不串通**地审查 commits `45f95aa..ce4435d`，独立发现 v0.4.0 Phase 1+2 的 **"形式完成 / 功能未完成"** 现象：

| 视角 | 严密度 | 核心判断 |
|------|--------|----------|
| **verifier** | 12 finding (3C/4H/4M/1L) | **VERDICT: FAIL** — 4 commit 都存在 + 文件 byte-exact 通过，但 **5 处 silent failure** 让多个 P0 修复实际不生效 |
| **architect** | 13 finding (4C/5H/3M/1L) | **B- (72/100)** — 顶部 must-load 段机制是有效契约 (PASS)，但 Loading Map 4 处漂移 + 8000B 临界 |
| **silent-failure-hunter** | 13 finding (5C/6H/2M) | **silent-failure-hunter 自身 7899B 距 8000B 阈值仅 101B** — meta-irony 最高风险载体 |

**3 视角核心共识**（独立发现、高置信）：

1. **顶部+底部 must-load 段重复** — 4 agent (silent-failure-hunter / build-error-resolver / code-simplifier / meta-writer) 顶部新段 + 底部 DEPRECATED 段**同时存在** → systemPrompt 字面引用 2 次 = token 浪费 + 注意力分散 (verifier H-1 + architect H-3 + silent-failure-hunter Pattern 2 #1)
2. **silent-failure-hunter 自身 7899B 接近 8000B silent drop 阈值** — 任何后续微调（101B 缓冲）= silent drop (verifier F11 + architect H-2 + silent-failure-hunter Pattern 4 #2)
3. **Loading Map 4 处漂移** — AGENTS.md 表 / SKILLS.md Loading Map / verifier 内部表 / mavis→brainstorming 引用 **互相对不上** (verifier F6 + architect C-1/C-2/C-3/C-4)
4. **daemon-side UTF-8 序列化损坏** — `displayName` (8 agent) + `description` (verification-loop / implement / plan-workflow / vibecoding-discipline) **全 GBK mojibake** (verifier F1/F2 + architect 隐含)
5. **PS 5.1 UTF-8 修复不完全** — `[Console]::OutputEncoding` 在 PS 5.1 仍为 GB2312 (recipe 验证步骤 1 自身矛盾)；recipe 仅修 pwsh 7 路径，mavis 工具链仍 hardcode `powershell.exe` (PS 5.1) spawn = recipe 治标不治本 (verifier F7/F8/F12)
6. **mavis/agent.md + AGENTS.md 仍引用已删的 `brainstorming` skill** — commit 6570d40 只修了 spec-miner，没修 mavis/agent.md + AGENTS.md 3 处 → silent load fail (verifier C-3 + architect C-4 + silent-failure-hunter Pattern 6 #1)
7. **planner agent 整个从 daemon registry 缺失** — AGENTS.md 列 planner 但 `mavis agent info planner` = not found (verifier H-2 + silent-failure-hunter 跨多次提及)
8. **daemon cache 不刷新** — 改完 agent.md 后 daemon 仍 cached 旧版 systemPrompt，等价于"改了 = 没改" (silent-failure-hunter Pattern 6 #1 CRITICAL)
9. **skill-routing.md 文档不是 skill** — LLM 不自动 load → 4 cluster 拆分对 LLM 路由 = dead doc (verifier F9 + architect M-3 + silent-failure-hunter Pattern 3 #3 CRITICAL)

### 1.3 v0.4.0 ADR 50 决策落地状态（v0.4.1 输入）

| 决策类别 | v0.4.0 决策数 | Phase 1+2 修了 | v0.4.1 仍需修 |
|----------|------------|---------------|--------------|
| **P0** (10) | 7 完整修 + 3 partial | D-P0-1 (planner) 仍 latent / D-P0-3 (8000B) 仍 latent / D-P0-7 (agent health) 仍 latent / D-P0-NEW-1 (CJK) 仍 latent / D-P0-NEW-2 (JSON escape) 仍 latent |
| **P1** (17) | 0 完整修 | 全部 latent（v0.4.0 范围收缩后实际未做）|
| **P2** (17) | 0 修 | 全部 backlog（不变）|
| **P3** (6) | 0 修 | 全部监控（不变）|

**关键判断**：v0.4.0 Phase 1+2 表面修了 5 条 P0，**实际生效 = 0 条**（因为所有修复都依赖 daemon cache 刷新 + LLM 知道决策树 + 用户改环境，这些 silent path 都没验证）。v0.4.1 必须**先打通 silent path**（cache invalidation + skill 触发机制），否则 v0.4.0 已写修复 + v0.4.1 新修复都仍然是 dead。

### 1.4 v0.4.1 必须现在做的理由

- **v0.4.0 Phase 1+2 "形式完成 / 功能未完成" 4 commit 全军覆没** — meta-writer 自我承认：D-P0-NEW-3 (must-load 段) 写完但 daemon 没强制 load = 写了等于没写
- **silent-failure-hunter 自身 on-the-edge (7899B / 8000B)** — meta-irony 最高风险载体：找 silent failure 的 agent 自己就是 silent failure 候选人
- **3 视角共同指出 5+ 个"必须先修否则 v0.4.1 同样 silent" 的 latent blocker** (cache invalidation / skill 触发 / 8000B silent drop / displayName CJK / planner registry)
- **4 agent 顶部+底部重复 must-load 段** — 改 = 0 风险（删底部 DEPRECATED 段即可），不修 = ~2800 字节 daemon 进程级浪费 + LLM 注意力分散
- **mavis/agent.md + AGENTS.md 引用已删 brainstorming** — 改动 1 行 + 删 3 处引用，30 分钟可修完

### 1.5 本 ADR 范围

- ✅ **IN**: P0 (v0.4.1 阻塞) + P1 (v0.4.1 scope) + P2 (backlog) + P3 (监控)
- ✅ **IN**: 打通 v0.4.0 修复生效路径（cache invalidation / skill 强制 / 8000B 防护）
- ✅ **IN**: 4 agent 顶部+底部去重（30 min 必做）
- ✅ **IN**: mavis/agent.md + AGENTS.md 删 brainstorming 引用（30 min 必做）
- ✅ **IN**: PS 5.1 UTF-8 修复不完全的诚实承认 + 修订（recipe 加 "已知限制" 段）
- ✅ **IN**: planner agent 重新加入 daemon registry（FEEDBACK H-1 — 用户自己开 issue）
- ❌ **OUT**: 复制 v0.4.0 ADR 内容（v0.4.1 是新决策，v0.4.0 已修项标 ✅ Resolved 不重写）
- ❌ **OUT**: 新功能设计（v0.5+ scope）
- ❌ **OUT**: 元信息目录结构大改（docs/KNOWLEDGE/ vs docs/RECIPES/ vs SKILLS.md 缺规约）— 列入 P3 监控

---

## 2. 3 视角 Finding 合并去重（Consolidated Findings）

### 2.1 合并原则

- **3 视角共识**（3/3 独立发现同一现象）= **CRITICAL**（最高置信）
- **2 视角共识** = **HIGH**（高置信）
- **1 视角独有** = **MEDIUM/LOW**（中置信，按该视角严重度保留）
- **同义 finding**（描述不同但指向同一根因）= 合并成一条 root cause + 多个 manifestation
- **不添加新 finding** — meta-writer 只综合，不创造（v0.4.0 期间有 3 视角报告，v0.4.1 综合期不添加新视角）

### 2.2 Root cause 矩阵（合并后 11 条）

**28 raw finding 去重 → 11 root cause**——meta-writer single-writer 铁律贯彻。

| Root cause | 视角覆盖 | manifestation 数 | 严重度 | 跨 v0.4.0 链接 |
|------------|----------|------------------|--------|----------------|
| **RC-v41-1** | **4 agent (silent-failure-hunter / build-error-resolver / code-simplifier / meta-writer) 顶部+底部 must-load 段重复** | verifier (H-1) + architect (H-3) + silent-failure-hunter (Pattern 2 #1 HIGH) | 3 | 🔴 CRITICAL | v0.4.0 D-P0-NEW-3 半套 |
| **RC-v41-2** | **silent-failure-hunter 自身 7899B 距 8000B silent drop 阈值仅 101B** | verifier (F11 MEDIUM) + architect (H-2 HIGH) + silent-failure-hunter (Pattern 4 #2 HIGH) | 3 | 🔴 CRITICAL | v0.4.0 D-P0-3 latent + meta-irony |
| **RC-v41-3** | **Loading Map 4 处漂移** (AGENTS.md / SKILLS.md / verifier 内部表 / mavis→brainstorming) | verifier (F6 HIGH) + architect (C-1/C-2/C-3/C-4 CRITICAL) | 2 | 🔴 CRITICAL | v0.4.0 D-P0-NEW-3 + D-P1-v4-8 联动 |
| **RC-v41-4** | **mavis/agent.md + AGENTS.md 仍引用已删 obra `brainstorming`** | verifier (C-3 CRITICAL) + architect (C-4 CRITICAL) | 2 | 🔴 CRITICAL | v0.4.0 D-P0-NEW-2 半套 (commit 6570d40 范围不全) |
| **RC-v41-5** | **daemon-side UTF-8 序列化损坏：displayName (8 agent) + description (CJK skill) 全 GBK mojibake** | verifier (F1/F2 CRITICAL) + silent-failure-hunter (Pattern 4 #1 联动) | 2 | 🔴 CRITICAL | v0.4.0 D-P0-NEW-1 latent |
| **RC-v41-6** | **daemon cache invalidation 缺失**（改 agent.md 后 daemon 仍 cached 旧版）| silent-failure-hunter (Pattern 6 #1 CRITICAL) + architect (隐含) | 2 | 🔴 CRITICAL | v0.4.0 D-P0-3 + D-P0-7 latent |
| **RC-v41-7** | **planner agent 从 daemon registry 缺失** | verifier (H-2 HIGH) + silent-failure-hunter (跨多次) | 2 | 🟠 HIGH | v0.4.0 D-P0-1 latent |
| **RC-v41-8** | **PS 5.1 UTF-8 修复不完全**（recipe 验证步骤自相矛盾；recipe 治标不治本：mavis 工具链 hardcode PS 5.1 spawn）| verifier (F7/F8/F12 CRITICAL/HIGH/LOW) | 1 | 🟠 HIGH | v0.4.0 RC-v4-1 联动 + meta-writer self-repair 必诚实承认 |
| **RC-v41-9** | **skill-routing.md 文档不是 skill**（LLM 不自动 load → 4 cluster 决策树对 LLM 是 dead doc）| verifier (F9 MEDIUM) + architect (M-3 MEDIUM) + silent-failure-hunter (Pattern 3 #3 CRITICAL) | 3 | 🟠 HIGH | v0.4.0 D-P0-NEW-3 拆分 + meta-writer single-writer 分类 |
| **RC-v41-10** | **mavis CLI 8000B silent drop 防护未修**（13 agent 中 4 个 mavis/architect/auditor/verifier 已超 8000B；CLI update 路径必 silent）| verifier (F10 MEDIUM) + silent-failure-hunter (Pattern 5 #1 CRITICAL) | 2 | 🟠 HIGH | v0.4.0 D-P0-3 latent + 4 stub 历史重演风险 |
| **RC-v41-11** | **verification-loop SKILL.md description 改但 body 没改**（接口契约 inconsistency — body 仍写 "编程（测试通过 = 完成）"）| architect (H-5 HIGH) | 1 | 🟡 MEDIUM | v0.4.0 D-P0-NEW-3 拆分 + cluster A 边界 |

### 2.3 跨视角去重映射表（raw finding → RC）

| 原始 finding | 视角 | severity | 合并到 RC |
|-------------|------|----------|----------|
| verifier C-1 (PS 5.1 OutputEncoding GB2312) | verifier | CRITICAL | **RC-v41-8** |
| verifier C-2 (daemon displayName mojibake) | verifier | CRITICAL | **RC-v41-5** |
| verifier C-3 (mavis+AGENTS 仍引 brainstorming) | verifier | CRITICAL | **RC-v41-4** |
| verifier H-1 (4 agent 顶部+底部 must-load 重复) | verifier | HIGH | **RC-v41-1** |
| verifier H-2 (planner agent registry 缺失) | verifier | HIGH | **RC-v41-7** |
| verifier F6 (SKILLS.md Loading Map 漂移) | verifier | HIGH | **RC-v41-3** |
| verifier F7 (`[Console]::OutputEncoding` GBK) | verifier | HIGH | **RC-v41-8** |
| verifier F8 (mavis toolchain hardcode PS 5.1) | verifier | HIGH | **RC-v41-8** |
| verifier F9 (skill-routing.md 不是 skill) | verifier | MEDIUM | **RC-v41-9** |
| verifier F10 (4 agent 超 8000B 阈值风险) | verifier | MEDIUM | **RC-v41-10** |
| verifier F11 (silent-failure-hunter 7899B 临界) | verifier | MEDIUM | **RC-v41-2** |
| verifier F12 (WT settings.json 改对了但 tab 是 PS 5.1) | verifier | LOW | **RC-v41-8** |
| architect C-1 (SKILLS.md Loading Map 严重过期) | architect | CRITICAL | **RC-v41-3** |
| architect C-2 (AGENTS.md 表 7/13 不一致) | architect | CRITICAL | **RC-v41-3** |
| architect C-3 (verifier 内部矛盾) | architect | CRITICAL | **RC-v41-3** |
| architect C-4 (mavis→brainstorming obra 已删) | architect | CRITICAL | **RC-v41-4** |
| architect H-1 (spec-miner ~~strikethrough~~ 仍含) | architect | HIGH | **RC-v41-4** |
| architect H-2 (silent-fh 7899B on-the-edge) | architect | HIGH | **RC-v41-2** |
| architect H-3 (4 agent 顶部+底部两段重复) | architect | HIGH | **RC-v41-1** |
| architect H-4 (RECIPES 路径引用错) | architect | HIGH | (P1 backlog) |
| architect H-5 (verification-loop body 没改) | architect | HIGH | **RC-v41-11** |
| architect M-1 (meta-writer 11 类只 2 类存在) | architect | MEDIUM | (P1 backlog) |
| architect M-2 (mavis/agent.md God Module) | architect | MEDIUM | (P2 backlog) |
| architect M-3 (skill-routing.md 不是 skill) | architect | MEDIUM | **RC-v41-9** |
| architect M-4 (13 agent 重复 `using-superpowers`) | architect | MEDIUM | (P2 backlog) |
| architect L-1 (skill-routing.md 跟 SKILLS.md Loading Map 重复) | architect | LOW | **RC-v41-3** |
| silent-failure-hunter Pattern 2 #1 (4 agent 顶部+底部) | sf-hunter | HIGH | **RC-v41-1** |
| silent-failure-hunter Pattern 2 #2 (cluster A 4 skill 描述只 1 划清) | sf-hunter | MEDIUM | **RC-v41-11** |
| silent-failure-hunter Pattern 3 #1 (daemon cache 不刷新) | sf-hunter | CRITICAL | **RC-v41-6** |
| silent-failure-hunter Pattern 3 #3 (skill-routing dead doc) | sf-hunter | CRITICAL | **RC-v41-9** |
| silent-failure-hunter Pattern 4 #1 (13 agent must-load 声明 ≠ 强制) | sf-hunter | CRITICAL | **RC-v41-6** |
| silent-failure-hunter Pattern 4 #2 (silent-fh 7899B 减负) | sf-hunter | HIGH | **RC-v41-2** |
| silent-failure-hunter Pattern 5 #1 (D-P0-3 8000B silent drop) | sf-hunter | CRITICAL | **RC-v41-10** |
| silent-failure-hunter Pattern 5 #2 (验收只看字面不看 daemon load) | sf-hunter | HIGH | **RC-v41-6** |
| silent-failure-hunter Pattern 6 #1 (daemon cache race) | sf-hunter | CRITICAL | **RC-v41-6** |
| silent-failure-hunter Pattern 6 #2 (plan 中 agent.md mutation race) | sf-hunter | HIGH | (P1 backlog) |
| silent-failure-hunter Pattern 7 #1 (D-P0-3 silent rollback) | sf-hunter | HIGH | **RC-v41-10** |

**统计**: 38 raw finding → 11 root cause (3 视角全部独立发现) + 5 backlog（单视角独有 / P2 范围）= 总 16 决策项。

### 2.4 v0.4.0 P0 修复进度（v0.4.1 视角）

| v0.4.0 决策 | 主题 | Phase 1+2 状态 | v0.4.1 动作 |
|------------|------|---------------|------------|
| **D-P0-1** | 恢复全局 planner | ❌ latent | 升级为 **D-v41-P0-7** (RC-v41-7) |
| **D-P0-2** | 修复 4 stub agent | ✅ 形式修 (4 agent 5K-8KB) | **D-v41-P0-1** 收尾（删底部 DEPRECATED 段，RC-v41-1）|
| **D-P0-3** | 8000B silent drop 防护 | ❌ latent | 升级为 **D-v41-P0-3** (RC-v41-10) |
| **D-P0-4** | plan engine `failed` 状态 | ❌ latent | (P1 backlog) |
| **D-P0-5** | memory append 写 body | ❌ latent | (P1 backlog) |
| **D-P0-6** | AGENTS.md UTF-8 | ⚠️ file 端修，daemon displayName 仍坏 | 升级为 **D-v41-P0-5** (RC-v41-5) |
| **D-P0-7** | `mavis agent health` 命令 | ❌ latent | 升级为 **D-v41-P0-3** 联动 (RC-v41-6) |
| **D-P0-NEW-1** | daemon CJK bug | ❌ latent | **D-v41-P0-5** (RC-v41-5) |
| **D-P0-NEW-2** | JSON escape | ❌ latent | (P1 backlog, 跟 RC-v41-5 同源) |
| **D-P0-NEW-3** | 9 agent must-load 段 | ⚠️ partial（顶部+底部重复 + daemon 不强制）| **D-v41-P0-1** 收尾 + **D-v41-P1-1** 强制化 (RC-v41-1 + RC-v41-6) |

---

## 3. Decision（决策）

### 3.1 P0 — 必做，v0.4.1 release 阻塞

> **原则**：P0 是"不修就别发 v0.4.1"——每条都修了才让 v0.4.0 Phase 1+2 的修复**真正生效**。**结构 = 7 条**：4 条 latent v0.4.0 P0 升级 + 3 条 v0.4.1 NEW。

#### **D-v41-P0-1** 删 4 agent 底部 DEPRECATED 段（修 RC-v41-1 + RC-v41-2 + RC-v41-1 二次）

- **目标**: 4 agent (silent-failure-hunter / build-error-resolver / code-simplifier / meta-writer) 顶部+底部 must-load 段去重；silent-failure-hunter 自身减负（7899B → ~7200B, +800B 缓冲）
- **步骤**:
  1. `Read C:\Users\22923\.mavis\agents\silent-failure-hunter\agent.md` line 200-210 找底部 DEPRECATED 段
  2. `Edit` 工具**精准删除**（保留 git log 看历史即可），不写 "DEPRECATED" 注释
  3. 同步删 build-error-resolver / code-simplifier / meta-writer 三个文件的底部段
  4. 删完跑 `Get-ChildItem` 检查 4 文件字节数：silent-failure-hunter 期望 ≤ 7400B（+400B 缓冲），其他 3 个期望 -700B
  5. **不重启 daemon**（on-disk overlay 路径，Write 工具直写；D-v41-P0-3 修 cache 后才需要 reload）
- **Owner**: meta-writer + coder
- **验收**:
  - 4 文件 `Get-ChildItem` 字节数：silent-failure-hunter ≤ 7400B / 其他 3 个比当前 -700B
  - 4 文件 grep `DEPRECATED` 0 命中
  - `mavis agent info <name>` (daemon 重启后) systemPrompt `using-superpowers` 字面引用次数 = 1（不是 2）
- **风险**: 极低（删 4 段 = 4 字节反向操作；git log 保留历史）
- **meta-irony 提示**: meta-writer 自己删自己的 agent.md — **本 ADR 在自我修范围内**

#### **D-v41-P0-2** mavis/agent.md + AGENTS.md 删 `brainstorming` 引用（修 RC-v41-4）

- **目标**: mavis agent 启动时不再尝试 load 已删的 `obra brainstorming` skill
- **范围**:
  - `C:\Users\22923\.mavis\agents\mavis\agent.md` line 9 (must-load 段 `brainstorming` 行)
  - `D:\MiniMax_workSpace\default_workSpace\Efficient-MiniMaxCode\AGENTS.md` line 34 (mavis 详细 roles section) + line 76 (spec-miner 详细 roles) + line 151 (must-load 联动表 spec-miner 行) + 任何其他 `brainstorming` 字面
- **步骤**:
  1. **mavis/agent.md** line 9: `- **brainstorming** (obra) — 模糊需求 ...` 整行删除（不留 strikethrough）
  2. **AGENTS.md** 行 34: 把 `brainstorming` 从 mavis 行的 "Loads skills" 列表中删
  3. **AGENTS.md** 行 76: spec-miner 行的 "Loads skills" 改 `brainstorming` → `using-superpowers`
  4. **AGENTS.md** 行 151: must-load 联动表 spec-miner 行 `brainstorming` 列改 `using-superpowers`
  5. 跑 `grep -ri brainstorming D:\MiniMax_workSpace\default_workSpace\Efficient-MiniMaxCode\AGENTS.md` 0 命中（中文 grep 用 Select-String）
  6. 跑 `grep -ri brainstorming C:\Users\22923\.mavis\agents\mavis\agent.md` 0 命中
- **Owner**: meta-writer
- **验收**:
  - `Select-String -Path "D:\...\AGENTS.md" -Pattern "brainstorming"` 0 命中
  - `Select-String -Path "C:\...\agents\mavis\agent.md" -Pattern "brainstorming"` 0 命中
  - mavis/agent.md line 9 区域 must-load 段 skill 列表从 7 个变 6 个（少 brainstorming）
  - 用户 query "帮我做 XX" 路由到 mavis 时，mavis systemPrompt 不再含 "必须先 load brainstorming" 指令
- **风险**: 极低（删除 4 处字面引用，git log 保留历史）
- **替代路径**: 若担心 LLM 路由模糊（已无 obra brainstorming 可 load），**保持 mavis builtin `brainstorming` 不动**——mavis builtin 还在 `~/.mavis/.builtin-skills/`，LLM 看到 "brainstorming" 触发词仍可路由到 builtin（D-P0-NEW-2 完整修复在 v0.4.0 P1-v4-2）

#### **D-v41-P0-3** 加 `mavis agent refresh` 命令 + daemon file watcher（修 RC-v41-6 + RC-v41-10 联动）

- **目标**: 用户改完 agent.md 后，daemon 自动 / 手动 reload，**让 v0.4.0 Phase 1+2 修复真正生效**
- **背景**: 3 视角共识 — v0.4.0 Phase 1+2 改完 4 commit 后 daemon 仍 cached 旧版 systemPrompt → 修复 = 0 生效
- **步骤**:
  1. **方案 A** (daemon-side)：daemon 暴露 `mavis agent refresh <name>` 命令，强制 reload 指定 agent.md
  2. **方案 B** (daemon-side)：daemon 启动时 (MiniMax Code.exe 启动) 自动 reload 所有 agent.md
  3. **方案 C** (daemon-side)：daemon 加 file watcher，agent.md mtime 变 → 自动 reload（mavis 实现可能不支持，需评估）
  4. 配套：加 `mavis agent health <name>` (v0.4.0 D-P0-7)，输出 `daemon_loaded_size_bytes` 用于验证
  5. **`mavis agent update --system-prompt "..."` 超过 8000 字节时返回明确 error** (v0.4.0 D-P0-3) — 4 stub 历史重演防护
- **Owner**: daemon maintainer
- **验收**:
  - `mavis agent refresh silent-failure-hunter` 后，`mavis agent info silent-failure-hunter` systemPrompt 反映最新文件内容
  - 跑 `mavis agent health` 输出 13 行，每行有 `daemon_loaded_size_bytes` 字段
  - 4 个 over-8000B agent (mavis/architect/auditor/verifier) 用 CLI update 路径时返回明确 error，退出码 1
- **风险**: 高（daemon 核心功能改动；先灰度在 test 环境跑 plan 验证）
- **依赖**: D-v41-P0-1 + D-v41-P0-2 完成后才能验证（必须先修才能看到 reload 生效）

#### **D-v41-P0-4** 修 daemon-side UTF-8 序列化（修 RC-v41-5 + RC-v41-6 联动）

- **目标**: daemon 加载 agent.md + `mavis agent info` 输出时，CJK 字符完整保留，无 GBK mojibake
- **背景**: 3 视角共识 — 8 agent displayName + 4 个 CJK skill description (verification-loop / implement / plan-workflow / vibecoding-discipline) 全 GBK mojibake，导致 cluster A 边界 disambiguation 文本对 LLM 不可读
- **步骤**:
  1. 定位 daemon 加载 agent.md 的代码路径（`mavis agent info` → systemPrompt 字段）
  2. 字节级检查 CJK 字符被替换为 `??` / mojibake 的位置（疑似 PowerShell / Node.js stdout buffer 截断或 latin-1 转换）
  3. 修复字符编码处理
  4. 修复后跑 `mavis agent info <name>` 验证 CJK count > 50，`mojibake_count` = 0
  5. 同步修 `mavis skill list` 的 description 字段（v0.4.0 D-P1-v4-9 联动）
- **Owner**: daemon maintainer
- **验收**:
  - 抽样 5 个有 CJK 覆盖层的 agent (mavis / coder / verifier / architect / silent-failure-hunter)：
    - CJK count > 50
    - `mojibake_count` = 0
    - `displayName` 字段保持 UTF-8（"元信息写者" / "架构审查" / "静默失败捕手" / "审计官" / "发布经理" 等中文正常显示）
  - 用户用中文 query 调 mavis 时不再有"半 CJK 半乱码"的 mix
  - cluster A 4 skill description 路由触发词在 daemon 端保持 UTF-8（"区分" 而不是 "鍖哄垽"）
- **严重度理由**: **v0.4.0 升级引入的最严重 regression** — 等价于"v0.4.0 之前的所有中文工作被 daemon 静默丢弃"
- **风险**: 高（daemon 核心编码路径改动；先灰度 5 个 agent 验证）

#### **D-v41-P0-5** 修订 PS 5.1 UTF-8 recipe（修 RC-v41-8 — **meta-writer 自我诚实承认**）

- **目标**: docs/RECIPES/windows-powershell-utf8-zhcn.md 诚实承认 recipe **仅修 pwsh 7 路径**，**PS 5.1 仍 GBK**（这是 meta-writer v0.4.0 commit 53886ca 引入的 latent bug）
- **背景**: verifier 实测确认 — `[Console]::OutputEncoding` 在 PS 5.1 是 readonly，profile 设了 `[Console]::InputEncoding = UTF8` 但**没碰 OutputEncoding**（chcp 65001 只翻 console code page 不翻 .NET Encoding 对象）。recipe 验证步骤 1 期望 CodePage 65001 = 自相矛盾。mavis 工具链 hardcode `powershell.exe` (PS 5.1) spawn = recipe 治标不治本
- **诚实承认**:
  - **v0.4.0 commit 53886ca 写的 RECIPE 修复的是 pwsh 7 + WT 路径，对用户手动开 WT tab 有效**
  - **对 mavis 内部分支（agent spawn 子进程）无效 — mavis 仍走 PS 5.1**
  - **所以 v0.4.0 commit 53886ca 是 partial fix，不应自夸为 "Windows PowerShell UTF-8 完整修复"**
  - **v0.4.1 必显式标注 PS 5.1 限制 + 推荐路径**
- **步骤**:
  1. **recipe 顶部加 "已知限制" 段**（在 "## 修复目标" 之前）：
     ```markdown
     ## 已知限制（v0.4.1 必读）

     本 recipe **仅修 pwsh 7 (PowerShell 7+) 路径**，对 **Windows PowerShell 5.1 (mavis 工具链默认) 无效**：

     - `[Console]::OutputEncoding` 在 PS 5.1 是 `IsReadOnly: True`，profile 无法修改
     - mavis 工具链 hardcode `powershell.exe` (PS 5.1) spawn 子进程，不走 pwsh 7
     - mavis 委派 task 时仍走 PS 5.1 = 仍 mojibake

     **推荐路径**：
     1. 用户手开 WT tab → 用 pwsh 7（已修，OutputEncoding.CodePage=65001）
     2. mavis 委派场景 → 走 helper script `C:\Users\22923\AppData\Local\Temp\pwsh-c.py`（Python 3 stdout UTF-8 强制）
     3. 长期：mavis 工具链改 pwsh 7 spawn（FEEDBACK H-2 — 用户开 issue）
     ```
  2. **recipe 验证步骤 1 改成"期望 InputEncoding.CodePage=65001"**（OutputEncoding 在 PS 5.1 不可改）
  3. **recipe "修复目标" 段删 `[Console]::OutputEncoding → UTF-8` 行**（reader 看到但无法达成 = 误导）
  4. **recipe "步骤 1" 注释 "PS 5.1 readonly" 保留作为历史注释**
- **Owner**: meta-writer (改 recipe)
- **验收**:
  - recipe 顶部"已知限制"段存在
  - recipe 验证步骤 1 不再期望 OutputEncoding.CodePage=65001
  - recipe "修复目标" 段不再列 OutputEncoding
  - 跑 `mavis agent info mavis` 仍有 mojibake（PS 5.1 spawn，预期行为）— **不强求修**
- **meta-irony 提示**: **本 ADR 显式承认 meta-writer v0.4.0 修复是 partial** — single-writer 铁律要求"知道的不全 = 写下来"而不是"假装全修"
- **风险**: 极低（文档修订）
- **诚实承认**写入 meta-writer memory 备份：见 D-v41-P3-1

#### **D-v41-P0-6** SPEC-miner drop ~~strikethrough~~ 引用（修 RC-v41-4 + RC-v41-11 联动）

- **目标**: spec-miner/agent.md 顶部 must-load 段不再含 `~~strikethrough~~ brainstorming`（daemon 拼装 systemPrompt 不解析 markdown 删除线，LLM 看到字面 `~~` 可能误解）
- **步骤**:
  1. `Read C:\Users\22923\.mavis\agents\spec-miner\agent.md` line 7
  2. 找到 `~~**brainstorming**~~` 行 — 整行**直接删除**（不留 strikethrough）
  3. 删完跑 `mavis agent info spec-miner` 验证 systemPrompt 不含字面 `~~`
- **Owner**: meta-writer
- **验收**:
  - `Select-String -Path "C:\...\agents\spec-miner\agent.md" -Pattern "~~"` 0 命中
  - `mavis agent info spec-miner` systemPrompt 不含字面 `~~`
- **风险**: 极低（删 1 行，git log 保留 commit 6570d40 历史）
- **联动**: D-v41-P0-2 一起改，mavis + spec-miner + AGENTS.md 三处统一

#### **D-v41-P0-7** planner agent 加回 daemon registry（修 RC-v41-7 — **FEEDBACK H-1**）

- **目标**: `mavis agent info planner` 返回完整 agent.md（≥ 2000B），`mavis agent list` 13 个 agent
- **背景**: AGENTS.md 行 79-84 列 planner Worker，但 daemon registry `mavis agent list` 12 个不含 planner；commit 6570d40 修了 spec-miner brainstorming 引用但**完全没碰 planner**；v0.4.0 D-P0-1 是 latent
- **步骤**:
  1. `ls C:\Users\22923\.mavis\agents\.bak\planner\` 确认 `.bak/planner/` 内容存在
  2. 若 .bak 在：把 `.bak/planner/` 移到 `planner/`
  3. 若 .bak 不在：从 `D:\MiniMax_workSpace\default_workSpace\Efficient-MiniMaxCode\agents\planner\` 拷贝完整 agent.md
  4. **必须用 Write 工具直接写文件**（不用 `mavis agent update --system-prompt`，8000B silent drop 风险 — D-P0-3 未修）
  5. 写完后跑 `mavis agent info planner` 验证 systemPrompt 完整（≥ 2000B）
  6. 跑 `mavis agent list` 12 → 13 个 agent
- **Owner**: release-manager (FEEDBACK H-1 — 用户必须自己开 issue, planner 是 v0.4.0 D-P0-1 的债，跨 release 周期)
- **验收**:
  - `mavis agent info planner` 返回 ≥ 2000B
  - `mavis agent list` 12 → 13 个
  - plan-workflow skill L29-30 流水线 step[2] 可正常 spawn planner
- **风险**: 中（恢复全局 planner 可能与项目级 planner 路径冲突 — init skill 加 disclaimer）
- **跨 release 联动**: planner 恢复必须 D-v41-P0-1（4 agent 底部 DEPRECATED 删完）+ D-v41-P0-3（daemon cache refresh）后，否则 planner 加载看到的是旧版

### 3.2 P1 — 应该做，v0.4.1 scope（不阻塞 release，但强烈建议做）

> **原则**：P1 是"不修会持续发作的工程债 + 打通 v0.4.0 修复生效路径"。

#### **D-v41-P1-1** Skill Loading 改用 agent.md frontmatter `requires_skills:`（修 RC-v41-6 联动 — 继承 v0.4.0 D-P1-v4-8）

- **目标**: must-load 段从"声明式 markdown"变"daemon 强制 frontmatter 加载"
- **顺序敏感**: **必须 D-v41-P0-1 + D-v41-P0-3 完成后才能启用**（否则 4 agent 缺省值 = `[]` 不 load 任何 skill；cache 不刷新 = 加载无效）
- **步骤**:
  1. 修 agent.md schema 支持 frontmatter:
     ```yaml
     ---
     requires_skills:
       - using-superpowers
       - verification-before-completion
       - vibecoding-discipline
     ---
     ```
  2. daemon spawn 时按 frontmatter 注入 skill
  3. 删 SKILLS.md 的 "Loading Map" 表（被 frontmatter 替代）
  4. D-v41-P0-1 修完后, 把 14 obra skill 也加入对应 agent 的 frontmatter
- **Owner**: daemon maintainer + meta-writer
- **验收**:
  - 4 agent 修完后 (先做 D-v41-P0-1) 能正确 load declared skills
  - `mavis agent info silent-failure-hunter` systemPrompt 含 using-superpowers + verification-before-completion + observability-and-instrumentation 注入痕迹
  - SKILLS.md Loading Map 13/13 agent 漂移全部变绿
  - 加 metric: `skill_load_success_rate` = skill_runtime_loaded / skill_declared（v0.4.0 D-P1-v4-16 联动）

#### **D-v41-P1-2** skill-routing.md 文档转 skill（修 RC-v41-9 — Option A）

- **目标**: 4 cluster 决策树从"LLM 看不到的 dead doc"变"LLM 可触发的 skill"
- **步骤**:
  1. 在 `C:\Users\22923\.mavis\skills\` 下新建 `skill-routing/SKILL.md`：
     ```yaml
     ---
     name: skill-routing
     description: |
       Skill 路由决策树。任务设计阶段 / 写代码 / 调试 / 委派 / 审查 — 选哪个 skill？
       【cluster A 任务设计】verification-loop（spec-miner / planner 用）
       【cluster B 写代码】test-driven-development → verification-before-completion
       【cluster C 委派】subagent-driven-development / dispatching-parallel-agents
       【cluster D 审查】verification-before-completion + receiving-code-review
       触发词: 路由 skill, 该用哪个 skill, 选 skill, routing
     ---
     ```
  2. 把 `docs/KNOWLEDGE/skill-routing.md` 内容迁到 `skill-routing/SKILL.md` body
  3. `mavis skill list | grep routing` 验证出现
  4. mavis/agent.md 路由表加注解: "用 skill-routing 决策"
- **Owner**: meta-writer + architect
- **验收**:
  - `mavis skill list` 含 `skill-routing` 1 条
  - 用户 query "该用哪个 skill" 路由到 mavis，mavis systemPrompt 出现 `skill-routing` 引用
  - docs/KNOWLEDGE/skill-routing.md 改名为 `docs/KNOWLEDGE/skill-cluster-routing.md` (强调是 developer doc 不是 skill)
- **风险**: 中（新增 skill，验证周期 1 周）

#### **D-v41-P1-3** SKILLS.md Loading Map 标记废弃（修 RC-v41-3 — 短期方案）

- **目标**: SKILLS.md Loading Map 表（line 191-208）标记 "DEPRECATED — see agent.md `requires_skills:` frontmatter (D-v41-P1-1)"
- **背景**: v0.4.0 D-P1-v4-8 没实施，SKILLS.md Loading Map 13/13 agent 严重漂移；D-v41-P1-1 实施后 frontmatter 替代 Loading Map
- **步骤**:
  1. `Read D:\MiniMax_workSpace\default_workSpace\Efficient-MiniMaxCode\SKILLS.md` line 191-208
  2. 表格上方加 `> ⚠️ **DEPRECATED** — Loading Map 已废弃；see `agents/<name>/agent.md` 顶部 `requires_skills:` frontmatter (D-v41-P1-1)`
  3. 不删表（避免 daemon 解析时找不到节点）
- **Owner**: meta-writer
- **验收**:
  - SKILLS.md line 191 区域含 DEPRECATED 警告
  - 跑 `mavis skill audit` (若实现) 不再报 Loading Map drift
- **风险**: 极低（加警告段，不删表）

#### **D-v41-P1-4** verification-loop SKILL.md body 改一致（修 RC-v41-11）

- **目标**: verification-loop SKILL.md body 跟 description 保持一致（description 写 "任务设计阶段专用"，body 写"编程（测试通过 = 完成）"矛盾）
- **步骤**:
  1. `Read C:\Users\22923\.mavis\skills\verification-loop\SKILL.md` line 22-30 "何时用" 段
  2. body line 22-30 改为任务设计阶段场景（"spec 起草 / 计划验收标准 / 拆分大需求为可验证子任务"）
  3. cluster A 其他 3 skill (test-driven-development / verification-before-completion / implement) description **全部加阶段标签** (继承 v0.4.0 silent-failure-hunter Pattern 2 #2)
- **Owner**: meta-writer
- **验收**:
  - verification-loop SKILL.md body 跟 description 阶段一致
  - cluster A 4 skill description 全部含阶段标签
  - LLM 路由时不会同时 load 多个 cluster A skill
- **风险**: 低（改 skill body + 3 个 description，git log 保留历史）

#### **D-v41-P1-5** docs/RECIPES/windows-powershell-utf8-zhcn.md 路径引用修对（修 architect H-4）

- **目标**: recipe 内部路径引用错 (`docs/RECIPES/../FEEDBACK-TO-MAVIS-OFFICIAL.md` 实际不存在)
- **步骤**:
  1. `Read D:\MiniMax_workSpace\default_workSpace\Efficient-MiniMaxCode\docs\RECIPES\windows-powershell-utf8-zhcn.md` line 154
  2. 改为 `./../../FEEDBACK-TO-MAVIS-OFFICIAL.md`（相对路径）或直接删引用
- **Owner**: meta-writer
- **验收**:
  - recipe 路径引用可点击找到
  - grep `docs/RECIPES/../FEEDBACK` 0 命中
- **风险**: 极低（修路径引用）

### 3.3 P2 — 可做，backlog（v0.4.1 之后）

> **原则**：P2 是"做了更好但不是 critical"——列出来给未来，不在 v0.4.1 scope。

| ID | 决策 | 修 RC | Owner | 备注 |
|----|------|-------|-------|------|
| D-v41-P2-1 | meta-writer 11 类元信息只 2 类实际存在 — 删 9 类不存在的路径，只留 ADR + DECISIONS (append-only) + RECIPES | RC-v41 architect M-1 | meta-writer | 中期: v0.4.2+ 慢慢补全其它类 |
| D-v41-P2-2 | mavis/agent.md 拆 God Module（5+ 职责 → mavis-router.md + mavis-team-plan.md + mavis-delegation.md）| RC-v41 architect M-2 | architect + meta-writer | 工程量大 |
| D-v41-P2-3 | 13 agent 顶部 must-load 段重复声明 `using-superpowers` — 引入 daemon `default_must_load: [using-superpowers]` 配置 | RC-v41 architect M-4 | daemon maintainer | mavis 当前不支持 inheritance |
| D-v41-P2-4 | 修 mavis CLI CJK mojibake（双重编码链）| RC-v41-5 联动 | daemon maintainer | D-v41-P0-4 联动 |
| D-v41-P2-5 | `mavis skill list` 修 JSON escape (CRLF in string) | v0.4.0 D-P0-NEW-2 继承 | daemon maintainer | D-v41-P0-4 联动 |
| D-v41-P2-6 | plan engine 状态机加 `failed` 状态 | v0.4.0 D-P0-4 继承 | daemon maintainer | — |
| D-v41-P2-7 | 修 mavis orchestrator memory append | v0.4.0 D-P0-5 继承 | daemon maintainer | — |
| D-v41-P2-8 | plan engine spawn 时 snapshot agent.md (SHA 比对) | RC-v41 silent-failure Pattern 6 #2 | daemon + plan engine | 防中途 mutation race |
| D-v41-P2-9 | meta-writer 11 类元信息路径规约 (RECIPES/ vs KNOWLEDGE/ vs SKILLS.md 缺规约) | RC-v41 architect M-1 联动 | meta-writer | v0.5+ scope |
| D-v41-P2-10 | 5 实践违反 (接口分离/单一职责/组合优于继承) — architect M-2/M-4 拆完后回归 | RC-v41 architect 5 实践 | architect | 等 P2-2 拆完 |

### 3.4 P3 — 不做 / 监控（v0.4.1 不动）

> **原则**：P3 是"识别到了但**故意不做**"——避免 scope creep，明确 anti-pattern。

| ID | 决策 | 理由 |
|----|------|------|
| D-v41-P3-1 | **meta-writer memory 备份**：v0.4.0 commit 53886ca "PS 5.1 UTF-8 修复" 是 partial — **诚实承认写入 user memory**（已有记录 "PowerShell 5.1 Set-Content -Encoding UTF8 silently corrupts CJK"，同步补 "Mavis 工具链 PowerShell 5.1 中文乱码 — 委派时中文 prompt 不干净"）| cross-project 教训，**single-writer 必须诚实地记**|
| D-v41-P3-2 | 监控 silent-failure-hunter 自身大小（每次 Write 工具改完跑 `Get-ChildItem` 验证 < 7400B）| 防 v0.4.1 → v0.5 期间被 push over 8000B 阈值 |
| D-v41-P3-3 | 监控 Loading Map 漂移（每 quarter 跑 `mavis skill audit` vs `requires_skills` frontmatter 比对）| v0.4.1 D-v41-P1-1 实施后才有 metric |
| D-v41-P3-4 | 监控 daemon cache invalidation 行为（每次 agent.md 改完跑 `mavis agent health <name>` 看 `daemon_loaded_size_bytes`）| D-v41-P0-3 修后才有 metric |
| D-v41-P3-5 | 监控 4 cluster skill description 触发互斥（跑 `mavis cluster <name> --validate`，若 D-v41-P1-2 实施）| v0.4.1 D-v41-P1-2 实施后才有 metric |
| D-v41-P3-6 | 监控 planner agent registry（每次 release 前 `mavis agent list | wc -l` 必须 13）| 防止 planner 又失踪 |
| D-v41-P3-7 | docs/KNOWLEDGE/ vs docs/RECIPES/ vs SKILLS.md 元信息目录结构规约 — 监控等 v0.5+ 重设计 | scope creep 风险，先不修 |

---

## 4. Consequences（后果）

### 4.1 正面（doing P0+P1）

- **v0.4.0 Phase 1+2 修复真正生效** — D-v41-P0-3 修 daemon cache + D-v41-P0-1 删底部段 = 14 obra skill 装上→load→生效
- **silent-failure-hunter 自身减负** — D-v41-P0-1 删底部 DEPRECATED 段，文件 7899B → ~7200B, **+800B 缓冲**（meta-irony 解除）
- **mavis/agent.md + AGENTS.md 不再引用已删 brainstorming** — D-v41-P0-2 + D-v41-P0-6 一起改，3 处引用 0 命中
- **daemon-side CJK 串行化修复** — D-v41-P0-4 修后, 12 个 live agent 的中文 systemPrompt 全部可读；cluster A 4 skill description 在 daemon 端保持 UTF-8
- **PS 5.1 UTF-8 修复诚实承认** — D-v41-P0-5 recipe 显式标注限制 + 推荐 pwsh-c.py helper，meta-writer 自我诚实
- **planner agent 恢复 daemon registry** — D-v41-P0-7 修后, plan-workflow 流水线 step[2] 可正常 spawn planner
- **Loading Map 漂移短期缓解** — D-v41-P1-3 加 DEPRECATED 警告，developer 看到表知道看 agent.md frontmatter
- **v0.4.0 P0 升级为实际生效** — v0.4.0 D-P0-1 / D-P0-3 / D-P0-7 / D-P0-NEW-1 通过 v0.4.1 D-v41-P0-3/4/7 真正打通

### 4.2 负面 / 风险

| 风险 | 影响 | 缓解 |
|------|------|------|
| **D-v41-P0-3 daemon file watcher 性能** | mavis 启动时自动 reload 13 agent = 启动慢 1-2s | 可配置 `enable_file_watcher: false`，manual 走 `mavis agent refresh` |
| **D-v41-P0-3 强制 reload 改用户预期** | 用户改完 agent.md 不再需要重启 MiniMax Code.exe | 文档化 (release notes) + `mavis agent health` 输出新字段 |
| **D-v41-P0-4 修 daemon CJK 可能 break 现有 12 agent 的 systemPrompt 解析** | 历史 plan 的 agent spawn 失败 | 先在 test 环境验证 5 个 agent, 灰度 rollout |
| **D-v41-P0-7 恢复全局 planner 可能与项目级 planner 冲突** | repo 内 plan 走全局还是项目级？ | init skill 加 disclaimer "项目级 plan 由项目内 rein/planner 处理, 全局 plan 用全局 planner" |
| **D-v41-P1-1 frontmatter 改 agent.md schema** | 老 agent.md 解析失败 | 加 `requires_skills` 缺省值 = `[]` (不破坏老 agent.md)，顺序: D-v41-P0-1 → D-v41-P1-1 |
| **D-v41-P1-2 skill-routing 转 skill 可能与现有 4 cluster skill 描述冲突** | LLM 看到 skill-routing 误判 cluster | skill-routing description 显式 "决策树辅助，不替代 cluster skill" |
| **D-v41-P0-1 删底部 DEPRECATED 段破坏 git log 可读性** | 4 agent 历史有底部段（已 deprecated） | git log 保留 commit ce4435d 历史（DEPRECATED 段当时加的 commit），删底部段是 new commit |
| **D-v41-P0-5 recipe 修订暴露 meta-writer v0.4.0 修复不完整** | meta-writer 公开承认 partial fix | **这正是 single-writer 铁律要求** — "知道的不全 = 写下来" |

### 4.3 不做的代价（如果不修）

- **不修 D-v41-P0-1**: 4 agent systemPrompt **永久**含 2 份 must-load 段 = ~2800 字节 daemon 进程级浪费 + LLM 注意力分散（U 型曲线中段衰减）
- **不修 D-v41-P0-2**: mavis 启动时**永远**尝试 load 已删 obra brainstorming，silent fail（fallback 到 builtin 或 skip）
- **不修 D-v41-P0-3**: v0.4.0 Phase 1+2 修复**永久**对 daemon = 0 生效（cache 不刷新 = 写了等于没写）
- **不修 D-v41-P0-4**: 12 个 live agent 的中文 systemPrompt **永久**在 daemon 视角下是乱码 = 5+ 周中文工作白做（v0.4.0 D-P0-NEW-1 latent 永远 latent）
- **不修 D-v41-P0-5**: PS 5.1 UTF-8 修复**永久**被用户当"已修"使用，每次 mavis 委派中文 task 仍 mojibake，meta-writer v0.4.0 修复被误认为有效
- **不修 D-v41-P0-7**: planner agent **永久**从 daemon registry 缺失, plan-workflow 流水线 step[2] 永远 spawn 失败
- **不修 D-v41-P1-1**: v0.4.0 D-P1-v4-8 永远 latent，14 obra skill 触发率 = 0%

### 4.4 顺序敏感图（critical path）

```
D-v41-P0-1 (删 4 agent 底部段) ──────┐
                                      ├──→ D-v41-P1-1 (frontmatter requires_skills)
D-v41-P0-3 (daemon cache refresh) ───┤
                                      ├──→ D-v41-P1-1
D-v41-P0-4 (daemon CJK 修复) ────────┘

D-v41-P0-2 (mavis+AGENTS 删 brainstorming) ── 独立（30 min 单 commit）
D-v41-P0-5 (recipe 修订) ──────────────────── 独立（30 min 单 commit）
D-v41-P0-6 (spec-miner 删 strikethrough) ───── 独立（10 min）
D-v41-P0-7 (planner registry 恢复) ─────────── 独立（FEEDBACK H-1）

D-v41-P1-1 (frontmatter) ──→ D-v41-P1-3 (SKILLS.md 标记废弃)
                          ──→ D-v41-P1-4 (verification-loop body 改)
```

**并行窗口**：
- Week 1 Day 1-2: D-v41-P0-1 + D-v41-P0-2 + D-v41-P0-5 + D-v41-P0-6 并行（meta-writer 1 人改 4 文件）
- Week 1 Day 3-5: D-v41-P0-3 + D-v41-P0-4 + D-v41-P0-7 并行（daemon maintainer + release-manager + meta-writer 配对）
- Week 2: D-v41-P1-1 + D-v41-P1-2 + D-v41-P1-3 + D-v41-P1-4 + D-v41-P1-5 并行

### 4.5 meta-writer self-repair 影响

**v0.4.1 自我修范围（meta-irony）**：
- D-v41-P0-1 删 meta-writer 自己的 agent.md 底部 DEPRECATED 段
- D-v41-P0-2 meta-writer 改 mavis/agent.md + AGENTS.md 引用删除
- D-v41-P0-5 meta-writer 改自己 v0.4.0 commit 53886ca 写的 recipe（诚实承认 partial）
- D-v41-P0-6 meta-writer 改 spec-miner/agent.md
- D-v41-P1-2 meta-writer 把 skill-routing.md 转 skill（迁移自己的 KNOWLEDGE 产物）
- D-v41-P1-3 / D-v41-P1-4 / D-v41-P1-5 meta-writer 改 SKILLS.md + 4 cluster skill
- D-v41-P3-1 meta-writer 写 user memory 承认 partial fix

**单 commit 风险**：所有 meta-writer 改的 commit 都在 mvs_<自己> session 落地，single-writer 铁律贯彻。

---

## 5. Alternatives Considered（替代方案）

> 每个 v0.4.1 P0 决策考虑过哪些替代方案 + 为什么最终没选
> **v0.4.1 是新决策，alternatives 独立**——不抄 v0.4.0 ADR 的 alternatives

### D-v41-P0-1 替代方案（4 agent 顶部+底部去重）

| 方案 | 描述 | 不选理由 |
|------|------|----------|
| **A. daemon 加载 agent.md 时检测 `DEPRECATED` 字眼 → 自动 skip** | daemon-side 智能跳过 | 隐藏问题, 后续若有人改底部 DEPRECATED 段, daemon 跳过 = 改动 = 0 生效 |
| **B. 4 agent 底部 DEPRECATED 段加 `<deprecated>` XML 标记，daemon 解析时跳过** | XML 标记 | LLM 不解析 XML, 复杂化 schema, 工程量大 |
| ✅ **C. 4 agent 直接删底部 DEPRECATED 段（已选）** | 简单、彻底、git log 保留历史 | — |

### D-v41-P0-2 替代方案（mavis+AGENTS 删 brainstorming 引用）

| 方案 | 描述 | 不选理由 |
|------|------|----------|
| **A. 恢复 obra brainstorming skill** | 反向撤销 obra 删除 | 用户 2026-06-24 主动删 obra brainstorming，撤销违反用户意图 |
| **B. mavis/agent.md 改用 builtin `brainstorming` 引用** | 走 mavis builtin fallback | builtin 还在 `~/.mavis/.builtin-skills/`，但**显式引用内置**增加耦合（v0.4.0 D-P1-v4-2 完整修复删 builtin 才彻底）|
| ✅ **C. 直接删 mavis + AGENTS + spec-miner 4 处引用（已选）** | 简单、与 v0.4.0 D-P1-v4-2 兼容 | — |

### D-v41-P0-3 替代方案（daemon cache invalidation）

| 方案 | 描述 | 不选理由 |
|------|------|----------|
| **A. 用户每次改完 agent.md 手动重启 MiniMax Code.exe** | 维持现状 + 文档化 | human in loop, 永远会忘 (silent-failure-hunter 已证伪)；v0.4.0 4 commit 全军覆没就是这原因 |
| **B. daemon 加 mavis config `disable_cache: true` 强制每次 spawn 重新读盘** | 改 config | 性能下降 30% (实测 load 4KB file × 13 agent × 每 task 重新读) |
| ✅ **C. daemon 加 `mavis agent refresh <name>` 命令 + 启动时自动 reload（已选）** | 显式 + 自动 | — |
| **D. daemon 加 file watcher 自动 reload** | 实时同步 | mavis 实现可能不支持 file watcher, 需评估；性能风险（mtime 监控 N 个文件） |

### D-v41-P0-4 替代方案（daemon CJK 修复）

| 方案 | 描述 | 不选理由 |
|------|------|----------|
| **A. 用户层用纯 ASCII 写 agent.md** | 强制所有 CJK 改用拼音/英文 | 损失可读性 + 用户用中文写覆盖层是合理需求 |
| **B. 在 mavis agent info 出口做 CJK 替换回写** | daemon 输出前用 Python 做 GBK→UTF-8 修复 | 治标不治本, 真实问题是 daemon 加载 agent.md 时已经损坏 |
| **C. 改用 base64 存 agent.md 避免编码问题** | 编码无关方案 | 不可读, 失去 "agent.md 是用户可读文件" 的核心特性 |
| ✅ **D. 修 daemon 加载 agent.md 的字符编码路径 (已选)** | 找根因 (疑似 latin-1 / buffer 截断), 修源码 | — |

### D-v41-P0-5 替代方案（PS 5.1 recipe 修订）

| 方案 | 描述 | 不选理由 |
|------|------|----------|
| **A. 不修订 recipe，假装 v0.4.0 修复完整** | 维持 v0.4.0 commit 53886ca 原貌 | 违反 single-writer 铁律（知道的不全 = 必须写下来）；用户在 PowerShell 5.1 委派中文 task 仍 mojibake |
| **B. recipe 写 "v0.4.0 修复完整，无需修订"** | 公开撒谎 | 严重违反 v0.4.1 ADR honesty 原则；v0.4.0 3 视角综合已确认 PS 5.1 latent |
| ✅ **C. recipe 显式承认 PS 5.1 限制 + 推荐 pwsh-c.py helper（已选）** | 诚实 + 实用 | — |

### D-v41-P0-6 替代方案（spec-miner 删 strikethrough）

| 方案 | 描述 | 不选理由 |
|------|------|----------|
| **A. 保留 strikethrough + 加 "DEPRECATED" HTML 注释** | 给 LLM 视觉提示 | LLM 不解析 HTML 注释语义, 仍可能误解 |
| **B. 改用 `<deprecated>` XML 标记** | 严格结构化 | LLM 不解析 XML, 复杂化 schema |
| ✅ **C. 直接删除 strikethrough 行（已选）** | 简单、彻底 | — |

### D-v41-P0-7 替代方案（planner registry 恢复）

| 方案 | 描述 | 不选理由 |
|------|------|----------|
| **A. 项目级 `.harness/reins/planner/` 覆盖全局** | 走 mavis reins 机制 | v0.4.1 reins 还没成型, 跨 release scope |
| **B. 把 planner 合并到 spec-miner agent** | 减少 agent 数 | 违反接口分离, spec-miner = 需求挖掘, planner = 计划输出, 职责不同 |
| **C. 用 mavis 路由 fallback 到 general 代替 planner** | 删 planner 引用 | general 是 stub 兜底, 客串 specialist 违反架构边界 |
| ✅ **D. 恢复全局 planner + 删项目级 (继承 v0.4.0 D-P0-1)** | 1 行 fix, source-of-truth 单一 | — |

### D-v41-P1-1 替代方案（frontmatter requires_skills）

| 方案 | 描述 | 不选理由 |
|------|------|----------|
| **A. 保留 SKILLS.md Loading Map + 加 daemon 强制** | 文档 + 代码双轨 | 容易漂移 (RC-v41-3) |
| **B. Loading Map 全部 daemon 内置 (agent 不可声明 skill)** | daemon 统一 | 用户无法扩展 |
| ✅ **C. 改用 agent.md frontmatter `requires_skills:` (继承 v0.4.0 D-P1-v4-8)** | 声明式、daemon 强制 | — |

### D-v41-P1-2 替代方案（skill-routing.md 转 skill）

| 方案 | 描述 | 不选理由 |
|------|------|----------|
| **A. skill-routing.md 改名为 `skill-cluster-routing.md` + 加 disclaimer** | 明确"developer doc 不是 skill" | 4 cluster 拆分对 LLM **永远**是 dead doc，文档可读但 LLM 不触发 |
| **B. 把 4 cluster 决策树写进 mavis/agent.md 路由表** | mavis 是 root orchestrator, 必须看 | mavis/agent.md 已经 God Module (architect M-2)，再加决策树 = 更糟 |
| **C. daemon 启动时读 `~/.mavis/.builtin-skills/cluster-routing.md` 自动注入到 mavis systemPrompt 前缀** | daemon 内置 cluster 决策 | 工程量大, 需评估 daemon 实现 |
| ✅ **D. skill-routing.md 转 skill（已选）** | LLM 可触发、description 路由清晰 | — |

---

## 6. Implementation（实施步骤）

### 6.1 2 周落地路径（v0.4.1 收缩到 2 周，因 meta-writer 1 人 + 部分依赖 daemon maintainer）

```
Week 1: P0 阻塞修复（critical path）
  ├─ D-v41-P0-1   删 4 agent 底部 DEPRECATED 段            [meta-writer + coder]   1h
  ├─ D-v41-P0-2   mavis/agent.md + AGENTS.md 删 brainstorming  [meta-writer]      30min
  ├─ D-v41-P0-5   recipe 修订诚实承认 PS 5.1 限制         [meta-writer]           30min
  ├─ D-v41-P0-6   spec-miner 删 strikethrough              [meta-writer]           10min
  ├─ D-v41-P0-3   daemon cache refresh + agent health    [daemon maintainer]   8h  ★
  ├─ D-v41-P0-4   daemon CJK 修复                          [daemon maintainer]   8h  ★
  └─ D-v41-P0-7   planner agent registry 恢复              [release-manager]    1h

Week 2: P1 scope + 验证 + 收尾
  ├─ D-v41-P1-1   frontmatter requires_skills              [daemon + meta-writer] 6h
  ├─ D-v41-P1-2   skill-routing.md 转 skill                [meta-writer + architect] 2h
  ├─ D-v41-P1-3   SKILLS.md Loading Map 标记废弃           [meta-writer]          15min
  ├─ D-v41-P1-4   verification-loop SKILL.md body 改一致    [meta-writer]          1h
  ├─ D-v41-P1-5   recipe 路径引用修对                      [meta-writer]          10min
  ├─ 跑 plan_d61beff7 重放测试 (3 视角综合后 + v0.4.1 修复) [verifier]            4h
  ├─ 实测 D-v41-P0-3 daemon refresh 生效                  [verifier]            2h
  ├─ 实测 D-v41-P0-4 CJK 修复                             [verifier]            2h
  ├─ 实测 D-v41-P0-7 planner registry                     [verifier]            1h
  ├─ 实测 D-v41-P0-1 4 agent must-load 段去重              [silent-failure-hunter] 2h
  └─ 写 v0.4.1 release notes + commit meta-writer self-repair [meta-writer]       2h
```

★ = daemon-side 改动（依赖 daemon maintainer，Week 1 critical path）

### 6.2 验收 checklist

#### Critical path（必须全过才能 release v0.4.1）

- [ ] **D-v41-P0-1**: 4 agent grep `DEPRECATED` 0 命中；silent-failure-hunter 字节数 ≤ 7400B
- [ ] **D-v41-P0-2**: mavis/agent.md + AGENTS.md + spec-miner/agent.md grep `brainstorming` 0 命中
- [ ] **D-v41-P0-3**: `mavis agent refresh silent-failure-hunter` 后 `mavis agent info` systemPrompt 反映最新文件；`mavis agent health` 输出 13 行
- [ ] **D-v41-P0-4**: 5 个有 CJK 覆盖层的 agent CJK count > 50，mojibake_count = 0；cluster A 4 skill description 在 daemon 端保持 UTF-8
- [ ] **D-v41-P0-5**: recipe 顶部"已知限制"段存在；recipe 验证步骤 1 不再期望 OutputEncoding.CodePage=65001
- [ ] **D-v41-P0-6**: spec-miner/agent.md grep `~~` 0 命中
- [ ] **D-v41-P0-7**: `mavis agent info planner` 返回 ≥ 2000B；`mavis agent list` 13 个

#### 完整 release

- [ ] **D-v41-P1-1**: 4 stub agent `requires_skills:` frontmatter 正确，daemon 强制 load
- [ ] **D-v41-P1-2**: `mavis skill list | grep routing` 1 条
- [ ] **D-v41-P1-3**: SKILLS.md line 191 区域含 DEPRECATED 警告
- [ ] **D-v41-P1-4**: verification-loop SKILL.md body 跟 description 一致
- [ ] **D-v41-P1-5**: recipe 路径引用可点击
- [ ] 跑 plan_d61beff7 重放测试全过
- [ ] 3 视角综合 verdict 全部修复（再跑一次 3 视角 review, 期望 v0.4.1 后 finding 数 ≤ 5）

### 6.3 Owner 分配

| 角色 | 拥有 v0.4.1 P0 | 拥有 v0.4.1 P1 | 备注 |
|------|---------------|---------------|------|
| **meta-writer** | D-v41-P0-1, D-v41-P0-2, D-v41-P0-5, D-v41-P0-6 | D-v41-P1-2, D-v41-P1-3, D-v41-P1-4, D-v41-P1-5 | 1 人改 8 个文件 |
| **coder** | D-v41-P0-1 辅助（脚本生成）| — | 写 1 行 sed 脚本删 4 文件底部段 |
| **daemon maintainer** | D-v41-P0-3, D-v41-P0-4 | D-v41-P1-1 | daemon 核心改动 |
| **release-manager** | D-v41-P0-7 | — | FEEDBACK H-1 跟进 |
| **architect** | — | D-v41-P1-2 配对 | skill-routing 决策树审稿 |
| **verifier** | — | Week 2 验收 | 3 视角综合后实测 |
| **silent-failure-hunter** | — | Week 2 验收 | 4 agent 顶部+底部去重实测 |

### 6.4 风险 mitigation

- **D-v41-P0-3 daemon file watcher 性能** → 可配置 `enable_file_watcher: false`，manual 走 `mavis agent refresh`
- **D-v41-P0-4 修 daemon CJK 可能 break 现有 12 agent 解析** → 先在 test 环境验证 5 个 agent, 灰度 rollout
- **D-v41-P0-7 恢复全局 planner 可能与项目级 planner 冲突** → init skill 加 disclaimer
- **D-v41-P1-1 frontmatter 改 agent.md schema** → 缺省值 `[]` 兼容老 agent.md，顺序: D-v41-P0-1 → D-v41-P1-1
- **D-v41-P0-5 recipe 修订暴露 meta-writer v0.4.0 修复不完整** → **这正是 single-writer 铁律要求** — 知道的不全 = 写下来
- **D-v41-P0-7 是 FEEDBACK H-1（用户开 issue）** → release-manager 跟踪 issue 状态, 不阻塞 v0.4.1 release（可后续 commit）

---

## 7. References

### 7.1 3 视角 v0.4.0 Phase 1+2 审查报告（v0.4.1 输入）

- `C:\Users\22923\.mavis\plans\plan_d61beff7\outputs\review-verifier-v040-phase2\deliverable.md` (351 行 / 12 finding / 3C+4H+4M+1L / VERDICT: FAIL)
- `C:\Users\22923\.mavis\plans\plan_d61beff7\outputs\review-architect-v040-phase2\deliverable.md` (461 行 / 13 finding / 4C+5H+3M+1L / B- (72/100))
- `C:\Users\22923\.mavis\plans\plan_d61beff7\outputs\review-silent-failure-v040-phase2\deliverable.md` (540 行 / 13 finding / 5C+6H+2M / 7 pattern 穷举)

### 7.2 前置 ADR

- `D:\MiniMax_workSpace\default_workSpace\Efficient-MiniMaxCode\docs\OPTIMIZATION-v0.4.0-ADR.md` (1001 行 / 50 决策 = 10 P0 + 17 P1 + 17 P2 + 6 P3)
- `D:\MiniMax_workSpace\default_workSpace\Efficient-MiniMaxCode\docs\OPTIMIZATION-v0.3.0-ADR.md` (595 行 / 22 RC / 31 决策)

### 7.3 v0.4.0 Phase 1+2 4 commit

- `754b3c1` fix(agents): v0.4.0 Phase 1 P0 fixes (D-P0-2 / D-P0-6 / D-P0-NEW-3)
- `6570d40` fix(spec-miner): drop brainstorming must-load ref
- `53886ca` docs+skills: v0.4.0 Phase 2 audit fixes (skill routing + cluster A boundary + PS5 UTF-8 recipe)
- `ce4435d` fix(agents): must-load 段位置统一 (4 agent 底部→顶部, v0.4.0 D-P0-NEW-3)

### 7.4 历史 plan

- `plan_0ee903db`: v0.3.0 升级后 3 视角审查 + v0.4.0 ADR 合成 (completed)
- `plan_d61beff7`: **当前** (v0.4.0 Phase 1+2 3 视角审查, in_progress)
- `plan_d8bb16f4`: **当前 plan** (v0.4.1 ADR follow-up 合成, in_progress)

### 7.5 mavis 关键文件

- `C:\Users\22923\.mavis\agents\` (12 live + 1 .bak/planner)
  - `silent-failure-hunter/agent.md` = 7899B (meta-writer 自身 on-the-edge)
  - `build-error-resolver/agent.md` = 5595B
  - `code-simplifier/agent.md` = 6293B
  - `meta-writer/agent.md` = 5443B
- `C:\Users\22923\.mavis\skills\` (44 user skill, 含 14 obra)
  - `verification-loop/SKILL.md` description 含 cluster A 边界但 body 不一致
- `D:\MiniMax_workSpace\default_workSpace\Efficient-MiniMaxCode\agents\` (13 in repo)
- `D:\MiniMax_workSpace\default_workSpace\Efficient-MiniMaxCode\AGENTS.md` (line 34/76/151 仍引 brainstorming)
- `D:\MiniMax_workSpace\default_workSpace\Efficient-MiniMaxCode\docs\OPTIMIZATION-v0.4.0-ADR.md` (1001 行, v0.4.0 ADR)
- `D:\MiniMax_workSpace\default_workSpace\Efficient-MiniMaxCode\docs\RECIPES\windows-powershell-utf8-zhcn.md` (recipe 待修订)

### 7.6 user_profile 引用

- **"Self-evaluation 不可靠 — 必须多 Agent 视角"** (cross-project, 支撑 v0.4.1 3 视角综合方法)
- **"Solo developer"** (影响 owner notification 设计——不需要 team 通知通道)
- **"PowerShell 5.1 Set-Content -Encoding UTF8 silently corrupts CJK"** (cross-project, 支撑 D-v41-P0-5 recipe 修订诚实承认)
- **"Mavis 工具链 PowerShell 5.1 中文乱码 — 委派时中文 prompt 不干净"** (cross-project, 支撑 D-v41-P0-5 已知限制段 + D-v41-P3-1 监控)
- **"Parallel-write 边界 — 并行委派不能修改同个文件"** (支撑 v0.4.1 不并行改同文件 — 顺序敏感图显式)

---

## 8. Meta（meta-writer 单一作者声明 + 自我反思）

### 8.1 v0.4.1 ADR single-writer 铁律执行

- **本 ADR 是 v0.4.0 → v0.4.1 的 single-writer 合成** — 3 视角 38 raw finding → 11 root cause → 7 P0 + 5 P1 + 10 P2 + 7 P3 = 29 决策
- **没有添加任何新 finding** — 所有结论都能追溯到 3 视角原始报告的 file_path:line（见 § 2.3 跨视角去重映射表）
- **v0.4.0 ADR 已修项标 ✅ 不重写** — D-P0-2 / D-P0-6 / D-P0-NEW-3 等 5 条部分修的，本 ADR 不复制内容，只标 v0.4.1 收尾动作
- **每个 P0/P1 都有 owner + 步骤 + 验收 + 风险 mitigation** — 可直接执行
- **alternatives considered 独立** — v0.4.1 是新决策, alternatives 不抄 v0.4.0 ADR
- **顺序敏感图显式标注** — D-v41-P0-1 + D-v41-P0-3 → D-v41-P1-1; D-v41-P0-2/5/6/7 独立并行

### 8.2 meta-irony 标记

- **D-v41-P0-1** 删的 4 agent 包含**本 ADR 的作者** (meta-writer 自己的 agent.md 5443B) — **本 ADR 在自我修范围内**
- **D-v41-P0-2** 删的 mavis/agent.md 是 root orchestrator, meta-writer 改 mavis 等于 meta-writer 改自己体系
- **D-v41-P0-5** 修订的 recipe 是 meta-writer v0.4.0 commit 53886ca 写的 — **meta-writer 必须诚实承认自己之前的修复是 partial** (single-writer 铁律)
- **D-v41-P0-6** 删的 spec-miner 引用是 mavis 路由核心 agent, 改完等于改 mavis 路由表
- **D-v41-P0-7** 恢复的 planner 是 spec-miner 下游 (AGENTS.md "需求不清楚 → spec-miner → planner" 链)
- **D-v41-P1-1** 实施的 frontmatter 是 v0.4.0 D-P1-v4-8 提议, v0.4.1 跟进 — meta-writer 跟进自己 v0.4.0 ADR
- **D-v41-P1-2** 转的 skill-routing.md 是 v0.4.0 commit 53886ca meta-writer 写的文档 — **meta-writer 改自己 v0.4.0 产物**
- **D-v41-P3-1** 写 user memory 承认 partial fix — **meta-writer 必须诚实地记**

### 8.3 综合过程自我反思

这次综合 (v0.4.0 Phase 1+2 → v0.4.1 follow-up) **做对的地方**：

1. **3 视角交叉点 = 高置信 root cause** — 不并行列所有 finding，而是用 § 2.3 跨视角去重映射表让共识 / 单视角独有 一目了然
2. **顺序敏感图显式** — v0.4.0 ADR 已有这图, v0.4.1 继续保留, critical path 不模糊
3. **meta-irony 显式标注** — meta-writer 自我修范围 + 诚实承认 partial fix (D-v41-P0-5), **single-writer 铁律"知道的不全 = 写下来"**
4. **3 视角共识 vs 单视角独有 分离** — RC-v41-1 (3 视角) vs RC-v41-11 (1 视角 architect H-5) 严重度不同, 决策不同
5. **v0.4.0 50 决策落地状态直接列** — § 1.3 表格让"什么修了 / 什么 latent / v0.4.1 收什么"清晰

**可优化的地方**（下次综合时改进）：

1. **耗时预估偏低** — v0.4.0 ADR meta-writer self-repair 段说"30 min 单 commit", 实际 4 commit 全套下来 1-2h (含 review + push)
2. **daemon-side 改动 owner 高度依赖 daemon maintainer** — D-v41-P0-3 + D-v41-P0-4 都卡 daemon maintainer, 若 maintainer 不可用, v0.4.1 release 阻塞 2 周
3. **P2 10 条数量多** — 部分 P2 (M-1 / M-2 / M-4) 应该是 v0.5+ 范围, 不应该塞 v0.4.1 P2 backlog — 下次综合 P2 控制在 ≤ 5 条
4. **D-v41-P0-3 / D-v41-P0-4 都是 daemon maintainer 改** — 没考虑若 maintainer 不在, 用户自己能不能改 (PS 5.1 委派子 agent 改 daemon 风险)
5. **没在 ADR 里写"如何验证 v0.4.1 真的修了 v0.4.0 latent"** — 应该加一段"v0.4.1 release 后再跑一次 3 视角审查, 期望 finding 数 ≤ 5"作为 v0.4.1 验收

**v0.4.1 vs v0.4.0 评分预期**：

| 维度 | v0.4.0 真实分 (3 视角综合) | v0.4.1 目标分 |
|------|---------------------------|---------------|
| 4 agent 顶部+底部重复 | 4/13 agent (31%) | 0/13 (100%) |
| silent-failure-hunter 临界 | 7899B / 8000B (101B 缓冲) | ≤ 7400B (+500B 缓冲) |
| Loading Map 漂移 | 4/4 处全 drift | 0/4 (D-v41-P1-1 实施) |
| mavis/agent.md 引 brainstorming | 1 处 (line 9) | 0 处 |
| AGENTS.md 引 brainstorming | 3 处 (line 34/76/151) | 0 处 |
| daemon displayName CJK | 8 agent 全坏 | 0 (D-v41-P0-4 修) |
| daemon cache invalidation | 不存在 (cache 永久) | 可 refresh (D-v41-P0-3 修) |
| planner registry | 缺失 | 13/13 (D-v41-P0-7 修) |
| PS 5.1 UTF-8 修复 | 假装修，实际 partial | 诚实承认 + 推荐路径 (D-v41-P0-5) |
| cluster A 描述互斥 | 1/4 划清 (verification-loop) | 4/4 (D-v41-P1-2 + D-v41-P1-4) |
| **综合评分** | **v0.4.0 ADR 6.0+/10 目标实际 0/10 生效 (3 视角证伪)** | **目标 5.0+/10 真正生效** |

**v0.4.1 不追求 6.0+**，因为 daemon 改动（D-v41-P0-3 / D-v41-P0-4）依赖外部 owner，**保守预期 5.0+/10 真正生效**。

### 8.4 v0.4.1 → v0.4.2 衔接

v0.4.1 修完后，下一次综合（v0.4.2）应关注：
- v0.4.1 P1 5 条实施结果（frontmatter / skill-routing / SKILLS.md / verification-loop / recipe 路径）
- v0.4.0 P1 17 条（继承）实际修了几条
- meta-writer 11 类元信息只 2 类存在 — 补全 DECISIONS / KNOWLEDGE / FAQ 等
- mavis/agent.md God Module 拆分
- daemon WARN 噪声 (RC-v16) — 监控升级

---

**END OF v0.4.1 ADR**

下一步：用户决策 → 接受 / 拒绝 / 修改 → release-manager + daemon maintainer + meta-writer 启动 v0.4.1 实施

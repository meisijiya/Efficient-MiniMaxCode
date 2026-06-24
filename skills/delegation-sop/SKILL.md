---
name: delegation-sop
description: Cross-orchestrator delegation SOP for the Mavis toolchain. Trigger when an agent (mavis or any future orchestrator) needs to delegate work to sub-agents via mavis CLI / plan engine / scratchpad pointer. Encodes the 3-tier routing (plan engine / spawn command / scratchpad pointer) that survives three documented Mavis bugs: PS 5.1 中文 content escaping, agent update silent-drop >8000B, and spawn-without-prompt silent default. Trigger keywords: 委派, 委派规则, delegation, delegate, spawn worker, mavis team plan, communication send, 中文 prompt 转义, PS 5.1 escape, hardcode yaml, scratchpad pointer, kebab-case task-id.
---

# Delegation SOP

Single source of truth for how any Mavis orchestrator hands work to sub-agents without losing content along the way.

## Why this skill exists

Three documented Mavis toolchain bugs make naive delegation unreliable:

1. **`mavis agent update` / `mavis agent new` > 8000 B silent drop** — file write silently truncates around 8000 bytes; daemon does not raise an error.
2. **`mavis communication send --content "<multi-line Chinese>"`** — Windows PowerShell 5.1 argument parser corrupts multi-line Chinese content (spaces, quotes, BOM, line continuations). The command may appear to succeed but the worker receives garbled or empty content.
3. **Spawn without prompt** — `mavis communication send --command spawn` without a `--content` (or with empty content) leaves the worker with no task definition and silently defaults.

This skill encodes the 3-tier routing that survives all three.

## MiniMax Code platform constraints

Delegation on MiniMax Code has additional quirks that this skill assumes you already know:

| Constraint | Behavior | Implication for delegation |
|------------|----------|---------------------------|
| **OpenCode is the default engine** | Daemon spawns workers via OpenCode runtime; worker receives `agent.md` as system-prompt overlay | Every agent must self-declare its `must-load skills` in `agent.md` — silent omission = skill not loaded |
| **`mavis agent new` only writes sqlite when CLI is used** | Direct file write to `~/.mavis/agents/<name>/agent.md` does NOT register in sqlite → daemon doesn't see it on restart | Always go through `mavis agent new` (without `--system-prompt`) for new registrations |
| **Daemon restart only re-reads sqlite, not disk** | Restarting MiniMax Code.exe won't pick up disk-only files | After disk edit, run `mavis agent list` to confirm registered; if not, re-register |
| **`mavis agent update --system-prompt` triggers daemon bug** | Agent.md content >8000B silently drops; or full content not preserved across update | **Never** use `mavis agent update` for prompt edits — use Edit/Write tools directly |
| **PS 5.1 + UTF-8 + Windows default code page** | `Get-Content` / `Set-Content` without `-Encoding UTF8` silently corrupts CJK | Always use Read/Write/Edit tools (UTF-8 native) for file content ops; never pipe through PS |

## 3-tier routing

| Scenario | Tool | Content transport | Why this works |
|----------|------|-------------------|----------------|
| **Multi-task / complex delegation** (≥2 workers, parallel, depends_on graph) | `mavis team plan run <yaml>` | Hardcode prompt into YAML `tasks[].prompt` block (or `>-` folded scalar for multi-line) | YAML is parsed by daemon, not CLI args. Engine has heartbeat + CycleReports + auto_retry. |
| **Single-shot audit / lightweight verify** (1 worker, ad-hoc) | `mavis communication send --command spawn --content "<kebab-task-id>"` | Pass ASCII task-id only; worker reads full prompt from `$MAVIS_SCRATCHPAD/<id>.md` | CLI boundary stays ASCII-safe; full prompt never crosses the wire. |
| **Ad-hoc reminder / small notification** | Write `$MAVIS_SCRATCHPAD/<task>.md`, then `mavis communication send --command prompt --content "Read $MAVIS_SCRATCHPAD/<task>.md"` | Path string crosses the wire; worker fetches content via file API | File API is UTF-8 safe; PS escape rules don't apply to file paths. |

## Forbidden patterns

- ❌ `mavis communication send --content "<multi-line Chinese prompt>"` — guaranteed PS 5.1 escape breakage.
- ❌ `mavis agent update --content "<large Chinese prompt>"` — silent drop + daemon bug.
- ❌ `mavis agent new` for any content where final file > 8000 B — same silent drop.
- ❌ Spawn without prompt + without scratchpad pointer — worker has no task and silently defaults.

## Verification SOP (anti-silent-drop)

Every delegated worker MUST, in its first reply, echo exactly one line:

```
task-id = <X> / 读自 <Y>
```

where `<Y>` is one of:
- `plan outputs/<X>/prompt.md` (plan engine route)
- `$MAVIS_SCRATCHPAD/<X>.md` (scratchpad route)

If the worker does NOT echo this line within 60 s, treat as silent-drop:
1. Verify the source file exists on disk (Read tool).
2. If file exists → worker prompt-loading bug → escalate to user.
3. If file missing → write failed → re-write + re-notify.
4. Do NOT silently retry with a different escape format — that path leads to 2x silent drops.

## Failure escalation

- Same prompt fails to deliver 2× → escalate to user (not silent retry).
- Worker says "no task received" / hangs → check scratchpad file exists (`Test-Path`); file present = worker bug (escalate), file absent = write bug (re-write + notify).
- Plan engine task stuck > hang_alert_after_ms → use `mavis team plan steer` or `extend-timeout`; do not cancel unless truly dead.

## Silent-drop downgrade ladder

When a delegation silently fails, walk this ladder — do not improvise a new escape format (each retry multiplies the failure rate):

```
Step 1: Detect (0–60s)
  └─ Worker did NOT echo `task-id = <X> / 读自 <Y>` within 60s
     → treat as silent-drop, do NOT assume "still thinking"

Step 2: Diagnose (60s–2min)
  ├─ Read source file at the path worker should have read
  │   ├─ File exists, content correct → worker prompt-loading bug
  │   │   → escalate to user (do NOT retry same path)
  │   └─ File missing OR content garbled → write-side bug
  │       → re-write file via Edit/Write tool (UTF-8 safe)
  │
  └─ If using `mavis communication send --content "..."`
      → assume PS 5.1 escape breakage, IMMEDIATELY switch tier

Step 3: Switch tier (escape-route, do not retry same tier)
  ├─ Was: spawn + --content → switch to: scratchpad pointer + spawn + ASCII task-id
  ├─ Was: scratchpad pointer → switch to: plan engine yaml hardcode
  └─ Was: plan engine yaml → switch to: write to outputs/<id>/prompt.md directly + spawn

Step 4: Escalate after 2 silent-drops on same prompt
  └─ Tell user: "Same prompt silent-dropped 2× across [tier1, tier2].
       Root cause likely: [worker prompt-loading / write-path / cli-escape].
       Do not retry; need your decision on [rewrite prompt | change agent | manual run]."
```

**The two non-negotiables**:
- Never silently retry the same CLI escape format (guaranteed 2nd silent-drop).
- Never switch to a "creative" escape (backslash-continuation, base64, here-string) — those all silently fail too.

## Examples

### Example 1 — 3-agent parallel review (plan engine)

```yaml
# ~/.mavis/plans/v042-review/plan.yaml
version: 1
plan:
  name: v0.4.2 综合评审
  max_concurrency: 3
  max_cycles: 1
  auto_accept: true
tasks:
  - id: review-verifier
    title: '[verifier] ...'
    prompt: |
      Full Chinese prompt here — survives because YAML parses it,
      not the CLI shell.
    assigned_to: verifier
    role: produce
    verified_by: verifier
    depends_on: []
    max_retries: 1
    timeout_ms: 900000
  # ... more tasks
```

```bash
mavis team plan run ~/.mavis/plans/v042-review/plan.yaml
```

### Example 2 — single-shot audit (spawn + scratchpad)

```powershell
# 1. Write prompt to scratchpad (Write tool, UTF-8 safe)
#    Path: $MAVIS_SCRATCHPAD/audit-mvs_xyz.md

# 2. Spawn worker with ASCII-only task-id
mavis communication send `
  --from <my-session> `
  --to <my-session> `
  --command spawn `
  --content 'audit-mvs_xyz'
```

Worker reads `$MAVIS_SCRATCHPAD/audit-mvs_xyz.md` on wake and echoes `task-id = audit-mvs_xyz / 读自 $MAVIS_SCRATCHPAD/audit-mvs_xyz.md`.

### Example 3 — ad-hoc reminder

```bash
echo "fix the foo bug per plan X" > "$MAVIS_SCRATCHPAD/reminder-fix-foo.md"
mavis communication send --to <worker-session> --command prompt --content "Read $MAVIS_SCRATCHPAD/reminder-fix-foo.md"
```

## Field-tested mini-SOPs (2026-06-24)

Three real failures observed and resolved. Use these as templates for similar issues.

### Mini-SOP A: agent registration silent-drop (sqlite not written)

**Symptom**: Wrote `agent.md` to `~/.mavis/agents/<name>/agent.md`, ran `mavis agent list`, new agent not shown. Daemon restart doesn't help.

**Root cause**: `mavis agent new` writes to sqlite only when invoked via CLI with name + meta. Disk-only writes skip sqlite.

**Fix (Node spawnSync to bypass PS escape)**:

```javascript
const { spawnSync } = require('child_process')
const r = spawnSync('cmd.exe', [
  'mavis', 'agent', 'new', '<name>',
  '--engine', 'opencode',
  '--persona', '<persona-string>',
  '--display-name', '<显示名>',
  '--description', '<描述>',
], { encoding: 'utf-8' })
console.log(r.stdout, r.stderr)
```

**Critical**: do NOT pass `--system-prompt` — daemon will read on-disk `agent.md` as overlay and merge into systemPrompt. Passing `--system-prompt` triggers the 8000B silent-drop AND overwrites your disk stub.

### Mini-SOP B: Chinese prompt silent-drop via PS 5.1

**Symptom**: `mavis communication send --command spawn --content "<长中文 prompt>"` returns success but worker receives empty / garbled content.

**Root cause**: PS 5.1 argument parser breaks on multi-line + CJK + quoted strings. Three documented bugs intersect:
- PowerShell strips BOM / line-continuations
- Argument parser mangles nested quotes
- CJK bytes sometimes get ANSI-decoded on roundtrip

**Fix**: never put the prompt in `--content`. Two escape routes:

1. **Plan engine route** (preferred for ≥2 tasks):
   - Write `~/.mavis/plans/<plan-id>/plan.yaml` with `tasks[].prompt:` block (UTF-8 file, no CLI escape)
   - Run `mavis team plan run <yaml>`

2. **Scratchpad pointer route** (for 1 ad-hoc task):
   - Write prompt to `$MAVIS_SCRATCHPAD/<kebab-id>.md` via Write tool (UTF-8 safe)
   - Spawn with ASCII-only task-id:
     ```
     mavis communication send --from <sid> --to <sid> --command spawn --content "<kebab-id>"
     ```
   - Worker reads scratchpad on wake, echoes `task-id = <kebab-id> / 读自 $MAVIS_SCRATCHPAD/<kebab-id>.md`

### Mini-SOP C: plan engine task stuck or synthesis task fails

**Symptom**: `mavis team plan run` shows task stuck > `hang_alert_after_ms` (default 15min), OR final synthesis task fails because `max_cycles` exhausted before synthesis could run.

**Fix**:

1. **Stuck mid-plan**: do NOT cancel. Use `mavis team plan steer <plan-id> --task <task-id> --action extend-timeout --ms 1800000`.
2. **max_cycles hit before synthesis**: in plan.yaml, set `plan.max_cycles: 3+` (safety margin) and `plan.auto_accept: true` for the synthesis task. Synthesis is the LAST task in depends_on chain — it should auto-accept without verifier round.
3. **depends_on not declared**: every task in a chain MUST declare `depends_on: [<前置-task-id>]`. Missing this = race condition = synthesis runs on stale data.

**Verification after fix**: `mavis team plan show <plan-id> --full` shows task statuses. Final synthesis task status `done` = plan complete.

## Quick decision tree

```
Need to delegate X to a sub-agent.
  │
  ├─ X has ≥2 parallel sub-tasks OR depends_on graph?
  │    └─ YES → plan engine (yaml + `mavis team plan run`)
  │
  ├─ X is 1 ad-hoc audit/verify on existing deliverable?
  │    └─ YES → spawn + scratchpad pointer
  │
  ├─ X is a quick reminder/poke to an existing worker?
  │    └─ YES → scratchpad file + path-only --content
  │
  └─ X is something else?
       └─ STOP. Re-read this skill. Do not improvise delegation.
```

## Related

- `mavis` skill — Mavis runtime reference (CLI commands, session management).
- `subagent-driven-development` (obra) — broader sub-agent orchestration patterns.
- `dispatching-parallel-agents` (obra) — when 3+ independent tasks can run in parallel.
- `verification-before-completion` — worker's "evidence before claim" discipline applies to the verification echo above.
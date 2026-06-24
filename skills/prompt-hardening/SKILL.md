---
name: prompt-hardening
description: Make agent prompts and SKILL.md files resist LLM drift. Structural techniques beyond vocabulary (must/never/禁止) — U-shape attention positioning, anchor-to-persona, explicit context windows, anti-example pairs, constraint layering. Trigger when an agent prompt is being repeatedly ignored or weakened by the LLM. Trigger keywords: prompt hardening, prompt 漂移, U 型注意力, 注意力衰减, 强 prompt, 硬约束, anchor, 约束漂移, persona drift.
---

# Prompt Hardening

Make agent prompts and SKILL.md files **resist LLM drift**. Goes beyond vocabulary (see `hard-constraints`) into **structural** techniques that survive long contexts and repeated invocations.

## Why this skill exists

Vocabulary alone (must / never / 禁止) doesn't work in long contexts. Karpathy's U-shape attention observation: LLMs allocate attention unevenly; middle-context gets systematically less. **Hard "must" at the start fades by turn 30.** Prompt hardening fixes this with structure.

## 6 structural techniques

### 1. Anchor to persona at top AND bottom

```
You are <persona>. <single-sentence mission>.
...
<at the end of the file, RESTATE the persona + mission verbatim>
```

**Why**: U-shape means ending is also high-attention. Repeating persona at end doubles the anchor.

### 2. Constraint layering (3-tier)

```
## Hard constraints (NEVER violate)
- ...

## Soft preferences (violate only with explicit reason)
- ...

## Out of scope (delegate / refuse)
- ...
```

**Why**: 3 tiers give the LLM escape valves for soft prefs without breaking hard constraints.

### 3. Anti-example pairs (negative + positive)

```markdown
## X done right
<concrete example>

## X done wrong
<concrete anti-example with explicit "DON'T" callout>
```

**Why**: LLMs pattern-match better with paired examples than abstract rules. The wrong example shows what failure looks like.

### 4. Explicit context window markers

```markdown
## In this session
- Goal: ...
- Spec: <path or 1-line>
- Known issues: ...

## NOT in this session
- <things the agent might assume but shouldn't>
```

**Why**: prevents context drift; the agent knows what's loaded vs not.

### 5. Trigger keywords (frontmatter)

```yaml
---
name: skill-name
description: ...
Trigger keywords: a, b, c, d
---
```

**Why**: when agent loads skill on demand, keywords are how it decides. Vague keywords = skill never loads.

### 6. Cost table for trade-offs

```markdown
| Choice | Cost | Benefit |
|--------|------|---------|
| Reset context | ~5k tokens | Highest review quality |
| Inline review | 0 | Anchored (broken) |
```

**Why**: gives LLM the "why" behind rules. LLMs respect rules more when they see the trade-off rationale.

## Anti-patterns

- ❌ **Hard "must" without structural anchor** — fades in long context
- ❌ **All rules in one flat list** — no tiering; LLM breaks soft rules under pressure
- ❌ **No anti-example** — agent can't pattern-match failure
- ❌ **Keywords too generic** ("code", "test", "help") — never loads; over-specific keywords also never load
- ❌ **Implicit context** — agent assumes what's loaded; you didn't tell it

## When to apply

Trigger prompt hardening when:
- Agent prompt being repeatedly ignored (user re-explains 2+ times)
- Agent prompt > 200 lines (drift inevitable without structure)
- Skill / agent prompt gets edited 3+ times (signal it's not holding)
- Cross-session behavior inconsistent (long-context reset reveals drift)

## Related

- `hard-constraints` — vocabulary level (must / never / 禁止) — pairing with this skill
- `context-reset` — structural technique for review, not for prompt design
- `meta-writer` — apply this when writing ADR / agent.md / SKILL.md
- `create-agent` — apply when designing new agent system prompt
- Karpathy U-shape attention curve — origin of techniques 1 + 4

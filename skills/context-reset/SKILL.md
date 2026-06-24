---
name: context-reset
description: Reset the agent's context window before review or major decisions to escape the "Dumb Zone" (Karpathy U-shape attention curve + Matt Pocock Smart Zone). Trigger when AI implementation and review are happening in the same context — review quality degrades because the LLM is "anchored" to its own implementation. Trigger keywords: context reset, 清空 context, Smart Zone, Dumb Zone, review reset, 重新 review, 注意力衰减, second-pass review, fresh-eyes review, context pollution.
---

# Context Reset

Reset the agent's context window before review or major decisions to escape the Dumb Zone — where the LLM is anchored to its own implementation and review quality degrades sharply.

## Why this skill exists

Two converging insights:

1. **Karpathy U-shape attention curve** — LLMs allocate attention unevenly across long contexts. The "middle" gets systematically less attention. By the time an agent has done implementation + planning + verification, the original spec / problem statement is buried in middle-context and the agent's "anchoring" to its own implementation dominates.
2. **Matt Pocock Smart Zone vs Dumb Zone** — implementation and review are fundamentally different cognitive tasks. Doing them in the same context = Dumb Zone (the LLM reviews what it *intended*, not what's actually there). Reset to Smart Zone = fresh-eyes review.

**Concrete symptom**: agent reviews its own code and approves everything, OR finds only trivial issues while missing real bugs. Same-context review is broken.

## When to trigger

Trigger context-reset BEFORE any of:

| Situation | Why reset |
|-----------|-----------|
| Reviewing implementation you just wrote | Anchoring to "what I meant" |
| Making a major architecture decision after extended exploration | Context polluted with implementation details |
| Producing a final summary / report after multi-hour session | Middle-context drift |
| Cross-session handoff | Fresh session = clean context |
| Verifier reviewing coder's diff after many intermediate steps | Anchoring to original spec instead of current diff |

**Do NOT reset when**:
- Reviewing 3rd-party code you just read for the first time (no anchoring risk)
- Single-step trivial changes (no context pollution yet)
- User explicitly asks for "self-review" or "quick check"

## How to reset (3 modes)

### Mode 1: Cross-session reset (cleanest)

```
1. End current session explicitly
2. Start new session with: "You are a reviewer for a Mavis project.
   The deliverable is at <path>. Do NOT look at any prior conversation —
   read the deliverable + spec fresh. Review for: <criteria>."
3. New session = clean context, Smart Zone
```

Best for: final reviews, architecture decisions, verifier tasks.

### Mode 2: Summary-and-restart (in-session)

```
1. Write a tight summary of current state to scratchpad:
   "## State at reset point
    - Goal: <一句话>
    - Current implementation: <路径>
    - Spec / acceptance criteria: <路径 or 一句话>
    - Known issues: <列表 or none>"
2. End current turn explicitly with: "Context reset. Next turn starts fresh."
3. Next turn: load summary from scratchpad as the ONLY prior context
```

Best for: long sessions where you don't want to lose all state but need a fresh review perspective.

### Mode 3: External reviewer handoff (most rigorous)

```
1. Spawn a NEW agent session (verifier / architect / independent reviewer)
   with: "Read <spec> + <deliverable>. Review adversarially. Output:
   - 3 strengths
   - 3 weaknesses
   - 1 must-fix blocker (if any)"
2. Original session waits for reviewer's deliverable, does NOT participate in review
3. Original session only acts on reviewer's findings
```

Best for: high-stakes decisions (payment / PII / security / production deploys).

## SOP: Pre-review checklist

Before reviewing anything you (or your session) implemented:

```
□ Is the deliverable ≥ 100 lines? → context pollution likely → reset
□ Did you write it > 30 minutes of session ago? → anchoring deepens → reset
□ Are you about to "verify" something you already decided? → reset
□ Will the review's output materially affect the deliverable? → Mode 3 (external)
□ Is this a quick smoke test only? → inline OK, no reset
```

If ≥ 2 boxes ticked: **reset before reviewing**.

## Anti-patterns

- ❌ **Same-context "self-review"** — agent reviews its own code in same session → 80%+ false approvals (Dumb Zone anchoring)
- ❌ **Reviewing after multiple retries** — agent has tried 3 fixes, now reviews the 4th attempt = anchored to "this time it should work"
- ❌ **Long session summary reviews** — agent summarizes what it did, doesn't review what's there
- ❌ **Skipping reset because "I remember the spec"** — the LLM doesn't reliably remember; middle-context drift is real
- ❌ **Resetting too often** — every context reset costs tokens; reset only at decision points, not after every small step

## Cost-benefit

| Mode | Cost (tokens) | Benefit (review quality) | When worth it |
|------|---------------|--------------------------|---------------|
| Mode 1 (cross-session) | ~2-5k session overhead | Highest — completely fresh | Final reviews, architecture decisions |
| Mode 2 (summary-restart) | ~500-1k for summary | Medium-high — anchoring broken | Long sessions, post-implementation review |
| Mode 3 (external reviewer) | ~5-15k for spawn + review | Highest rigor | Payment / PII / security / production |

**Rule of thumb**: for any review that affects production or costs > 1h to fix wrong, use Mode 3. For routine reviews of ≤100-line changes, Mode 2. For "I just want to look at this myself once", Mode 1.

## Field example (2026-06-24)

**Symptom**: After 3 hours of context (silent-drop debugging + ADR writing + skill authoring), `mavis` root orchestrator was about to write a "summary" of tonight's work. Risk: middle-context drift would make the summary miss the actual key decisions.

**Mode chosen**: Mode 2 (summary-restart).

**Implementation**:
1. Wrote summary scratchpad with: 4 silent-drop BUGs / 3 commits / delegation-sop skill / 5 platform quirks
2. Asked user for explicit go-ahead on next action
3. Next turn: re-loaded summary + acted on it as if it were new

**Result**: clean perspective, no anchoring to "what I tried earlier", user got an actionable answer.

## Related

- `verification-before-completion` — reviewer's "evidence before claim" applies to context-reset too (don't claim review is fresh if it's not)
- `vibecoding-discipline` — complexity grows quadratically; review reset catches architectural drift early
- `delegation-sop` — Mode 3 (external reviewer handoff) uses spawn + scratchpad pattern
- `subagent-driven-development` (obra) — broader orchestration where context-reset applies
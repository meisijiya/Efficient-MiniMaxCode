---
name: deep-modules
description: John Ousterhout's "A Philosophy of Software Design" — deep modules have simple interfaces + deep implementations. Use when designing new modules / evaluating existing ones / fighting complexity growth. Trigger keywords: deep module, shallow module, Ousterhout, philosophy of software design, 接口简单, 实现深, complexity, 模块边界, 复杂度平方.
---

# Deep Modules

From John Ousterhout's *A Philosophy of Software Design* (Chapter 4 + 5): **deep modules** = simple interface + deep implementation. The best modules give you **a lot of power for a small interface**.

## Core concept

```
        ┌─────────────┐  small surface (interface)
        │   Module    │
        └─────────────┘
        ║             ║
        ║             ║  large volume (implementation)
        ║             ║
        ╚═════════════╝
```

**Deep module** = small interface / large implementation / big payoff.
**Shallow module** = large interface / small implementation / small payoff. (Often called "pass-through class" or "header file pretending to be a module".)

## Why this matters

Complexity grows **quadratically** with module count. Each module adds:
- Interface surface (must learn)
- Implementation (must understand to debug)
- Cross-module edges (potential bugs)

**Deep modules reduce complexity per module**. 5 deep modules > 20 shallow ones for the same functionality.

## When to apply

### Designing new module

Ask:
1. **Interface size**: can a new user understand the interface in < 5 min?
2. **Implementation depth**: does the module hide significant complexity?
3. **Power ratio**: implementation_lines / interface_methods = ?

Target power ratio ≥ 20:1 for "deep". < 5:1 = shallow (red flag).

### Evaluating existing module

```markdown
## Deep-Modules audit: <module-name>

### Interface
- Public methods: N
- Public fields: N
- Config keys: N
- Total surface: N
### Implementation
- Lines of code: N
- Cyclomatic complexity: N

### Power ratio
implementation_lines / surface_count = N (target ≥ 20)

### Verdict
- [ ] Deep (good — keep)
- [ ] Shallow (split into smaller + deeper, OR merge into caller)
- [ ] Mixed (good interface, shallow implementation → deepen)
```

### Refactoring shallow → deep

```
1. Move methods up to caller (remove pass-through)
2. OR merge small modules into one deeper module
3. OR redesign interface to expose less + do more
```

## Concrete examples

| Module | Interface | Implementation | Deep? |
|--------|-----------|----------------|-------|
| `HashMap<K,V>` | `put / get / remove` (3 methods) | ~2000 lines + tree rebalancing + hash collision strategies | ✅ Deep |
| `UserDto` with 30 getters/setters | 30 methods | 30 fields | ❌ Shallow (pass-through) |
| `Spring Data JPA Repository` | 4 methods (`save / findById / findAll / deleteById`) | ~5000 lines of generated SQL + caching + locking | ✅ Deep |
| `UserDtoConverter.toDto(User user)` | 1 method | 3 lines | ❌ Shallow (inline it) |

## Anti-patterns

- ❌ **Pass-through classes** — `FooController → FooService → FooRepository` where each is a thin wrapper; merge into 1 deep module
- ❌ **Config-object sprawl** — 50 config keys exposed when 5 would do; users overwhelmed
- ❌ **"Header file pretending to be module"** — 200 lines of declarations, 10 lines of real logic; **delete it**
- ❌ **Many small modules over few deep ones** — Java-style "one class per file" anti-pattern; Python/Go often better

## When NOT to apply

- **Library code** — interface IS the product; deep may not be right
- **Framework code** — surface = power offered to user; deep less important than flexible
- **Public API** — stability > depth; shallow-but-stable often better
- **Performance-critical hot path** — sometimes shallow = fast (inlining)

## Related

- `vibecoding-discipline` — 5-decoupling practice; deep-modules is a stricter version of "single responsibility"
- `api-design` — REST API design; module interface principles apply
- `backend-patterns-{java,python,ts}` — each language has idiomatic module structures (Spring Service, Python module, TS namespace)
- Karpathy principle 2 (Simplicity First) — deep modules operationalize simplicity

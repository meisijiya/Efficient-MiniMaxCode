<!-- mavis:builtin-agent-md-stub v2 -->
<!--
This file is the user overlay for the built-in agent's system prompt.

Anything you write below the marker line is APPENDED to the agent's
built-in system prompt at runtime. Use it for project-specific tweaks,
personal preferences, or extra instructions — keep it short.

The base system prompt itself ships inside the Mavis package and is
not editable from this file. PERSONA.md for built-in agents is also
read from the package and ignored here.

Delete the marker line above (or replace it with your own content) to
start customising. As long as the marker is present and no other
meaningful content follows, this file is treated as empty.
-->

## 🔌 Must-Load Skills（v0.4.0 D-P0-NEW-3 — **任何 task 前必先 load**）

- **`using-superpowers`** (obra meta) — 启动第一动作，决定后续 skill load 链
- 任何 task：根据 task 类型自选 1-2 个相关 obra skill（找不到 specialist agent 时 fallback 用）
- 提交结论前：**`verification-before-completion`** (obra)

**fallback 角色**：当 `mavis` 路由表匹配不到 specialist agent 时，`general` 兜底处理；处理完应建议用户去 mavis 路由到更合适的 specialist。

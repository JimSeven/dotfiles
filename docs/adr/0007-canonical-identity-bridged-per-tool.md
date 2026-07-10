# One canonical Identity, bridged to each agent tool

Personal instructions — who the user is and how they want to be worked with — live once in
a tool-neutral canonical file, `~/.config/agents/identity.md` (the Identity). Each agent
tool **bridges** to it instead of holding a copy: Claude via an `@~/.config/agents/identity.md`
import in `~/.claude/CLAUDE.md`, Codex and opencode via a symlink from their native
`AGENTS.md`. Tool-specific behaviour stays in each tool's own config (`~/.claude/rules/`,
`~/.codex/config.toml`).

Chosen over per-tool instruction files because Claude Code does **not** read `AGENTS.md`
natively while every other tool does, and separately-maintained copies inevitably drift. A
single real file makes drift structurally impossible.

Consequences:

- The Identity is kept **lean** (~20 lines, no PII beyond public role, no secrets): it loads into every session
  of every tool, and over-instruction uniformly degrades adherence to all rules.
- Global Claude instructions stay thin — a `@import` line plus a few universal rules — with
  `~/.claude/rules/` as an escape hatch only when a topic genuinely grows (cf. ADR-0004).

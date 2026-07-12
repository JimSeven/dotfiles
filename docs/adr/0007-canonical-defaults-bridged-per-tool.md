# One canonical Defaults file, bridged to each agent tool

Working defaults — a minimal, public-safe profile plus tool- and domain-neutral rules for
how the user wants to be worked with — live once in a canonical file,
`~/.config/agents/defaults.md` (the Defaults). Each agent tool **bridges** to it instead of
holding a copy: Claude via an `@~/.config/agents/defaults.md` import in `~/.claude/CLAUDE.md`,
Codex via a symlink from its native `~/.codex/AGENTS.md`, opencode via an `instructions`
entry in `~/.config/opencode/opencode.json`. Tool-specific behaviour stays in each tool's own
config (`~/.claude/rules/`, `~/.codex/config.toml`).

Chosen over per-tool instruction files because Claude Code does **not** read `AGENTS.md`
natively while every other tool does, and separately-maintained copies inevitably drift. A
single real file makes drift structurally impossible.

Consequences:

- The Defaults are **domain-neutral** — a good baseline across coding, conception, research
  and writing — and any project's own config may override them. Tool- or domain-specific
  depth (e.g. coding conventions) is added lazily as a pointer to a topic file, never inlined.
- The file is kept **lean** (~15 lines, no secrets, no PII beyond the public role): it loads
  into every session of every tool, and over-instruction uniformly degrades adherence.
- Profile and defaults share **one file** with a `## Profile` section on top. The Codex
  symlink can target exactly one file, so a single canonical file keeps the bridge symmetric
  across all three tools. The profile splits into its own 1Password-rendered file (cf.
  ADR-0002) only if it ever needs sensitive content — the deliberate "ripcord", not built on
  spec.
- Global Claude instructions stay thin — an `@import` line plus a few universal rules — with
  `~/.claude/rules/` as an escape hatch only when a topic genuinely grows (cf. ADR-0004).

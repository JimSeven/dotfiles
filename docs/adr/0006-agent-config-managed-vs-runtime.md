# AI agent config: version managed config, never runtime state

The home-directory dotfolders of AI agent tools (`~/.claude`, `~/.codex`, opencode)
interleave user-authored config with machine-generated runtime state and secrets. We
version only a small, durable **managed config** — `settings.json`, `CLAUDE.md`, statusline
for Claude; `config.toml` + `rules/` for Codex; `opencode.json` for opencode; and the
canonical Defaults (ADR-0007) — via a plain (never `exact_`) chezmoi directory plus a strict
`.chezmoiignore`. **Runtime state** (credentials, session transcripts, history, caches,
installed plugin payloads, SQLite logs) is never added.

Consequences:

- `exact_` on an agent dotfolder is **forbidden** — it would delete every unmanaged
  runtime file on the next `chezmoi apply`, wiping credentials, transcripts and 100s of MB
  of plugins.
- Because the repo is **public**, `~/.claude/.credentials.json` and `~/.codex/auth.json`
  are never managed (re-authenticate per machine), and a **gitleaks pre-commit hook** guards
  every commit against a pasted secret in an otherwise-tracked file.
- `settings.json` is a chezmoi template so the private company marketplace
  (`skills-leadership`) is gated behind machine data and stays out of the public repo.

## Deliberately out of scope

The scope is intentionally limited to instructions + durable settings. The following are
**not** versioned here and are (re-)established per machine, by hand:

- **Loose skill collections** — npx-installed sets (e.g. the Matt Pocock set) have
  interactive installers and so cannot be reproduced non-interactively; re-install by hand
  per machine. (Plugin-delivered skills, like the gated company marketplace, *are* still
  reproduced declaratively via `settings.json`.) Self-authored skills live in their own repo.
- **MCP servers** — Claude has no version-controllable user-scope MCP file (it lives in the
  mutable `~/.claude.json`); opencode/Codex hold theirs in their own managed config. Auth is
  always runtime. Rule of thumb: version the wiring only where it already lives in a managed
  file, never the secret.
- **`agents/`, `commands/`** — empty today; add a targeted `.chezmoiignore` re-include only
  if and when a durable, self-authored artifact actually appears.

This is a conscious trade-off: the setup churns and is Claude-first, so a minimal core that
never rots beats a comprehensive one that needs constant tending.

The agents rewrite their managed config at runtime (Codex re-adds `[projects."…"]` trust,
Claude Code re-orders keys and adds its own toggles). Rather than let that drift prompt on
every apply, the two files are `modify_` scripts that enforce the managed baseline while
passing the runtime keys back through into the target — kept out of the repo, never
committed. See ADR-0012.

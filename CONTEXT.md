# macOS Setup

> Glossary — the ubiquitous language for this repo. For how to use the setup see
> [`docs/GUIDE.md`](./docs/GUIDE.md), for the decisions behind each term see
> [`docs/adr/`](./docs/adr/), and for the landing page see [`README.md`](./README.md).

A personal, reproducible macOS provisioning system: one command turns a fresh Mac
into a fully configured machine. The repository is the single source of truth for
dotfiles, installed software, macOS system preferences, and secrets wiring.

## Language

**Bootstrap**:
The single-command process that takes a fresh macOS install and produces a fully
configured machine (prerequisites → chezmoi → apply). Runs in two phases because of
the 1Password login step.
_Avoid_: Setup script, installer.

**Apply**:
Running chezmoi to converge `$HOME` with the source state in this repo. The verb for
"make my machine match the repo."
_Avoid_: Sync, install dotfiles, deploy.

**Source state**:
The version-controlled representation of dotfiles and directories that chezmoi renders
into `$HOME`. Lives in this repo, not in `$HOME`.
_Avoid_: Templates folder, config dir.

**Manifest**:
The `Brewfile` — the declarative list of every Homebrew formula, cask, and Mac App Store
app the machine should have. Treated as the source of truth; cleanup of unlisted packages
is manual, never automatic.
_Avoid_: Package list, dependencies file.

**Provisioning script**:
A chezmoi `run_` hook that performs imperative setup that isn't a file (installing the
Manifest via `brew bundle`, applying macOS defaults, configuring the Dock).
_Avoid_: Hook, post-install script.

**Verification**:
The `run_after` Provisioning script (`run_after_90-verify.sh`) that asserts, at the end of
every Apply, the invariants Apply cannot otherwise guarantee — the three Bridges resolving to
the Defaults, and Herd's integration path. Exits non-zero (loud) on failure; runs on-machine
only, never in CI (ADR-0008).
_Avoid_: Test, healthcheck, doctor.

**Secret**:
A value that must never appear in the repo in plaintext (SSH keys, signing keys, tokens).
Resolved at Apply time from 1Password via the `op` CLI inside a chezmoi template.
_Avoid_: Credential, password, env var.

**Shell module**:
A numbered `*.zsh` file under `~/.config/zsh` (e.g. `20-tools.zsh`), sourced by the thin
`~/.zshrc` in prefix order. Each module owns one concern (path, env, tools, aliases, …).
_Avoid_: Snippet, include, fragment.

**Machine-local override**:
`~/.zshrc.local` — sourced last by `~/.zshrc` and never managed by chezmoi. Holds
machine-specific shell config and absorbs tool auto-injections (e.g. from Herd).
_Avoid_: Local config, overrides file.

## AI agent config

**Agent tool**:
A CLI/IDE coding agent whose config lives in a home-directory dotfolder (Claude Code
`~/.claude`, Codex `~/.codex`, opencode). Only the user-scope config of an Agent tool is
in scope here; team-shared config lives in a marketplace or project repo, never here.
_Avoid_: AI, LLM, assistant.

**Defaults**:
The single canonical file (`~/.config/agents/defaults.md`) with a minimal public-safe
profile plus tool- and domain-neutral rules for how the user wants to be worked with.
Loaded into every session, kept lean (~15 lines, no PII beyond public role, no secrets),
overridable per project. The source of truth every Agent tool bridges to.
_Avoid_: Identity, persona, profile, system prompt.

**Bridge**:
The mechanism that points an Agent tool's native instruction file at the Defaults — an
`@import` line (Claude), a symlink from the native `AGENTS.md` (Codex), or an `instructions`
entry in the config (opencode) — so there is exactly one real file and no drift.
_Avoid_: Link, include, reference.

**Managed config**:
The small, durable set of user-authored, non-secret files worth version-controlling:
`settings.json`, `CLAUDE.md`, statusline (Claude); `config.toml` + `rules/` (Codex);
`opencode.json` (opencode); the Defaults. Skills, MCP wiring, `agents/` and `commands/`
are deliberately out of scope (ADR-0006). Everything else is Runtime state.
_Avoid_: Dotfiles, agent files.

**Runtime state**:
Machine-generated data under an Agent tool's dotfolder that must never be committed —
credentials, session transcripts, history, caches, installed plugin payloads. Excluded via
`.chezmoiignore` and never added to chezmoi.
_Avoid_: Cache, junk, temp files.
